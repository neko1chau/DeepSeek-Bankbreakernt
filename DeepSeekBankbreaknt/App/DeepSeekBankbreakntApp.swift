import SwiftUI
import AppKit
import Combine

@main
struct DeepSeekBankbreakntApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(viewModel: AppDelegate.shared.viewModel)
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    let viewModel: BalanceViewModel
    
    private var statusItem: NSStatusItem?
    private var popOver: NSPopover?
    private var settingsWindow: NSWindow?
    private var cancellable: AnyCancellable?
    private var observer: NSObjectProtocol?
    private var eventMonitor: Any?
    
    override init() {
        self.viewModel = BalanceViewModel()
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupNotificationObserver()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateButtonTitle()
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        cancellable = viewModel.$statusBarText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonTitle()
            }
        
        Task {
            await viewModel.initialLoad()
        }
    }
    
    private func setupNotificationObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettingsWindow()
        }
    }
    
    func openSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "DeepSeek Bankbreaknt Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 400, height: 420))
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @MainActor
    private func updateButtonTitle() {
        guard let button = statusItem?.button else { return }
        let text = viewModel.menuBarTitle
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popOver?.isShown == true {
            closePopover()
            return
        }

        let popOver = NSPopover()
        popOver.contentSize = NSSize(width: 280, height: 340)
        popOver.behavior = .transient
        popOver.contentViewController = NSHostingController(rootView: MenuBarView(viewModel: viewModel, appDelegate: self))

        popOver.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popOver = popOver
        startEventMonitor()
    }

    private func closePopover() {
        popOver?.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popOver?.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
