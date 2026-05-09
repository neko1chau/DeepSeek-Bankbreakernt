import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: BalanceViewModel
    weak var appDelegate: AppDelegate?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            balanceSection
            Divider()
            statusSection
            Divider()
            actionsSection
            Divider()
            settingsSection
        }
        .padding()
        .frame(width: 280)
    }
    
    private var headerSection: some View {
        HStack {
            Text(L10n.DeepSeekBalance.title).font(.headline)
            Spacer()
            if viewModel.useMockProvider {
                Text(L10n.Mock.label).font(.caption).padding(.horizontal, 6).padding(.vertical, 2).background(Color.orange.opacity(0.2)).cornerRadius(4)
            }
        }
    }
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.CurrentBalance.title).font(.caption).foregroundColor(.secondary)
            
            if viewModel.balanceInfos.isEmpty && !viewModel.isRefreshing {
                Text("--").font(.title2).fontWeight(.semibold)
            } else {
                ForEach(sortedBalanceInfos) { info in
                    HStack {
                        Text("\(info.currency.symbol)\(info.formattedTotalBalance)").font(.title2).fontWeight(.semibold)
                        Spacer()
                        if info.currency == viewModel.preferredCurrency {
                            Text(L10n.Preferred.label).font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).background(Color.accentColor.opacity(0.2)).cornerRadius(3)
                        }
                        Text(info.currency.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(L10n.Granted.label).font(.caption2).foregroundColor(.secondary)
                            Text("\(info.currency.symbol)\(info.grantedBalance)").font(.caption)
                        }
                        VStack(alignment: .leading) {
                            Text(L10n.ToppedUp.label).font(.caption2).foregroundColor(.secondary)
                            Text("\(info.currency.symbol)\(info.toppedUpBalance)").font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    private var sortedBalanceInfos: [BalanceInfo] {
        let infos = viewModel.displayedBalances
        let preferred = viewModel.preferredCurrency
        return infos.sorted { $0.currency == preferred && $1.currency != preferred }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(L10n.LastUpdated.title).font(.caption).foregroundColor(.secondary); Spacer(); Text(viewModel.lastRefreshTimeText).font(.caption) }
            HStack { Text(L10n.RefreshRate.title).font(.caption).foregroundColor(.secondary); Spacer(); Text(viewModel.refreshFrequency.displayName).font(.caption) }
            HStack { Text(L10n.Status.title).font(.caption).foregroundColor(.secondary); Spacer(); statusIndicator }
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch viewModel.status {
        case .idle: Text(L10n.Ready.text).font(.caption).foregroundColor(.secondary)
        case .refreshing: ProgressView().scaleEffect(0.6)
        case .success: Text(L10n.OK.text).font(.caption).foregroundColor(.green)
        case .failure(let error): Text(error.userFriendlyMessage).font(.caption).foregroundColor(.red).lineLimit(1)
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button(action: { Task { await viewModel.refresh() } }) {
                HStack { Image(systemName: "arrow.clockwise"); Text(L10n.Refresh.button) }
            }
            .buttonStyle(.bordered).disabled(viewModel.isRefreshing)
            Spacer()
        }
    }
    
    private var settingsSection: some View {
        HStack(spacing: 12) {
            Button(action: { appDelegate?.openSettingsWindow() }) {
                HStack { Image(systemName: "gear"); Text(L10n.Settings.button) }
            }
            .buttonStyle(.bordered)
            Spacer()
            Button(action: { viewModel.quit() }) {
                HStack { Image(systemName: "power"); Text(L10n.Quit.button) }
            }
            .buttonStyle(.bordered).tint(.red)
        }
    }
}