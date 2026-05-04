import Cocoa
import IOKit.ps

public class BatteryMonitor {
    private var batteryLevelChangeCallback: ((Int) -> Void)?
    private var batteryInfoChangeCallback: (([String: Any]) -> Void)?
    private var batteryHealthChangeCallback: (([String: Any]) -> Void)?
    
    private var batteryLevelPushTimer: Timer?
    private var batteryInfoPushTimer: Timer?
    private var batteryHealthTimer: Timer?
    
    private var lastBatteryLevel: Int = -1
    private var lastPushedBatteryLevel: Int = -1
    private var enableBatteryLevelDebounce: Bool = true
    
    private var eventChannelHandler: BatteryStreamHandler?
    
    public init() {}
    
    public func setEventChannelHandler(_ handler: BatteryStreamHandler) {
        self.eventChannelHandler = handler
    }
    
    public func getBatteryLevel() -> Int {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        for ps in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            if let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int {
                return currentCapacity
            }
        }
        return -1
    }
    
    public func getBatteryInfo() -> [String: Any] {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        var level = -1
        var isCharging = false
        var isCharged = false
        var timeToFull = -1
        var timeToEmpty = -1
        
        for ps in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            
            if let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int {
                level = currentCapacity
            }
            if let charging = description[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
            if let charged = description[kIOPSIsChargedKey] as? Bool {
                isCharged = charged
            }
            if let timeFull = description[kIOPSTimeToFullChargeKey] as? Int {
                timeToFull = timeFull
            }
            if let timeEmpty = description[kIOPSTimeToEmptyKey] as? Int {
                timeToEmpty = timeEmpty
            }
        }
        
        let state = getBatteryState(level: level, isCharging: isCharging, isCharged: isCharged)
        
        return [
            "level": level,
            "isCharging": isCharging,
            "isCharged": isCharged,
            "timeToFull": timeToFull,
            "timeToEmpty": timeToEmpty,
            "state": state,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
    }
    
    public func getBatteryHealth() -> [String: Any] {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        var level = -1
        var isCharging = false
        var maxCapacity = -1
        var currentCapacity = -1
        var designCapacity = -1
        var cycleCount = -1
        var serialNumber = ""
        var manufacturer = ""
        var deviceName = ""
        
        for ps in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            let technicalInfo = description[kIOPSTechnologyKey] as? String ?? ""
            
            if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                level = capacity
                currentCapacity = capacity
            }
            if let maxCap = description[kIOPSMaxCapacityKey] as? Int {
                maxCapacity = maxCap
            }
            if let charging = description[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
            if let serial = description[kIOPSHardwareSerialNumberKey] as? String {
                serialNumber = serial
            }
            if let name = description[kIOPSNameKey] as? String {
                deviceName = name
            }
        }
        
        // Try to get additional info from IORegistry
        if maxCapacity > 0 {
            let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"))
            if service != 0 {
                if let cycleData = IORegistryEntryCreateCFProperty(service, "CycleCount" as CFString, kCFAllocatorDefault, 0) {
                    cycleCount = cycleData.takeRetainedValue() as? Int ?? -1
                }
                if let designCapData = IORegistryEntryCreateCFProperty(service, "DesignCapacity" as CFString, kCFAllocatorDefault, 0) {
                    designCapacity = designCapData.takeRetainedValue() as? Int ?? -1
                }
                if let manufacturerData = IORegistryEntryCreateCFProperty(service, "Manufacturer" as CFString, kCFAllocatorDefault, 0) {
                    manufacturer = manufacturerData.takeRetainedValue() as? String ?? ""
                }
                IOObjectRelease(service)
            }
        }
        
        let healthPercentage = maxCapacity > 0 ? Double(maxCapacity) / Double(designCapacity > 0 ? designCapacity : maxCapacity) * 100.0 : 100.0
        let status = getHealthStatus(healthPercentage: healthPercentage, cycleCount: cycleCount)
        let recommendations = getHealthRecommendations(status: status, healthPercentage: healthPercentage, cycleCount: cycleCount, isCharging: isCharging, level: level)
        let riskLevel = getRiskLevel(status: status)
        
        return [
            "state": status,
            "healthPercentage": round(healthPercentage * 100) / 100,
            "maxCapacity": maxCapacity,
            "currentCapacity": currentCapacity,
            "designCapacity": designCapacity,
            "cycleCount": cycleCount,
            "serialNumber": serialNumber,
            "manufacturer": manufacturer,
            "deviceName": deviceName,
            "isCharging": isCharging,
            "level": level,
            "riskLevel": riskLevel,
            "recommendations": recommendations,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
    }
    
    public func getBatteryOptimizationTips() -> [String] {
        var tips: [String] = []
        let info = getBatteryInfo()
        
        let level = info["level"] as? Int ?? -1
        let isCharging = info["isCharging"] as? Bool ?? false
        let isCharged = info["isCharged"] as? Bool ?? false
        
        if !isCharging && level >= 0 && level < 20 {
            tips.append("电量低于20%，建议连接充电器")
        }
        
        if !isCharging && level >= 0 && level < 10 {
            tips.append("电量严重不足，设备可能很快关机")
        }
        
        if isCharging && isCharged {
            tips.append("电池已充满，可以断开充电器")
        }
        
        if isCharging && level >= 80 {
            tips.append("电池电量已超过80%，为延长电池寿命可考虑断开充电器")
        }
        
        if tips.isEmpty {
            tips.append("电池状态良好，可正常使用")
        }
        
        return tips
    }
    
    private func getBatteryState(level: Int, isCharging: Bool, isCharged: Bool) -> String {
        if isCharged {
            return "FULL"
        }
        if isCharging {
            return "CHARGING"
        }
        if level <= 10 {
            return "CRITICAL"
        }
        if level <= 20 {
            return "LOW"
        }
        return "NORMAL"
    }
    
    private func getHealthStatus(healthPercentage: Double, cycleCount: Int) -> String {
        if healthPercentage >= 80 && cycleCount < 1000 {
            return "GOOD"
        }
        if healthPercentage < 50 || cycleCount > 1000 {
            return "DEAD"
        }
        if healthPercentage < 70 {
            return "FAILURE"
        }
        return "UNKNOWN"
    }
    
    private func getRiskLevel(status: String) -> String {
        switch status {
        case "GOOD":
            return "LOW"
        case "UNKNOWN":
            return "MEDIUM"
        default:
            return "HIGH"
        }
    }
    
    private func getHealthRecommendations(status: String, healthPercentage: Double, cycleCount: Int, isCharging: Bool, level: Int) -> [String] {
        var tips: [String] = []
        
        switch status {
        case "DEAD":
            tips.append("电池健康度严重下降，建议更换电池")
        case "FAILURE":
            tips.append("电池健康度较低，建议联系售后检查")
        default:
            if !isCharging && level < 30 {
                tips.append("电量偏低(\(level)%)，建议及时充电")
            }
            if cycleCount > 500 {
                tips.append("电池循环次数已达\(cycleCount)次，建议关注电池健康")
            }
        }
        
        if tips.isEmpty {
            tips.append("电池状态良好，可正常使用")
        }
        
        return tips
    }
    
    public func setBatteryLevelPushInterval(intervalMs: Int) {
        stopBatteryLevelListening()
        
        let interval = TimeInterval(intervalMs) / 1000.0
        batteryLevelPushTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pushBatteryLevel()
        }
    }
    
    public func startBatteryLevelListening(eventChannelHandler: BatteryStreamHandler?) {
        self.eventChannelHandler = eventChannelHandler
        stopBatteryLevelListening()
        
        lastBatteryLevel = getBatteryLevel()
        
        batteryLevelPushTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pushBatteryLevel()
        }
    }
    
    public func stopBatteryLevelListening() {
        batteryLevelPushTimer?.invalidate()
        batteryLevelPushTimer = nil
        lastBatteryLevel = -1
    }
    
    public func startBatteryInfoListening(intervalMs: Int = 5000) {
        stopBatteryInfoListening()
        
        let interval = TimeInterval(intervalMs) / 1000.0
        batteryInfoPushTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pushBatteryInfo()
        }
    }
    
    public func stopBatteryInfoListening() {
        batteryInfoPushTimer?.invalidate()
        batteryInfoPushTimer = nil
    }
    
    public func startBatteryHealthListening(intervalMs: Int = 10000) {
        stopBatteryHealthListening()
        
        let interval = TimeInterval(intervalMs) / 1000.0
        batteryHealthTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pushBatteryHealth()
        }
    }
    
    public func stopBatteryHealthListening() {
        batteryHealthTimer?.invalidate()
        batteryHealthTimer = nil
    }
    
    public func stopMonitoring() {
        stopBatteryLevelListening()
        stopBatteryInfoListening()
        stopBatteryHealthListening()
    }
    
    public func dispose() {
        stopMonitoring()
        batteryLevelChangeCallback = nil
        batteryInfoChangeCallback = nil
        batteryHealthChangeCallback = nil
    }
    
    private func pushBatteryLevel() {
        let currentLevel = getBatteryLevel()
        if currentLevel >= 0 {
            let shouldPush = !enableBatteryLevelDebounce || currentLevel != lastPushedBatteryLevel
            if shouldPush {
                lastPushedBatteryLevel = currentLevel
                batteryLevelChangeCallback?(currentLevel)
                eventChannelHandler?.sendBatteryUpdate(["level": currentLevel, "timestamp": Int(Date().timeIntervalSince1970 * 1000)])
            }
        }
    }
    
    private func pushBatteryInfo() {
        let info = getBatteryInfo()
        batteryInfoChangeCallback?(info)
        eventChannelHandler?.sendBatteryUpdate(info)
    }
    
    private func pushBatteryHealth() {
        let health = getBatteryHealth()
        batteryHealthChangeCallback?(health)
    }
}

public class BatteryStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private weak var batteryMonitor: BatteryMonitor?
    
    public init(batteryMonitor: BatteryMonitor) {
        self.batteryMonitor = batteryMonitor
        super.init()
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    public func sendBatteryUpdate(_ info: [String: Any]) {
        eventSink?(info)
    }
}
