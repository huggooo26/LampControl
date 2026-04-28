import Foundation
import Network

final class YeelightClient {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 4.0) {
        self.timeout = timeout
    }

    func sendCommand(host: String, port: Int, method: String, params: [Any]) async throws -> [String] {
        let payload: [String: Any] = [
            "id": Int.random(in: 1...10_000),
            "method": method,
            "params": params
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        guard var line = String(data: data, encoding: .utf8) else {
            throw LampControlError.invalidResponse
        }
        line.append("\r\n")

        let response = try await exchange(host: host, port: port, command: line)
        return try parse(response: response)
    }

    private func parse(response: String) throws -> [String] {
        for raw in response.split(separator: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { continue }
            let decoded = try? JSONDecoder().decode(YeelightResponse.self, from: data)
            if let error = decoded?.error {
                throw LampControlError.tuya("Yeelight: \(error.message) (\(error.code))")
            }
            if let result = decoded?.result {
                return result
            }
        }

        throw LampControlError.invalidResponse
    }

    private func exchange(host: String, port: Int, command: String) async throws -> String {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            throw LampControlError.configuration("Port Yeelight invalide.")
        }

        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        let timeout = self.timeout

        return try await withCheckedThrowingContinuation { continuation in
            let lock = NSLock()
            var finished = false

            func finish(_ result: Result<String, Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(with: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let payload = command.data(using: .utf8) ?? Data()
                    connection.send(content: payload, completion: .contentProcessed { sendError in
                        if let sendError {
                            finish(.failure(LampControlError.tuya("Yeelight: \(sendError.localizedDescription)")))
                            return
                        }
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, _, receiveError in
                            if let receiveError {
                                finish(.failure(LampControlError.tuya("Yeelight: \(receiveError.localizedDescription)")))
                                return
                            }
                            guard let data, let text = String(data: data, encoding: .utf8) else {
                                finish(.failure(LampControlError.invalidResponse))
                                return
                            }
                            finish(.success(text))
                        }
                    })
                case .failed(let error):
                    finish(.failure(LampControlError.tuya("Yeelight: \(error.localizedDescription)")))
                case .cancelled:
                    finish(.failure(LampControlError.offline))
                default:
                    break
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                finish(.failure(LampControlError.tuya("Yeelight: délai dépassé. Vérifiez que LAN Control est activé.")))
            }

            connection.start(queue: .global())
        }
    }
}
