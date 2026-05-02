import Foundation

struct LightScenePreset: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: HSVColor

    static let presets: [LightScenePreset] = [
        LightScenePreset(id: "focus", title: "Focus",  icon: "sun.max.fill",    color: HSVColor(h: 42,  s: 360, v: 1000)),
        LightScenePreset(id: "relax", title: "Relax",  icon: "moon.fill",       color: HSVColor(h: 24,  s: 760, v: 780)),
        LightScenePreset(id: "neon",  title: "Neon",   icon: "sparkles",        color: HSVColor(h: 278, s: 860, v: 1000)),
        LightScenePreset(id: "night", title: "Nuit",   icon: "bed.double.fill", color: HSVColor(h: 220, s: 720, v: 320)),
    ]
}

/// Snapshot of a single lamp's state, used by capture-type scenes.
struct LampSnapshot: Codable, Equatable, Hashable {
    var lampId: String
    var nativeID: String
    var providerID: LightProviderKind
    var name: String
    var power: Bool
    var brightness: Int?
    var temperature: Int?
    var color: HSVColor?
}

struct UserLightScene: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var icon: String
    var color: HSVColor          // used for display tint; ignored when snapshots ≠ nil
    var snapshots: [LampSnapshot]? // nil → colour scene · non-nil → full-state capture
    var createdAt: Date

    /// True when this scene was captured from live lamp state (not colour-only).
    var isCapture: Bool { snapshots != nil }

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        color: HSVColor,
        snapshots: [LampSnapshot]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.snapshots = snapshots
        self.createdAt = createdAt
    }
}
