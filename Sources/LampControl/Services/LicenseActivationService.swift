import AppKit
import Foundation

struct LicenseProviderConfig {
    static let providerName = "Lemon Squeezy"
    static let checkoutURL = Bundle.main.stringValue(forInfoDictionaryKey: "LCLicenseCheckoutURL").flatMap(URL.init(string:))
    static let expectedStoreID = Bundle.main.integerValue(forInfoDictionaryKey: "LCLicenseExpectedStoreID")
    static let expectedProductID = Bundle.main.integerValue(forInfoDictionaryKey: "LCLicenseExpectedProductID")
    static let expectedVariantID = Bundle.main.integerValue(forInfoDictionaryKey: "LCLicenseExpectedVariantID")
}

enum LicenseActivationError: LocalizedError {
    case invalidKey
    case emailMismatch
    case missingInstance
    case requestFailed(String)
    case unexpectedResponse
    case unexpectedProduct

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            "Clé de licence invalide."
        case .emailMismatch:
            "L'email ne correspond pas à cette licence."
        case .missingInstance:
            "Cette licence n'a pas d'activation locale."
        case .requestFailed(let message):
            message
        case .unexpectedResponse:
            "Réponse de licence illisible."
        case .unexpectedProduct:
            "Cette licence ne correspond pas au produit LampControl."
        }
    }
}

final class LicenseActivationService {
    private let baseURL = URL(string: "https://api.lemonsqueezy.com/v1/licenses")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func activate(licenseKey: String, expectedEmail: String?) async throws -> LicenseState {
        let cleanKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { throw LicenseActivationError.invalidKey }

        let response = try await perform(
            endpoint: "activate",
            fields: [
                "license_key": cleanKey,
                "instance_name": Self.defaultInstanceName()
            ]
        )

        guard response.activated == true, response.licenseKey?.status != "disabled" else {
            throw LicenseActivationError.requestFailed(response.errorMessage ?? "Activation impossible.")
        }

        try validateExpectedProduct(response.meta)
        try validateExpectedEmail(expectedEmail, responseEmail: response.meta?.customerEmail)

        return LicenseState(
            tier: .premium,
            provider: .lemonSqueezy,
            licenseKey: cleanKey,
            instanceID: response.instance?.id,
            instanceName: response.instance?.name ?? Self.defaultInstanceName(),
            customerEmail: response.meta?.customerEmail,
            productName: response.meta?.productName,
            activatedAt: Date(),
            validatedAt: Date()
        )
    }

    func validate(_ state: LicenseState) async throws -> LicenseState {
        guard let licenseKey = state.licenseKey?.trimmingCharacters(in: .whitespacesAndNewlines), !licenseKey.isEmpty else {
            throw LicenseActivationError.invalidKey
        }

        var fields = ["license_key": licenseKey]
        if let instanceID = state.instanceID, !instanceID.isEmpty {
            fields["instance_id"] = instanceID
        }

        let response = try await perform(endpoint: "validate", fields: fields)
        guard response.valid == true else {
            throw LicenseActivationError.requestFailed(response.errorMessage ?? "Licence non valide.")
        }

        try validateExpectedProduct(response.meta)

        var next = state
        next.tier = .premium
        next.customerEmail = response.meta?.customerEmail ?? state.customerEmail
        next.productName = response.meta?.productName ?? state.productName
        next.validatedAt = Date()
        return next
    }

    func deactivate(_ state: LicenseState) async throws {
        guard let licenseKey = state.licenseKey?.trimmingCharacters(in: .whitespacesAndNewlines), !licenseKey.isEmpty else {
            throw LicenseActivationError.invalidKey
        }
        guard let instanceID = state.instanceID, !instanceID.isEmpty else {
            throw LicenseActivationError.missingInstance
        }

        let response = try await perform(
            endpoint: "deactivate",
            fields: [
                "license_key": licenseKey,
                "instance_id": instanceID
            ]
        )

        guard response.deactivated == true else {
            throw LicenseActivationError.requestFailed(response.errorMessage ?? "Désactivation impossible.")
        }
    }

    private func perform(endpoint: String, fields: [String: String]) async throws -> LicenseAPIResponse {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = formBody(fields)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let decoded = try? JSONDecoder().decode(LicenseAPIResponse.self, from: data)
            throw LicenseActivationError.requestFailed(decoded?.errorMessage ?? "Erreur serveur de licence.")
        }

        guard let decoded = try? JSONDecoder().decode(LicenseAPIResponse.self, from: data) else {
            throw LicenseActivationError.unexpectedResponse
        }

        return decoded
    }

    private func formBody(_ fields: [String: String]) -> Data? {
        let body = fields
            .map { key, value in
                "\(escape(key))=\(escape(value))"
            }
            .joined(separator: "&")

        return body.data(using: .utf8)
    }

    private func escape(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func validateExpectedProduct(_ meta: LicenseAPIResponse.Meta?) throws {
        if let expectedStoreID = LicenseProviderConfig.expectedStoreID, meta?.storeID != expectedStoreID {
            throw LicenseActivationError.unexpectedProduct
        }
        if let expectedProductID = LicenseProviderConfig.expectedProductID, meta?.productID != expectedProductID {
            throw LicenseActivationError.unexpectedProduct
        }
        if let expectedVariantID = LicenseProviderConfig.expectedVariantID, meta?.variantID != expectedVariantID {
            throw LicenseActivationError.unexpectedProduct
        }
    }

    private func validateExpectedEmail(_ expectedEmail: String?, responseEmail: String?) throws {
        let expected = expectedEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !expected.isEmpty else { return }

        let received = responseEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard received == expected else {
            throw LicenseActivationError.emailMismatch
        }
    }

    private static func defaultInstanceName() -> String {
        let hostName = Host.current().localizedName ?? "Mac"
        return "LampControl - \(hostName)"
    }
}

private struct LicenseAPIResponse: Decodable {
    let activated: Bool?
    let valid: Bool?
    let deactivated: Bool?
    let error: FlexibleString?
    let licenseKey: LicenseKey?
    let instance: Instance?
    let meta: Meta?

    var errorMessage: String? {
        error?.value
    }

    private enum CodingKeys: String, CodingKey {
        case activated
        case valid
        case deactivated
        case error
        case licenseKey = "license_key"
        case instance
        case meta
    }

    struct LicenseKey: Decodable {
        let status: String?
    }

    struct Instance: Decodable {
        let id: String?
        let name: String?
    }

    struct Meta: Decodable {
        let storeID: Int?
        let productID: Int?
        let variantID: Int?
        let productName: String?
        let customerEmail: String?

        private enum CodingKeys: String, CodingKey {
            case storeID = "store_id"
            case productID = "product_id"
            case variantID = "variant_id"
            case productName = "product_name"
            case customerEmail = "customer_email"
        }
    }
}

private struct FlexibleString: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = nil
        } else if let string = try? container.decode(String.self), !string.isEmpty {
            value = string
        } else if let bool = try? container.decode(Bool.self), bool {
            value = "Erreur de licence."
        } else {
            value = nil
        }
    }
}

private extension Bundle {
    func stringValue(forInfoDictionaryKey key: String) -> String? {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func integerValue(forInfoDictionaryKey key: String) -> Int? {
        if let value = object(forInfoDictionaryKey: key) as? Int, value > 0 {
            return value
        }

        guard let string = stringValue(forInfoDictionaryKey: key), let value = Int(string), value > 0 else {
            return nil
        }

        return value
    }
}
