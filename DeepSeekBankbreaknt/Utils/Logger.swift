import Foundation
import os.log

enum AppLogger {
    #if DEBUG
    static let isEnabled = true
    #else
    static let isEnabled = false
    #endif
    
    private static let subsystem = "com.deepseek.bankbreaknt"
    private static let logger = OSLog(subsystem: subsystem, category: "general")
    
    static func log(_ message: String) {
        guard isEnabled else { return }
        let info = message.withCString { cString in
            os_log("%{private}c", log: logger, type: .info, cString)
        }
        _ = info
    }
}