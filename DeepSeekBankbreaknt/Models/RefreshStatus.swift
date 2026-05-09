import Foundation

enum RefreshStatus: Equatable {
    case idle
    case refreshing
    case success(Date)
    case failure(BalanceError)
    
    var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }
    
    var lastSuccessDate: Date? {
        if case .success(let date) = self { return date }
        return nil
    }
    
    var error: BalanceError? {
        if case .failure(let error) = self { return error }
        return nil
    }
    
    static func == (lhs: RefreshStatus, rhs: RefreshStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.refreshing, .refreshing): return true
        case (.success(let lDate), .success(let rDate)): return lDate == rDate
        case (.failure(let lError), .failure(let rError)): return lError.errorDescription == rError.errorDescription
        default: return false
        }
    }
}