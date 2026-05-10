import Foundation

final class CredentialsStore {
    static let shared = CredentialsStore()

    private init() {}

    var apiKey: String? {
        get { KeychainStore.read() }
        set {
            if let key = newValue {
                KeychainStore.save(key)
            } else {
                KeychainStore.delete()
            }
        }
    }

    var hasAPIKey: Bool {
        KeychainStore.exists()
    }
}
