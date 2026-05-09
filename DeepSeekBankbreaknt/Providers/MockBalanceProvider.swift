import Foundation

final class MockBalanceProvider: BalanceProvider {
    let name = "Mock Provider"
    
    private var mockBalance: Double = 99.50
    private var mockCurrency: Currency = .cny
    private var shouldFail: Bool = false
    private var failError: BalanceError = .unknown("Mock error")
    
    func setMockBalance(_ balance: Double, currency: Currency = .cny) {
        self.mockBalance = balance
        self.mockCurrency = currency
    }
    
    func setShouldFail(_ shouldFail: Bool, error: BalanceError = .unknown("Mock error")) {
        self.shouldFail = shouldFail
        self.failError = error
    }
    
    func fetchBalance() async throws -> [BalanceInfo] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFail {
            throw failError
        }
        
        return [
            BalanceInfo(
                currency: mockCurrency,
                totalBalance: String(format: "%.2f", mockBalance + Double.random(in: 0...5)),
                grantedBalance: String(format: "%.2f", mockBalance * 0.1),
                toppedUpBalance: String(format: "%.2f", mockBalance * 0.9)
            )
        ]
    }
    
    func testConnection() async throws -> Bool {
        try await Task.sleep(nanoseconds: 300_000_000)
        return !shouldFail
    }
}