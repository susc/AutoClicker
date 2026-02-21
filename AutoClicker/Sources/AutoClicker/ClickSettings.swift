import Foundation
import CoreGraphics

enum ClickButton: String, CaseIterable, Identifiable {
    case left = "左键"
    case right = "右键"
    case middle = "中键"

    var id: String { rawValue }

    var cgEventType: CGEventType {
        switch self {
        case .left: return .leftMouseDown
        case .right: return .rightMouseDown
        case .middle: return .otherMouseDown
        }
    }

    var cgEventUpType: CGEventType {
        switch self {
        case .left: return .leftMouseUp
        case .right: return .rightMouseUp
        case .middle: return .otherMouseUp
        }
    }
}

enum PositionMode: String, CaseIterable, Identifiable {
    case currentMouse = "当前鼠标位置"
    case fixedPosition = "指定位置"

    var id: String { rawValue }
}

struct ClickSettings {
    var clickCount: Int = 1
    var clickInterval: Double = 100 // milliseconds
    var clickIntervalUnit: IntervalUnit = .milliseconds
    var clickButton: ClickButton = .left
    var positionMode: PositionMode = .currentMouse
    var fixedX: Double = 0
    var fixedY: Double = 0

    enum IntervalUnit: String, CaseIterable, Identifiable {
        case milliseconds = "毫秒"
        case seconds = "秒"

        var id: String { rawValue }

        func toMilliseconds(_ value: Double) -> Double {
            switch self {
            case .milliseconds: return value
            case .seconds: return value * 1000
            }
        }

        func fromMilliseconds(_ ms: Double) -> Double {
            switch self {
            case .milliseconds: return ms
            case .seconds: return ms / 1000
            }
        }
    }

    var intervalInMilliseconds: Double {
        clickIntervalUnit.toMilliseconds(clickInterval)
    }
}
