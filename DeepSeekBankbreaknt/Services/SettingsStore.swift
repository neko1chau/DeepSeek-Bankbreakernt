import Foundation
import ServiceManagement

final class SettingsStore {
    static let shared = SettingsStore()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let refreshFrequency = "refresh_frequency"
        static let launchAtLogin = "launch_at_login"
        static let preferredCurrency = "preferred_currency"
        static let lowBalanceThreshold = "low_balance_threshold"
        static let hideZeroBalance = "hide_zero_balance"
    }
    
    private init() {}
    
    var refreshFrequency: RefreshFrequency {
        get {
            let rawValue = userDefaults.integer(forKey: Keys.refreshFrequency)
            return RefreshFrequency(rawValue: rawValue) ?? .fiveMinutes
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.refreshFrequency)
            AppLogger.log("Refresh frequency set to: \(newValue.displayName)")
        }
    }
    
    var launchAtLogin: Bool {
        get { userDefaults.bool(forKey: Keys.launchAtLogin) }
        set {
            userDefaults.set(newValue, forKey: Keys.launchAtLogin)
            if newValue {
                enableLaunchAtLogin()
            } else {
                disableLaunchAtLogin()
            }
            AppLogger.log("Launch at login set to: \(newValue)")
        }
    }
    
    var preferredCurrency: Currency {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.preferredCurrency),
                  let currency = Currency(rawValue: rawValue) else {
                return .cny
            }
            return currency
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.preferredCurrency)
            AppLogger.log("Preferred currency set to: \(newValue.rawValue)")
        }
    }
    
    var lowBalanceThreshold: Double {
        get { userDefaults.double(forKey: Keys.lowBalanceThreshold) }
        set {
            userDefaults.set(newValue, forKey: Keys.lowBalanceThreshold)
            AppLogger.log("Low balance threshold set to: \(newValue)")
        }
    }
    
    var hideZeroBalance: Bool {
        get { userDefaults.bool(forKey: Keys.hideZeroBalance) }
        set {
            userDefaults.set(newValue, forKey: Keys.hideZeroBalance)
            AppLogger.log("Hide zero balance set to: \(newValue)")
        }
    }
    
    private func enableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            AppLogger.log("Failed to enable launch at login: \(error)")
        }
    }
    
    private func disableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            AppLogger.log("Failed to disable launch at login: \(error)")
        }
    }
}