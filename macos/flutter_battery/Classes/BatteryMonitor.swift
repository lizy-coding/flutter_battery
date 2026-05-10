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
    
    // MARK: - Callback setters (R005)
    
    public func setOnBatteryLevelChangeCallback(_ callback: @escaping (Int) -> Void) {
        batteryLevelChangeCallback = callback
    }
    
    public func setOnBatteryInfoChangeCallback(_ callback: @escaping ([String: Any]) -> Void) {
        batteryInfoChangeCallback = callback
    }
    
    public func setOnBatteryHealthChangeCallback(_ callback: @escaping ([String: Any]) -> Void) {
        batteryHealthChangeCallback = callback
    }
    
    private func hasBattery() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        return !sources.isEmpty
    }

    private struct HardwareMetrics {
        var temperature: Double = 0.0
        var voltage: Double = 0.0
        var maxCapacity: Int = -1
        var designCapacity: Int = -1
        var cycleCount: Int = -1
        var manufacturer: String = ""
    }

    private func getHardwareMetrics() -> HardwareMetrics {
        var metrics = HardwareMetrics()
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service == 0 {
            return metrics
        }
        defer {
            IOObjectRelease(service)
        }

        metrics.cycleCount = readIntProperty(service: service, key: "CycleCount") ?? -1
        metrics.designCapacity = readIntProperty(service: service, key: "DesignCapacity") ?? -1
        metrics.maxCapacity = readIntProperty(service: service, key: "AppleRawMaxCapacity")
            ?? readIntProperty(service: service, key: "MaxCapacity")
            ?? -1
        metrics.temperature = normalizeTemperature(readIntProperty(service: service, key: "Temperature"))
        metrics.voltage = normalizeVoltage(readIntProperty(service: service, key: "Voltage"))

        if let manufacturerData = IORegistryEntryCreateCFProperty(service, "Manufacturer" as CFString, kCFAllocatorDefault, 0) {
            metrics.manufacturer = manufacturerData.takeRetainedValue() as? String ?? ""
        }

        return metrics
    }

    private func readIntProperty(service: io_registry_entry_t, key: String) -> Int? {
        guard let data = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        let value = data.takeRetainedValue()
        if let intValue = value as? Int {
            return intValue
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }

    private func normalizeTemperature(_ rawValue: Int?) -> Double {
        guard let rawValue = rawValue, rawValue > 0 else {
            return 0.0
        }
        let value = Double(rawValue)
        if rawValue > 1000 {
            return round((value / 100.0) * 10) / 10
        }
        return round((value / 10.0) * 10) / 10
    }

    private func normalizeVoltage(_ rawValue: Int?) -> Double {
        guard let rawValue = rawValue, rawValue > 0 else {
            return 0.0
        }
        let value = rawValue > 100 ? Double(rawValue) / 1000.0 : Double(rawValue)
        return round(value * 100) / 100
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
        let metrics = getHardwareMetrics()
        
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
            "batteryLevel": level,
            "isCharging": isCharging,
            "isCharged": isCharged,
            "timeToFull": timeToFull,
            "timeToEmpty": timeToEmpty,
            "temperature": metrics.temperature,
            "voltage": metrics.voltage,
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
        var serialNumber = ""
        var deviceName = ""
        let metrics = getHardwareMetrics()
        
        for ps in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            _ = description["Technology"] as? String ?? ""
            
            if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                level = capacity
                currentCapacity = capacity
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
        
        maxCapacity = metrics.maxCapacity
        
        let healthPercentage = maxCapacity > 0 && metrics.designCapacity > 0
            ? Double(maxCapacity) / Double(metrics.designCapacity) * 100.0
            : 0.0
        let status = getHealthStatus(
            healthPercentage: healthPercentage,
            hasReliableCapacity: maxCapacity > 0 && metrics.designCapacity > 0,
            cycleCount: metrics.cycleCount
        )
        let recommendations = getHealthRecommendations(status: status, healthPercentage: healthPercentage, cycleCount: metrics.cycleCount, isCharging: isCharging, level: level)
        let riskLevel = getRiskLevel(status: status)
        
        return [
            "state": status,
            "statusLabel": healthLabel(for: status),
            "isGood": status == "GOOD",
            "healthPercentage": round(healthPercentage * 100) / 100,
            "maxCapacity": maxCapacity,
            "currentCapacity": currentCapacity,
            "designCapacity": metrics.designCapacity,
            "cycleCount": metrics.cycleCount,
            "serialNumber": serialNumber,
            "manufacturer": metrics.manufacturer,
            "deviceName": deviceName,
            "isCharging": isCharging,
            "level": level,
            "batteryLevel": level,
            "temperature": metrics.temperature,
            "voltage": metrics.voltage,
            "riskLevel": riskLevel,
            "recommendations": recommendations,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
    }
    
    private func healthLabel(for status: String) -> String {
        switch status {
        case "GOOD": return "Good"
        case "OVERHEAT": return "Overheating"
        case "DEAD": return "Dead"
        case "FAILURE": return "Failure"
        case "COLD": return "Cold"
        default: return "Unknown"
        }
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
        if isCharged { return "FULL" }
        if isCharging { return "CHARGING" }
        if level <= 10 { return "CRITICAL" }
        if level <= 20 { return "LOW" }
        return "NORMAL"
    }
    
    private func getHealthStatus(healthPercentage: Double, hasReliableCapacity: Bool, cycleCount: Int) -> String {
        if cycleCount > 1000 { return "DEAD" }
        if !hasReliableCapacity { return "UNKNOWN" }
        if healthPercentage >= 80 { return "GOOD" }
        if healthPercentage < 50 { return "DEAD" }
        if healthPercentage < 70 { return "FAILURE" }
        return "UNKNOWN"
    }
    
    private func getRiskLevel(status: String) -> String {
        switch status {
        case "GOOD": return "LOW"
        case "UNKNOWN": return "MEDIUM"
        default: return "HIGH"
        }
    }
    
    private func getHealthRecommendations(status: String, healthPercentage: Double, cycleCount: Int, isCharging: Bool, level: Int) -> [String] {
        var tips: [String] = []
        switch status {
        case "DEAD":
            tips.append("电池健康度严重下降，建议更换电池")
        case "FAILURE":
            tips.append("电池健康度较低，建议联系售后检查")
        case "UNKNOWN":
            tips.append("无法可靠读取 macOS 电池健康容量数据，请以系统设置中的电池健康信息为准")
        default:
            if !isCharging && level >= 0 && level < 30 {
                tips.append("电量偏低(\(level)%)，建议及时充电")
            }
            if cycleCount > 500 {
                tips.append("电池循环次数已达\(cycleCount)次，建议关注电池健康")
            }
        }
        if tips.isEmpty { tips.append("电池状态良好，可正常使用") }
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
    
    private func emitUnavailableIfNoBattery() -> Bool {
        if !hasBattery() {
            let payload: [String: Any] = [
                "type": "BATTERY_UNAVAILABLE",
                "level": 0,
                "batteryLevel": 0,
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "unavailableReason": "No battery present on this system"
            ]
            eventChannelHandler?.sendBatteryUpdate(payload)
            batteryLevelChangeCallback?(0)
            return true
        }
        return false
    }
    
    private func pushBatteryLevel() {
        if emitUnavailableIfNoBattery() { return }
        
        let currentLevel = getBatteryLevel()
        if currentLevel >= 0 {
            let shouldPush = !enableBatteryLevelDebounce || currentLevel != lastPushedBatteryLevel
            if shouldPush {
                lastPushedBatteryLevel = currentLevel
                let payload: [String: Any] = [
                    "type": "BATTERY_LEVEL",
                    "level": currentLevel,
                    "batteryLevel": currentLevel,
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                batteryLevelChangeCallback?(currentLevel)
                eventChannelHandler?.sendBatteryUpdate(payload)
            }
        }
    }
    
    private func pushBatteryInfo() {
        if emitUnavailableIfNoBattery() { return }
        
        var info = getBatteryInfo()
        info["type"] = "BATTERY_INFO"
        // Ensure both level keys are present
        if let level = info["level"] as? Int {
            info["batteryLevel"] = level
        }
        batteryInfoChangeCallback?(info)
        eventChannelHandler?.sendBatteryUpdate(info)
    }
    
    private func pushBatteryHealth() {
        if emitUnavailableIfNoBattery() { return }
        
        var health = getBatteryHealth()
        health["type"] = "BATTERY_HEALTH"
        if let level = health["level"] as? Int {
            health["batteryLevel"] = level
        }
        batteryHealthChangeCallback?(health)
        eventChannelHandler?.sendBatteryUpdate(health)
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
