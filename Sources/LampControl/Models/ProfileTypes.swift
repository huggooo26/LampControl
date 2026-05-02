import Foundation

struct LampSnapshot: Codable, Equatable {
    var lampId: String
    var nativeID: String
    var providerID: LightProviderKind
    var name: String
    var power: Bool
    var brightness: Int?
    var temperature: Int?
    var color: HSVColor?
}

struct LampProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var icon: String = "square.stack.3d.up.fill"
    var snapshots: [LampSnapshot] = []
    var createdAt: Date = Date()
}
