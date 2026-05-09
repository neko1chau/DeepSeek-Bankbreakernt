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
            } header: { Text(L10n.About.title) }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
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
                    HStack { if isTesting { ProgressView().scaleEffect(0.6) }; Text(L10n.TestConnection.button) }
                }
                .disabled(apiKeyInput.isEmpty || isTesting)
                
                Button(action: saveAPIKey) {
                    HStack { if isSaving { ProgressView().scaleEffect(0.6) }; Text(L10n.Save.button) }
                }
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
            LabeledContent(L10n.Version.title, value: "1.0.0")
            LabeledContent("Build", value: "1")
            Text("很惭愧，只做了一点微小的工作。").font(.caption).foregroundColor(.secondary)
            LabeledContent("Credits", value: "Toast1 Vibe Coding")
            Spacer()
            HStack { Toggle(L10n.UseMockProvider.title, isOn: $viewModel.useMockProvider); Spacer() }
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