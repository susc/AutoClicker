import SwiftUI
import Carbon
import AppKit

// MARK: - Position Picker Helper

func showPositionPickerWindow(
    fixedX: Binding<Double>,
    fixedY: Binding<Double>,
    onComplete: @escaping () -> Void
) {
    NSApp.windows.first?.orderOut(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        let pickerWindow = PositionPickerWindow(
            selectedX: fixedX,
            selectedY: fixedY,
            onComplete: onComplete
        )
        pickerWindow.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var clickManager: ClickManager
    @State private var recordingMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Status
                HeaderView()

                // Click Settings Card
                ClickSettingsCard()

                // Position Settings Card
                PositionSettingsCard()

                // Hotkey Settings Card
                HotkeySettingsCard()

                // Control Button
                ControlButton()
            }
            .padding(20)
        }
        .frame(minWidth: 380, idealWidth: 420, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: clickManager.isRecordingHotKey) { _, newValue in
            if newValue {
                startRecording()
            } else {
                stopRecording()
            }
        }
        .onChange(of: clickManager.isPickingPosition) { _, newValue in
            if newValue {
                showPositionPicker()
            }
        }
    }

    private func showPositionPicker() {
        showPositionPickerWindow(
            fixedX: Binding(
                get: { self.clickManager.settings.fixedX },
                set: { self.clickManager.settings.fixedX = $0 }
            ),
            fixedY: Binding(
                get: { self.clickManager.settings.fixedY },
                set: { self.clickManager.settings.fixedY = $0 }
            ),
            onComplete: {
                self.clickManager.isPickingPosition = false
            }
        )
    }

    private func startRecording() {
        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let keyCode = event.keyCode
            if keyCode == 54 || keyCode == 55 || keyCode == 56 || keyCode == 57 ||
               keyCode == 58 || keyCode == 59 || keyCode == 60 || keyCode == 61 ||
               keyCode == 62 || keyCode == 63 {
                return event
            }

            var display = ""
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if modifiers.contains(.control) { display += "⌃" }
            if modifiers.contains(.option) { display += "⌥" }
            if modifiers.contains(.shift) { display += "⇧" }
            if modifiers.contains(.command) { display += "⌘" }

            let keyName = keyCodeToString(Int(keyCode))
            display += keyName

            clickManager.updateHotKey(
                keyCode: Int(keyCode),
                modifiers: modifiers,
                display: display
            )
            clickManager.isRecordingHotKey = false

            return nil
        }
    }

    private func stopRecording() {
        if let monitor = recordingMonitor {
            NSEvent.removeMonitor(monitor)
            recordingMonitor = nil
        }
    }

    private func keyCodeToString(_ keyCode: Int) -> String {
        let keyMap: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 50: "`", 65: ".", 67: "*", 69: "+",
            71: "Clear", 75: "/", 76: "Enter", 78: "-", 81: "=",
            82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5",
            88: "6", 89: "7", 91: "8", 92: "9",
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
            113: "F15", 118: "F4", 119: "F2", 120: "F1", 122: "F16", 123: "←",
            124: "→", 125: "↓", 126: "↑"
        ]
        return keyMap[keyCode] ?? "?"
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.headline)

                if clickManager.state == .running {
                    Text("已点击 \(clickManager.currentClickCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // App icon placeholder
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch clickManager.state {
        case .stopped: return .red
        case .running: return .green
        case .paused: return .orange
        }
    }

    private var statusText: String {
        switch clickManager.state {
        case .stopped: return "等待开始"
        case .running: return "正在运行"
        case .paused: return "已暂停"
        }
    }
}

// MARK: - Click Settings Card

struct ClickSettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("点击设置", systemImage: "cursorarrow.click")
                .font(.headline)

            VStack(spacing: 12) {
                // Click Count
                SettingRow(icon: "number", title: "点击次数") {
                    HStack(spacing: 8) {
                        TextField("", value: $clickManager.settings.clickCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: clickManager.settings.clickCount) { _, newValue in
                                if newValue < 0 { clickManager.settings.clickCount = 0 }
                            }

                        Text("(0 = 无限)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Click Interval
                SettingRow(icon: "clock", title: "点击间隔") {
                    HStack(spacing: 8) {
                        TextField("", value: $clickManager.settings.clickInterval, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: clickManager.settings.clickInterval) { _, newValue in
                                if newValue < 0 { clickManager.settings.clickInterval = 0 }
                            }

                        Picker("", selection: $clickManager.settings.clickIntervalUnit) {
                            ForEach(ClickSettings.IntervalUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }

                Divider()

                // Click Button
                SettingRow(icon: "hand.point.up", title: "点击按钮") {
                    Picker("", selection: $clickManager.settings.clickButton) {
                        ForEach(ClickButton.allCases) { button in
                            Text(button.rawValue).tag(button)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Position Settings Card

struct PositionSettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("位置设置", systemImage: "location")
                .font(.headline)

            // Position Mode Picker
            Picker("", selection: $clickManager.settings.positionMode) {
                ForEach(PositionMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Fixed Position Inputs
            if clickManager.settings.positionMode == .fixedPosition {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("X 坐标")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("", value: $clickManager.settings.fixedX, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: clickManager.settings.fixedX) { _, newValue in
                                if newValue < 0 { clickManager.settings.fixedX = 0 }
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y 坐标")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("", value: $clickManager.settings.fixedY, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: clickManager.settings.fixedY) { _, newValue in
                                if newValue < 0 { clickManager.settings.fixedY = 0 }
                            }
                    }

                    Spacer()

                    Button(action: {
                        clickManager.isPickingPosition = true
                    }) {
                        Label("选择位置", systemImage: "location.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Hotkey Settings Card

struct HotkeySettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("快捷键", systemImage: "keyboard")
                .font(.headline)

            HStack {
                Text("开始/停止:")
                    .foregroundColor(.secondary)

                if clickManager.isRecordingHotKey {
                    Text("按下快捷键...")
                        .foregroundColor(.blue)
                } else {
                    Text(clickManager.hotKeyDisplay)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                }

                Spacer()

                if clickManager.isRecordingHotKey {
                    Button("取消") {
                        clickManager.isRecordingHotKey = false
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("修改") {
                        clickManager.isRecordingHotKey = true
                    }
                    .buttonStyle(.bordered)

                    Button("重置") {
                        clickManager.resetHotKey()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if clickManager.isRecordingHotKey {
                Text("请按下您想要使用的快捷键组合")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        Button(action: {
            if !clickManager.checkAccessibilityPermission() {
                return
            }
            clickManager.toggleClicking()
        }) {
            HStack(spacing: 8) {
                Image(systemName: clickManager.state == .running ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text(clickManager.state == .running ? "停止自动点击" : "开始自动点击")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(clickManager.state == .running ? Color.red : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setting Row

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            content()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(ClickManager())
}
