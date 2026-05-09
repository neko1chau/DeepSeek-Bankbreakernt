import Foundation

struct DeepSeekProvider: BalanceProvider {
    let name = "DeepSeek"
    
    private let networkService: NetworkService
    private let credentialsStore: CredentialsStore
    
    init(networkService: NetworkService = .shared, credentialsStore: CredentialsStore = .shared) {
        self.networkService = networkService
        self.credentialsStore = credentialsStore
    }
    
    func fetchBalance() async throws -> [BalanceInfo] {
        guard let apiKey = credentialsStore.apiKey, !apiKey.isEmpty else {
            throw BalanceError.noAPIKey
        }
        
        let response = try await networkService.fetchBalance(apiKey: apiKey)
        return response.balanceInfos
    }
    
    func testConnection() async throws -> Bool {
        guard let apiKey = credentialsStore.apiKey, !apiKey.isEmpty else {
            throw BalanceError.noAPIKey
        }
        
        _ = try await networkService.fetchBalance(apiKey: apiKey)
        return true
    }
}