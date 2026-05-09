import Foundation

protocol BalanceProvider {
    var name: String { get }
    func fetchBalance() async throws -> [BalanceInfo]
    func testConnection() async throws -> Bool
}