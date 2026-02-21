import SwiftUI
import AppKit

// MARK: - Position Picker Window

class PositionPickerWindow: NSWindow {
    private var onComplete: ((Double, Double) -> Void)?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var escapeMonitor: Any?

    init(selectedX: Binding<Double>, selectedY: Binding<Double>, onComplete: @escaping () -> Void) {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Create bindings that will be updated
        let xBinding = selectedX
        let yBinding = selectedY

        let pickerView = PositionPickerView(
            onDismiss: { [weak self] in
                self?.close()
            }
        )
        self.contentView = NSHostingView(rootView: pickerView)

        // Store the bindings to update later
        self.onComplete = { x, y in
            xBinding.wrappedValue = x
            yBinding.wrappedValue = y
            onComplete()
        }

        setupEventMonitors()
    }

    private func setupEventMonitors() {
        // Listen for click
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.handleSelection()
        }

        // Also listen when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.handleSelection()
            return nil
        }

        // Listen for escape key
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.close()
                return nil
            }
            return event
        }
    }

    private func handleSelection() {
        // Get the current mouse location
        let location = NSEvent.mouseLocation

        // Convert from screen coordinates (origin at bottom-left) to our coordinates
        if let screen = NSScreen.main {
            let x = location.x
            let y = screen.frame.height - location.y
            onComplete?(x, y)
        }

        close()
    }

    override func close() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }

        orderOut(nil)

        // Show main window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    deinit {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = escapeMonitor { NSEvent.removeMonitor(monitor) }
    }
}

// MARK: - Position Picker View

struct PositionPickerView: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // Instructions
            VStack {
                Text("点击屏幕选择位置")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding()

                Text("按 ESC 取消")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
        .onAppear {
            NSCursor.crosshair.push()
        }
        .onDisappear {
            NSCursor.pop()
        }
    }
}
