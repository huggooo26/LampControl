import Foundation

struct YeelightSettings: Codable, Equatable {
    var bulbs: [YeelightBulb] = []

    var isConfigured: Bool {
        !bulbs.isEmpty
    }
}

struct YeelightBulb: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var host: String
    var port: Int
    var name: String

    init(id: String = UUID().uuidString, host: String, port: Int = 55443, name: String = "") {
        self.id = id
        self.host = host
        self.port = port
        self.name = name.isEmpty ? host : name
    }
}

struct YeelightResponse: Decodable {
    let id: Int?
    let result: [String]?
    let error: YeelightErrorPayload?
}

struct YeelightErrorPayload: Decodable {
    let code: Int
    let message: String
}
