import SwiftUI
import AppKit

@main
struct AutoClickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clickManager = ClickManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(clickManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }
        }
    }

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
