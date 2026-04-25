import Foundation

struct LightScenePreset: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: HSVColor

    static let presets: [LightScenePreset] = [
        LightScenePreset(id: "focus", title: "Focus", icon: "sun.max.fill", color: HSVColor(h: 42, s: 360, v: 1000)),
        LightScenePreset(id: "relax", title: "Relax", icon: "moon.fill", color: HSVColor(h: 24, s: 760, v: 780)),
        LightScenePreset(id: "neon", title: "Neon", icon: "sparkles", color: HSVColor(h: 278, s: 860, v: 1000)),
        LightScenePreset(id: "night", title: "Nuit", icon: "bed.double.fill", color: HSVColor(h: 220, s: 720, v: 320))
    ]
}

struct UserLightScene: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var icon: String
    var color: HSVColor
    var createdAt: Date

    init(id: UUID = UUID(), title: String, icon: String, color: HSVColor, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.createdAt = createdAt
    }
}
