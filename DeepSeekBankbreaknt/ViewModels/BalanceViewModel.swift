import Foundation
import Combine
import AppKit
import UserNotifications

@MainActor
final class BalanceViewModel: ObservableObject {
    @Published private(set) var balanceInfos: [BalanceInfo] = []
    @Published private(set) var status: RefreshStatus = .idle
    @Published private(set) var lastRefreshTime: Date?
    @Published private(set) var balanceHistory: [BalanceRecord] = []
    
    @Published var refreshFrequency: RefreshFrequency {
        didSet {
            SettingsStore.shared.refreshFrequency = refreshFrequency
            restartAutoRefresh()
        }
    }
    
    @Published var preferredCurrency: Currency {
        didSet {
            SettingsStore.shared.preferredCurrency = preferredCurrency
            updateStatusBarText()
        }
    }
    
    @Published var lowBalanceThreshold: Double {
        didSet {
            SettingsStore.shared.lowBalanceThreshold = lowBalanceThreshold
        }
    }
    
    @Published var hideZeroBalance: Bool {
        didSet {
            SettingsStore.shared.hideZeroBalance = hideZeroBalance
        }
    }
    
    @Published var statusBarText: String?
    
    var menuBarTitle: String {
        guard let text = statusBarText, !text.isEmpty else { return "--" }
        return text
    }
    
    @Published var useMockProvider: Bool = false
    
    private var provider: BalanceProvider {
        useMockProvider ? mockProvider : realProvider
    }
    
    private let realProvider: DeepSeekProvider
    private let mockProvider: MockBalanceProvider
    
    private var refreshTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    private var lastLowBalanceNotification: Date?
    private var hasNotifiedLowBalance: Bool = false
    
    init() {
        self.realProvider = DeepSeekProvider()
        self.mockProvider = MockBalanceProvider()
        self.refreshFrequency = SettingsStore.shared.refreshFrequency
        self.preferredCurrency = SettingsStore.shared.preferredCurrency
        self.lowBalanceThreshold = SettingsStore.shared.lowBalanceThreshold
        self.hideZeroBalance = SettingsStore.shared.hideZeroBalance
        
        Task {
            await requestNotificationPermission()
            await setupAutoRefresh()
        }
    }
    
    var hasAPIKey: Bool {
        CredentialsStore.shared.hasAPIKey
    }
    
    var currentBalance: BalanceInfo? {
        balanceInfos.first { $0.currency == preferredCurrency }
            ?? balanceInfos.first
    }
    
    var displayedBalances: [BalanceInfo] {
        if hideZeroBalance {
            return balanceInfos.filter { $0.totalBalanceDouble > 0 }
        }
        return balanceInfos
    }
    
    var currentBalanceText: String {
        guard let info = currentBalance else { return "--" }
        return "\(info.currency.symbol)\(info.formattedTotalBalance)"
    }
    
    var shortBalanceText: String {
        guard let info = currentBalance else { return "--" }
        let balance = info.totalBalanceDouble
        
        if balance >= 1000 {
            return "\(info.currency.symbol)\(Int(balance))"
        } else if balance >= 100 {
            return "\(info.currency.symbol)\(Int(balance))"
        } else {
            return "\(info.currency.symbol)\(String(format: "%.1f", balance))"
        }
    }
    
    var lastRefreshTimeText: String {
        guard let time = lastRefreshTime else { return "Never" }
        return Formatters.relativeTimeFormatter.localizedString(for: time, relativeTo: Date())
    }
    
    var statusText: String {
        switch status {
        case .idle: return L10n.Ready.text
        case .refreshing: return L10n.Refreshing.text
        case .success: return L10n.Updated.text
        case .failure(let error): return error.userFriendlyMessage
        }
    }
    
    var isRefreshing: Bool {
        status.isRefreshing
    }
    
    func initialLoad() async {
        AppLogger.log("Initial load started")
        await refresh()
    }
    
    func refresh() async {
        guard !status.isRefreshing else { return }
        
        AppLogger.log("Starting refresh")
        status = .refreshing
        statusBarText = "..."
        
        do {
            let infos = try await provider.fetchBalance()
            balanceInfos = infos
            lastRefreshTime = Date()
            status = .success(Date())
            
            addToHistory(infos: infos)
            checkLowBalance()
            updateStatusBarText()
            AppLogger.log("Refresh succeeded: \(infos.count) balance(s)")
        } catch let error as BalanceError {
            status = .failure(error)
            statusBarText = "!"
            AppLogger.log("Refresh failed: \(error.errorDescription)")
        } catch {
            status = .failure(.unknown(error.localizedDescription))
            statusBarText = "!"
            AppLogger.log("Refresh failed: \(error)")
        }
    }
    
    func testConnection() async -> Bool {
        AppLogger.log("Testing connection")
        do {
            let result = try await provider.testConnection()
            AppLogger.log("Connection test result: \(result)")
            return result
        } catch {
            AppLogger.log("Connection test failed: \(error)")
            return false
        }
    }
    
    private func updateStatusBarText() {
        statusBarText = shortBalanceText
    }
    
    private func setupAutoRefresh() async {
        restartAutoRefresh()
    }
    
    private func restartAutoRefresh() {
        autoRefreshTask?.cancel()
        let frequency = refreshFrequency
        AppLogger.log("Setting up auto-refresh: \(frequency.displayName)")
        
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(frequency.rawValue) * 1_000_000_000)
                if !Task.isCancelled { await refresh() }
            }
        }
    }
    
    private func addToHistory(infos: [BalanceInfo]) {
        guard let info = infos.first(where: { $0.currency == preferredCurrency }) ?? infos.first else { return }
        let record = BalanceRecord(timestamp: Date(), currency: info.currency, balance: info.totalBalanceDouble)
        balanceHistory.append(record)
        if balanceHistory.count > 100 { balanceHistory.removeFirst(balanceHistory.count - 100) }
    }
    
    private func checkLowBalance() {
        guard let info = currentBalance else { return }
        let currentBalance = info.totalBalanceDouble
        
        if lowBalanceThreshold > 0 && currentBalance < lowBalanceThreshold {
            if hasNotifiedLowBalance { return }
            if let lastNotification = lastLowBalanceNotification, Date().timeIntervalSince(lastNotification) < 3600 { return }
            sendLowBalanceNotification(balance: currentBalance, currency: info.currency)
            hasNotifiedLowBalance = true
        } else {
            hasNotifiedLowBalance = false
            lastLowBalanceNotification = nil
        }
    }
    
    private func requestNotificationPermission() async {
        do {
            let center = UNUserNotificationCenter.current()
            try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            AppLogger.log("Notification permission error: \(error)")
        }
    }
    
    private func sendLowBalanceNotification(balance: Double, currency: Currency) {
        let content = UNMutableNotificationContent()
        content.title = "Low Balance Warning"
        content.body = "Your \(currency.displayName) balance (\(currency.symbol)\(String(format: "%.2f", balance))) is below \(currency.symbol)\(Int(lowBalanceThreshold))"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "low-balance-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                AppLogger.log("Failed to send notification: \(error)")
            }
        }
    }
    
    func quit() {
        AppLogger.log("App quit requested")
        autoRefreshTask?.cancel()
        refreshTask?.cancel()
        NSApplication.shared.terminate(nil)
    }
}

struct BalanceRecord: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let currency: Currency
    let balance: Double
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}