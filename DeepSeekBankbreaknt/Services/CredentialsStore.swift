import Foundation

final class CredentialsStore {
    static let shared = CredentialsStore()
    
    private let userDefaults = UserDefaults.standard
    private let apiKeyKey = "deepseek_bankbreaknt_apikey"
    
    private init() {}
    
    var apiKey: String? {
        get {
            return userDefaults.string(forKey: apiKeyKey)
        }
        set {
            userDefaults.set(newValue, forKey: apiKeyKey)
            AppLogger.log("API key saved")
        }
    }
    
    var hasAPIKey: Bool {
        apiKey?.isEmpty == false
    }
}