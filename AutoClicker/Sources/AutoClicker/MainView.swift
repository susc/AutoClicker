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
        VStack(spacing: 0) {
            // Header
            HeaderView()

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    ClickSettingsCard()
                    PositionSettingsCard()
                    HotkeySettingsCard()
                }
                .padding(16)
            }

            Divider()

            // Bottom
            BottomView()
        }
        .frame(width: 400)
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
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("AutoClicker")
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if clickManager.state == .running {
                        Text("· \(clickManager.currentClickCount) 次")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }

    private var statusColor: Color {
        switch clickManager.state {
        case .stopped: return .gray
        case .running: return .green
        case .paused: return .orange
        }
    }

    private var statusText: String {
        switch clickManager.state {
        case .stopped: return "就绪"
        case .running: return "运行中"
        case .paused: return "已暂停"
        }
    }
}

// MARK: - Click Settings Card

struct ClickSettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("点击设置", systemImage: "cursorarrow.click")
                .font(.system(size: 13, weight: .semibold))

            VStack(spacing: 0) {
                // Click Count
                RowItem(title: "点击次数", icon: "number") {
                    HStack(spacing: 8) {
                        TextField("", value: $clickManager.settings.clickCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .onChange(of: clickManager.settings.clickCount) { _, newValue in
                                if newValue < 0 { clickManager.settings.clickCount = 0 }
                            }

                        Text("0 = 无限")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Divider().padding(.leading, 36)

                // Click Interval
                RowItem(title: "点击间隔", icon: "clock") {
                    HStack(spacing: 8) {
                        TextField("", value: $clickManager.settings.clickInterval, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .onChange(of: clickManager.settings.clickInterval) { _, newValue in
                                if newValue < 0 { clickManager.settings.clickInterval = 0 }
                            }

                        Picker("", selection: $clickManager.settings.clickIntervalUnit) {
                            ForEach(ClickSettings.IntervalUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 90)
                    }
                }

                Divider().padding(.leading, 36)

                // Click Button
                RowItem(title: "点击按钮", icon: "hand.point.up") {
                    Picker("", selection: $clickManager.settings.clickButton) {
                        ForEach(ClickButton.allCases) { button in
                            Text(button.rawValue).tag(button)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Position Settings Card

struct PositionSettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("位置设置", systemImage: "location")
                .font(.system(size: 13, weight: .semibold))

            VStack(spacing: 0) {
                RowItem(title: "模式", icon: "scope") {
                    Picker("", selection: $clickManager.settings.positionMode) {
                        ForEach(PositionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if clickManager.settings.positionMode == .fixedPosition {
                    Divider().padding(.leading, 36)

                    RowItem(title: "坐标", icon: "point.topleft.down.to.point.bottomright.curvepath") {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("X")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                TextField("", value: $clickManager.settings.fixedX, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                    .onChange(of: clickManager.settings.fixedX) { _, newValue in
                                        if newValue < 0 { clickManager.settings.fixedX = 0 }
                                    }
                            }

                            HStack(spacing: 4) {
                                Text("Y")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                TextField("", value: $clickManager.settings.fixedY, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 70)
                                    .onChange(of: clickManager.settings.fixedY) { _, newValue in
                                        if newValue < 0 { clickManager.settings.fixedY = 0 }
                                    }
                            }

                            Button(action: {
                                clickManager.isPickingPosition = true
                            }) {
                                Image(systemName: "location.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Hotkey Settings Card

struct HotkeySettingsCard: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快捷键", systemImage: "keyboard")
                .font(.system(size: 13, weight: .semibold))

            VStack(spacing: 0) {
                RowItem(title: "开始/停止", icon: "play.square") {
                    if clickManager.isRecordingHotKey {
                        HStack(spacing: 8) {
                            Text("按下快捷键...")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)

                            Button("取消") {
                                clickManager.isRecordingHotKey = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text(clickManager.hotKeyDisplay)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(4)

                            Button("修改") {
                                clickManager.isRecordingHotKey = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button("重置") {
                                clickManager.resetHotKey()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                if clickManager.isRecordingHotKey {
                    Divider().padding(.leading, 36)

                    HStack {
                        Text("请按下您想要使用的快捷键组合")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Row Item

struct RowItem<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Bottom View

struct BottomView: View {
    @EnvironmentObject var clickManager: ClickManager

    var body: some View {
        HStack {
            Spacer()

            Button(action: {
                if !clickManager.checkAccessibilityPermission() {
                    return
                }
                clickManager.toggleClicking()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: clickManager.state == .running ? "stop.fill" : "play.fill")
                    Text(clickManager.state == .running ? "停止" : "开始")
                }
                .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(clickManager.state == .running ? .red : .accentColor)

            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    MainView()
        .environmentObject(ClickManager())
}
