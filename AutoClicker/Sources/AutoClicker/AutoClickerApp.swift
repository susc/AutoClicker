import SwiftUI

@main
struct AutoClickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clickManager = ClickManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(clickManager)
                .frame(minWidth: 380, idealWidth: 420)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
