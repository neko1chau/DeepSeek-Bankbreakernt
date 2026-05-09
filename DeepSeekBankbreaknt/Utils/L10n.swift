import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
    
    enum APIConfig { static var title: String { string("API Configuration") } }
    enum RefreshSettings { static var title: String { string("Refresh Settings") } }
    enum Startup { static var title: String { string("Startup") } }
    enum About { static var title: String { string("About") } }
    
    enum CurrentBalance { static var title: String { string("Current Balance") } }
    enum LastUpdated { static var title: String { string("Last Updated") } }
    enum RefreshRate { static var title: String { string("Refresh Rate") } }
    enum Status { static var title: String { string("Status") } }
    
    enum Ready { static var text: String { string("Ready") } }
    enum Refreshing { static var text: String { string("Refreshing") } }
    enum Updated { static var text: String { string("Updated") } }
    enum OK { static var text: String { string("OK") } }
    
    enum Refresh { static var button: String { string("Refresh") } }
    enum Settings { static var button: String { string("Settings") } }
    enum Quit { static var button: String { string("Quit") } }
    
    enum TestConnection { static var button: String { string("Test Connection") } }
    enum Save { static var button: String { string("Save") } }
    enum ConnectionSuccess { static var message: String { string("Connection successful") } }
    enum ConnectionFailed { static var message: String { string("Connection failed") } }
    
    enum PreferredCurrency { static var title: String { string("Preferred Currency") } }
    enum AutoRefresh { static var title: String { string("Auto Refresh") } }
    enum LowBalanceAlert { static var title: String { string("Low Balance Alert") } }
    enum LaunchAtLogin { static var title: String { string("Launch at Login") } }
    enum HideZeroBalance { static var title: String { string("Hide Zero Balance") } }
    
    enum Version { static var title: String { string("Version") } }
    enum UseMockProvider { static var title: String { string("Use Mock Provider") } }
    enum Mock { static var label: String { string("Mock") } }
    enum Granted { static var label: String { string("Granted") } }
    enum ToppedUp { static var label: String { string("Topped Up") } }
    enum Off { static var label: String { string("Off") } }
    enum Preferred { static var label: String { string("Preferred") } }
    enum DeepSeekBalance { static var title: String { string("DeepSeek Balance") } }
}