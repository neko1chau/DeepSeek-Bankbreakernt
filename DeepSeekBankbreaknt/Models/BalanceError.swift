import Foundation

enum BalanceError: Error, Equatable {
    case noAPIKey
    case invalidAPIKey
    case networkError(String)
    case serverError(Int)
    case rateLimited
    case parseError
    case unknown(String)
    
    var errorDescription: String {
        switch self {
        case .noAPIKey:
            return "No API Key configured"
        case .invalidAPIKey:
            return "Invalid API Key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let code):
            return "Server error (code: \(code))"
        case .rateLimited:
            return "Rate limited - please wait"
        case .parseError:
            return "Failed to parse response"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .noAPIKey:
            return "Please set your API Key in Settings"
        case .invalidAPIKey:
            return "Invalid API Key - please check and update"
        case .networkError:
            return "Network unavailable"
        case .serverError:
            return "Service temporarily unavailable"
        case .rateLimited:
            return "Too many requests - try again later"
        case .parseError:
            return "Service response error"
        case .unknown:
            return "An error occurred"
        }
    }
}