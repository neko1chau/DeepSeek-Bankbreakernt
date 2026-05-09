import Foundation

final class NetworkService {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let baseURL = "https://api.deepseek.com"
    private let timeout: TimeInterval = 30
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    func fetchBalance(apiKey: String) async throws -> BalanceResponse {
        let url = URL(string: "\(baseURL)/user/balance")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        AppLogger.log("Fetching balance from: \(url)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BalanceError.networkError("Invalid response")
        }
        
        AppLogger.log("Response status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw BalanceError.invalidAPIKey
        case 429:
            throw BalanceError.rateLimited
        case 500...599:
            throw BalanceError.serverError(httpResponse.statusCode)
        default:
            throw BalanceError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let balanceResponse = try decoder.decode(BalanceResponse.self, from: data)
        AppLogger.log("Balance fetched successfully")
        return balanceResponse
    }
}