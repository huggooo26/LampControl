import AppKit
import Foundation

enum ShortcutAction: String, Codable, CaseIterable, Identifiable {
    case powerOffAll
    case powerOnAll
    case applySceneFocus
    case applySceneRelax
    case applySceneNeon
    case applySceneNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .powerOffAll:      return "Éteindre tout"
        case .powerOnAll:       return "Allumer tout"
        case .applySceneFocus:  return "Scène Focus"
        case .applySceneRelax:  return "Scène Relax"
        case .applySceneNeon:   return "Scène Neon"
        case .applySceneNight:  return "Scène Nuit"
        }
    }

    var icon: String {
        switch self {
        case .powerOffAll:      return "power"
        case .powerOnAll:       return "power.circle.fill"
        case .applySceneFocus:  return "sun.max.fill"
        case .applySceneRelax:  return "moon.fill"
        case .applySceneNeon:   return "sparkles"
        case .applySceneNight:  return "bed.double.fill"
        }
    }
}

struct ShortcutBinding: Codable, Identifiable, Equatable {
    var id: String { action.rawValue }
    var action: ShortcutAction
    var keyCode: UInt16?
    var modifierFlags: UInt = NSEvent.ModifierFlags.option.rawValue
    var isEnabled: Bool = true

    var displayKey: String {
        guard let keyCode else { return "—" }
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option)  { parts.append("⌥") }
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.shift)   { parts.append("⇧") }
        let key: String
        switch keyCode {
        case 18: key = "1"; case 19: key = "2"; case 20: key = "3"
        case 21: key = "4"; case 23: key = "5"; case 29: key = "0"
        default: key = "?"
        }
        parts.append(key)
        return parts.joined()
    }
}

struct ShortcutSettings: Codable {
    var bindings: [ShortcutBinding]

    static let `default` = ShortcutSettings(bindings: [
        ShortcutBinding(action: .powerOffAll,     keyCode: 29, isEnabled: true),
        ShortcutBinding(action: .applySceneFocus, keyCode: 18, isEnabled: true),
        ShortcutBinding(action: .applySceneRelax, keyCode: 19, isEnabled: true),
        ShortcutBinding(action: .applySceneNeon,  keyCode: 20, isEnabled: true),
        ShortcutBinding(action: .applySceneNight, keyCode: 21, isEnabled: true),
        ShortcutBinding(action: .powerOnAll,      keyCode: nil, isEnabled: false),
    ])
}

extension Notification.Name {
    static let shortcutSettingsDidChange = Notification.Name("LampControl.shortcutSettingsDidChange")
}
