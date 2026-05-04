import Cocoa
import FlutterMacOS

public class FlutterBatteryPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var batteryMonitor: BatteryMonitor?
    private var eventChannelHandler: BatteryStreamHandler?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = FlutterBatteryPlugin()
        
        // Method Channel
        let methodChannel = FlutterMethodChannel(
            name: "flutter_battery",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(plugin, channel: methodChannel)
        plugin.methodChannel = methodChannel
        
        // Event Channel
        let eventChannel = FlutterEventChannel(
            name: "flutter_battery/battery_stream",
            binaryMessenger: registrar.messenger
        )
        plugin.eventChannel = eventChannel
        
        // Initialize battery monitor
        plugin.batteryMonitor = BatteryMonitor()
        
        // Setup event channel handler
        let eventHandler = BatteryStreamHandler(batteryMonitor: plugin.batteryMonitor!)
        eventChannel.setStreamHandler(eventHandler)
        plugin.eventChannelHandler = eventHandler
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let batteryMonitor = batteryMonitor else {
            result(FlutterError(code: "UNAVAILABLE", message: "Battery monitor not available", details: nil))
            return
        }
        
        switch call.method {
        case "getPlatformVersion":
            let version = ProcessInfo.processInfo.operatingSystemVersionString
            result("macOS \(version)")
            
        case "getBatteryLevel":
            let level = batteryMonitor.getBatteryLevel()
            result(level)
            
        case "getBatteryInfo":
            let info = batteryMonitor.getBatteryInfo()
            result(info)
            
        case "getBatteryHealth":
            let health = batteryMonitor.getBatteryHealth()
            result(health)
            
        case "getBatteryOptimizationTips":
            let tips = batteryMonitor.getBatteryOptimizationTips()
            result(tips)
            
        case "startBatteryLevelListening":
            batteryMonitor.startBatteryLevelListening(eventChannelHandler: eventChannelHandler)
            result(true)
            
        case "stopBatteryLevelListening":
            batteryMonitor.stopBatteryLevelListening()
            result(true)
            
        case "startBatteryInfoListening":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.startBatteryInfoListening(intervalMs: intervalMs)
            } else {
                batteryMonitor.startBatteryInfoListening()
            }
            result(true)
            
        case "stopBatteryInfoListening":
            batteryMonitor.stopBatteryInfoListening()
            result(true)
            
        case "startBatteryHealthListening":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.startBatteryHealthListening(intervalMs: intervalMs)
            } else {
                batteryMonitor.startBatteryHealthListening()
            }
            result(true)
            
        case "stopBatteryHealthListening":
            batteryMonitor.stopBatteryHealthListening()
            result(true)
            
        case "setPushInterval":
            if let args = call.arguments as? [String: Any],
               let intervalMs = args["intervalMs"] as? Int {
                batteryMonitor.setBatteryLevelPushInterval(intervalMs: intervalMs)
            }
            result(true)
            
        case "setBatteryLevelThreshold":
            // macOS doesn't support native notifications in the same way as Android
            // Return success but log that this feature is limited
            result(true)
            
        case "stopBatteryMonitoring":
            batteryMonitor.stopMonitoring()
            result(true)
            
        case "scheduleNotification":
            // Not supported on macOS
            result(FlutterError(code: "NOT_SUPPORTED", message: "Scheduled notifications not supported on macOS", details: nil))
            
        case "showNotification":
            // Not supported on macOS
            result(FlutterError(code: "NOT_SUPPORTED", message: "Native notifications not supported on macOS", details: nil))
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        batteryMonitor?.dispose()
        methodChannel = nil
        eventChannel = nil
        eventChannelHandler = nil
    }
}
