import Foundation

enum RefreshFrequency: Int, CaseIterable, Codable, Identifiable {
    case oneMinute = 60
    case fiveMinutes = 300
    case tenMinutes = 600
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .tenMinutes: return "10m"
        }
    }
}