import Foundation

enum AutomationAction: Codable, Equatable, Hashable {
    case powerOffAll
    case powerOnAll
    case applyScenePreset(id: String)
    case applyProfile(id: UUID)
    case enableAdaptiveLighting
    case disableAdaptiveLighting

    var title: String {
        switch self {
        case .powerOffAll:              return "Éteindre tout"
        case .powerOnAll:               return "Allumer tout"
        case .applyScenePreset(let id): return "Scène \(id.capitalized)"
        case .applyProfile:             return "Appliquer un profil"
        case .enableAdaptiveLighting:   return "Activer l'éclairage adaptatif"
        case .disableAdaptiveLighting:  return "Désactiver l'éclairage adaptatif"
        }
    }

    var icon: String {
        switch self {
        case .powerOffAll:            return "power"
        case .powerOnAll:             return "power.circle.fill"
        case .applyScenePreset:       return "paintpalette.fill"
        case .applyProfile:           return "square.stack.3d.up.fill"
        case .enableAdaptiveLighting: return "sun.and.horizon.fill"
        case .disableAdaptiveLighting:return "sun.and.horizon"
        }
    }
}

struct Automation: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var isEnabled: Bool = true
    var hour: Int
    var minute: Int
    var weekdays: Set<Int> = []   // empty = every day; 1=Mon … 7=Sun
    var action: AutomationAction
    var lastFiredDate: Date?

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var weekdaysLabel: String {
        if weekdays.isEmpty { return "Chaque jour" }
        let names = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
        return weekdays.sorted().compactMap { names[safe: $0 - 1] }.joined(separator: ", ")
    }

    func shouldFire(at date: Date, calendar: Calendar) -> Bool {
        guard isEnabled else { return false }
        let comps = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        guard comps.hour == hour, comps.minute == minute else { return false }
        if !weekdays.isEmpty {
            // Calendar weekday: 1=Sun, 2=Mon … 7=Sat → convert to 1=Mon … 7=Sun
            let wd = ((comps.weekday ?? 1) + 5) % 7 + 1
            guard weekdays.contains(wd) else { return false }
        }
        return true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
