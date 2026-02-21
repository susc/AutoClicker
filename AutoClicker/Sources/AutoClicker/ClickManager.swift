import Foundation
import AppKit
import Combine
import Carbon

enum ClickState {
    case stopped
    case running
    case paused
}

class ClickManager: ObservableObject {
    @Published var state: ClickState = .stopped
    @Published var settings = ClickSettings()
    @Published var hotKeyDisplay: String = "F9"
    @Published var isRecordingHotKey: Bool = false
    @Published var isPickingPosition: Bool = false
    @Published var currentClickCount: Int = 0
    @Published var hotKeyKeyCode: Int = 96  // F9
    @Published var hotKeyModifiers: NSEvent.ModifierFlags = .command

    private var clickTimer: Timer?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let userDefaults = UserDefaults.standard

    init() {
        loadSettings()
        setupGlobalHotKey()
    }

    deinit {
        stopClicking()
        removeGlobalHotKey()
    }

    // MARK: - Settings Persistence

    func loadSettings() {
        settings.clickCount = userDefaults.integer(forKey: "clickCount")
        if settings.clickCount == 0 { settings.clickCount = 1 }

        settings.clickInterval = userDefaults.double(forKey: "clickInterval")
        if settings.clickInterval == 0 { settings.clickInterval = 100 }

        let unitRaw = userDefaults.string(forKey: "clickIntervalUnit") ?? "毫秒"
        settings.clickIntervalUnit = ClickSettings.IntervalUnit(rawValue: unitRaw) ?? .milliseconds

        let buttonRaw = userDefaults.string(forKey: "clickButton") ?? "左键"
        settings.clickButton = ClickButton(rawValue: buttonRaw) ?? .left

        let modeRaw = userDefaults.string(forKey: "positionMode") ?? "当前鼠标位置"
        settings.positionMode = PositionMode(rawValue: modeRaw) ?? .currentMouse

        settings.fixedX = userDefaults.double(forKey: "fixedX")
        settings.fixedY = userDefaults.double(forKey: "fixedY")

        hotKeyKeyCode = userDefaults.integer(forKey: "hotKeyKeyCode")
        if hotKeyKeyCode == 0 { hotKeyKeyCode = 96 }  // Default F9

        let modifiersRaw = userDefaults.integer(forKey: "hotKeyModifiers")
        hotKeyModifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiersRaw))
        if hotKeyModifiers.rawValue == 0 { hotKeyModifiers = .command }

        hotKeyDisplay = userDefaults.string(forKey: "hotKeyDisplay") ?? "⌘F9"
    }

    func saveSettings() {
        userDefaults.set(settings.clickCount, forKey: "clickCount")
        userDefaults.set(settings.clickInterval, forKey: "clickInterval")
        userDefaults.set(settings.clickIntervalUnit.rawValue, forKey: "clickIntervalUnit")
        userDefaults.set(settings.clickButton.rawValue, forKey: "clickButton")
        userDefaults.set(settings.positionMode.rawValue, forKey: "positionMode")
        userDefaults.set(settings.fixedX, forKey: "fixedX")
        userDefaults.set(settings.fixedY, forKey: "fixedY")
        userDefaults.set(hotKeyKeyCode, forKey: "hotKeyKeyCode")
        userDefaults.set(Int(hotKeyModifiers.rawValue), forKey: "hotKeyModifiers")
        userDefaults.set(hotKeyDisplay, forKey: "hotKeyDisplay")
    }

    // MARK: - Click Control

    func toggleClicking() {
        if state == .running {
            stopClicking()
        } else {
            startClicking()
        }
    }

    func startClicking() {
        guard state != .running else { return }

        saveSettings()
        currentClickCount = 0
        state = .running

        performClick()

        let interval = settings.intervalInMilliseconds / 1000.0
        clickTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performClick()
        }
    }

    func stopClicking() {
        clickTimer?.invalidate()
        clickTimer = nil
        state = .stopped
        currentClickCount = 0
    }

    private func performClick() {
        guard state == .running else { return }

        // Check if we've reached the click limit (0 means unlimited)
        if settings.clickCount > 0 && currentClickCount >= settings.clickCount {
            stopClicking()
            return
        }

        // Get click position
        var point: CGPoint
        if settings.positionMode == .currentMouse {
            point = NSEvent.mouseLocation
            // Convert from screen coordinates (origin at bottom-left) to CG coordinates
            if let screen = NSScreen.main {
                point.y = screen.frame.height - point.y
            }
        } else {
            point = CGPoint(x: settings.fixedX, y: settings.fixedY)
        }

        // Perform the click
        performMouseClick(at: point, button: settings.clickButton)

        self.currentClickCount += 1
    }

    private func performMouseClick(at point: CGPoint, button: ClickButton) {
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: button.cgEventType, mouseCursorPosition: point, mouseButton: button == .left ? .left : (button == .right ? .right : .center))
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: button.cgEventUpType, mouseCursorPosition: point, mouseButton: button == .left ? .left : (button == .right ? .right : .center))

        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }

    // MARK: - Global Hot Key

    private func setupGlobalHotKey() {
        removeGlobalHotKey()

        // Use NSEvent global monitor for keyboard events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Also add local monitor for when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil  // Consume the event
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Check if the key matches our hotkey
        if keyCode == hotKeyKeyCode && modifiers == hotKeyModifiers {
            DispatchQueue.main.async { [weak self] in
                self?.toggleClicking()
            }
            return true
        }
        return false
    }

    private func removeGlobalHotKey() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    func updateHotKey(keyCode: Int, modifiers: NSEvent.ModifierFlags, display: String) {
        hotKeyKeyCode = keyCode
        hotKeyModifiers = modifiers
        hotKeyDisplay = display
        saveSettings()
    }

    func resetHotKey() {
        hotKeyKeyCode = 96  // F9
        hotKeyModifiers = .command
        hotKeyDisplay = "⌘F9"
        saveSettings()
    }

    // MARK: - Mouse Position

    func captureCurrentMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.main {
            settings.fixedX = mouseLocation.x
            settings.fixedY = screen.frame.height - mouseLocation.y
        }
    }

    // MARK: - Accessibility Check

    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
