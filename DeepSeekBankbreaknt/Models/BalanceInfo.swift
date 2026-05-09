import Foundation

struct BalanceInfo: Codable, Equatable, Identifiable {
    let currency: Currency
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String
    
    var id: String { currency.rawValue }
    
    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }
    
    var totalBalanceDouble: Double {
        Double(totalBalance) ?? 0.0
    }
    
    var formattedTotalBalance: String {
        Formatters.balanceFormatter.string(from: NSNumber(value: totalBalanceDouble)) ?? totalBalance
    }
}

enum Currency: String, Codable, CaseIterable, Identifiable {
    case cny = "CNY"
    case usd = "USD"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .cny: return "¥"
        case .usd: return "$"
        }
    }
    
    var displayName: String {
        rawValue
    }
}

struct BalanceResponse: Codable {
    let isAvailable: Bool
    let balanceInfos: [BalanceInfo]
    
    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}