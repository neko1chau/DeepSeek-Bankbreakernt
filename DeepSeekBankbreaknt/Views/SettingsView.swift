import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @State private var apiKeyInput: String = ""
    @State private var showTestResult: Bool = false
    @State private var testResultSuccess: Bool = false
    @State private var isTesting: Bool = false
    @State private var isSaving: Bool = false
    
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("lowBalanceThreshold") private var lowBalanceThreshold: Double = 0
    @AppStorage("hideZeroBalance") private var hideZeroBalance: Bool = false
    
    var body: some View {
        Form {
            Section {
                apiKeySection
            } header: { Text(L10n.APIConfig.title) }
            
            Section {
                currencySection
                refreshFrequencySection
                lowBalanceThresholdSection
                hideZeroBalanceSection
            } header: { Text("Display Settings") }
            
            Section {
                launchAtLoginToggle
            } header: { Text(L10n.Startup.title) }
            
            Section {
                aboutSection
                updateSection
            } header: { Text(L10n.About.title) }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
        .onAppear {
            apiKeyInput = CredentialsStore.shared.apiKey ?? ""
            launchAtLogin = SettingsStore.shared.launchAtLogin
            lowBalanceThreshold = SettingsStore.shared.lowBalanceThreshold
            hideZeroBalance = SettingsStore.shared.hideZeroBalance
        }
    }
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SecureField("API Key", text: $apiKeyInput).textFieldStyle(.roundedBorder)

            HStack {
                Button(action: testConnection) {
                    HStack(spacing: 4) {
                        if isTesting { ProgressView().controlSize(.small) }
                        Text(L10n.TestConnection.button)
                    }
                }
                .controlSize(.small)
                .disabled(apiKeyInput.isEmpty || isTesting)

                Button(action: saveAPIKey) {
                    HStack(spacing: 4) {
                        if isSaving { ProgressView().controlSize(.small) }
                        Text(L10n.Save.button)
                    }
                }
                .controlSize(.small)
                .disabled(apiKeyInput.isEmpty || isSaving)
                .buttonStyle(.borderedProminent)

                Spacer()
            }

            if showTestResult {
                HStack {
                    Image(systemName: testResultSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(testResultSuccess ? .green : .red)
                    Text(testResultSuccess ? L10n.ConnectionSuccess.message : L10n.ConnectionFailed.message)
                        .font(.caption).foregroundColor(testResultSuccess ? .green : .red)
                }
            }
        }
    }
    
    private var currencySection: some View {
        Picker(L10n.PreferredCurrency.title, selection: $viewModel.preferredCurrency) {
            ForEach(Currency.allCases) { currency in Text(currency.displayName).tag(currency) }
        }
    }
    
    private var refreshFrequencySection: some View {
        Picker(L10n.AutoRefresh.title, selection: $viewModel.refreshFrequency) {
            ForEach(RefreshFrequency.allCases) { frequency in Text(frequency.displayName).tag(frequency) }
        }
        .pickerStyle(.segmented)
    }
    
    private var lowBalanceThresholdSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.LowBalanceAlert.title)
                Spacer()
                Text(lowBalanceThreshold == 0 ? L10n.Off.label : "\(viewModel.preferredCurrency.symbol)\(Int(lowBalanceThreshold))")
                    .foregroundColor(.secondary)
            }
            Slider(value: $lowBalanceThreshold, in: 0...20, step: 1).onChange(of: lowBalanceThreshold) { newValue in viewModel.lowBalanceThreshold = newValue }
        }
    }
    
    private var hideZeroBalanceSection: some View {
        Toggle(L10n.HideZeroBalance.title, isOn: $hideZeroBalance)
            .onChange(of: hideZeroBalance) { newValue in viewModel.hideZeroBalance = newValue }
    }
    
    private var launchAtLoginToggle: some View {
        Toggle(L10n.LaunchAtLogin.title, isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { newValue in SettingsStore.shared.launchAtLogin = newValue }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent(L10n.Version.title, value: "1.0.2")
            LabeledContent("Build", value: "1")
            Text("很惭愧，只做了一点微小的工作。").font(.caption).foregroundColor(.secondary)
            LabeledContent("Credits", value: "Toast1 Vibe Coding")
            HStack { Toggle(L10n.UseMockProvider.title, isOn: $viewModel.useMockProvider); Spacer() }
        }
    }

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.updateState {
            case .idle:
                Button(action: { Task { await viewModel.checkForUpdate() } }) {
                    HStack { Image(systemName: "arrow.down.circle"); Text("Check for Updates") }
                }
            case .checking:
                HStack { ProgressView(); Text("Checking..."); Spacer() }
            case .available(let release):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill").foregroundColor(.green)
                        Text("Version \(release.version) available").fontWeight(.medium)
                    }
                    Text("Release: \(release.tagName)").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Button("Download") { Task { await viewModel.downloadUpdate() } }
                            .buttonStyle(.borderedProminent)
                        Button("Dismiss") { viewModel.dismissUpdate() }
                    }
                }
            case .downloading(let progress):
                VStack(alignment: .leading, spacing: 4) {
                    Text("Downloading...")
                    ProgressView(value: progress).progressViewStyle(.linear)
                    Text("\(Int(progress * 100))%").font(.caption).foregroundColor(.secondary)
                }
            case .ready:
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Update Ready")
                    Button("Install & Restart") { viewModel.installUpdate() }
                        .buttonStyle(.borderedProminent)
                }
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                    Text(message).font(.caption).foregroundColor(.red)
                    Button("Retry") { Task { await viewModel.checkForUpdate() } }
                }
            }
        }
    }
    
    private func testConnection() {
        isTesting = true; showTestResult = false
        let tempKey = apiKeyInput
        let originalKey = CredentialsStore.shared.apiKey
        CredentialsStore.shared.apiKey = tempKey
        
        Task {
            let success = await viewModel.testConnection()
            await MainActor.run {
                testResultSuccess = success; showTestResult = true; isTesting = false
                if originalKey != tempKey { CredentialsStore.shared.apiKey = originalKey }
            }
        }
    }
    
    private func saveAPIKey() {
        isSaving = true
        CredentialsStore.shared.apiKey = apiKeyInput
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaving = false
            Task { await self.viewModel.refresh() }
        }
    }
}