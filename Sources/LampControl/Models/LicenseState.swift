import Foundation

enum LicenseTier: String, Codable {
    case free
    case earlyAccess
    case premium

    var title: String {
        switch self {
        case .free: "Gratuit"
        case .earlyAccess: "Early Access"
        case .premium: "Premium"
        }
    }
}

enum LicenseProvider: String, Codable {
    case lemonSqueezy

    var title: String {
        switch self {
        case .lemonSqueezy: "Lemon Squeezy"
        }
    }
}

struct LicenseEntitlements: Codable, Equatable {
    var maxLamps: Int?
    var canUseGroups: Bool
    var canUseCustomScenes: Bool
    var canUseScenePresets: Bool
    var canUseProfiles: Bool
    var canUseAutomations: Bool
    var canUseAdaptiveLighting: Bool

    static let free = LicenseEntitlements(
        maxLamps: 2,
        canUseGroups: false,
        canUseCustomScenes: false,
        canUseScenePresets: true,
        canUseProfiles: false,
        canUseAutomations: false,
        canUseAdaptiveLighting: false
    )

    static let premium = LicenseEntitlements(
        maxLamps: nil,
        canUseGroups: true,
        canUseCustomScenes: true,
        canUseScenePresets: true,
        canUseProfiles: true,
        canUseAutomations: true,
        canUseAdaptiveLighting: true
    )
}

struct LicenseState: Codable, Equatable {
    var tier: LicenseTier
    var provider: LicenseProvider
    var licenseKey: String?
    var instanceID: String?
    var instanceName: String?
    var customerEmail: String?
    var productName: String?
    var activatedAt: Date?
    var validatedAt: Date?

    init(
        tier: LicenseTier,
        provider: LicenseProvider,
        licenseKey: String?,
        instanceID: String?,
        instanceName: String?,
        customerEmail: String?,
        productName: String?,
        activatedAt: Date?,
        validatedAt: Date?
    ) {
        self.tier = tier
        self.provider = provider
        self.licenseKey = licenseKey
        self.instanceID = instanceID
        self.instanceName = instanceName
        self.customerEmail = customerEmail
        self.productName = productName
        self.activatedAt = activatedAt
        self.validatedAt = validatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tier = try container.decodeIfPresent(LicenseTier.self, forKey: .tier) ?? .earlyAccess
        provider = try container.decodeIfPresent(LicenseProvider.self, forKey: .provider) ?? .lemonSqueezy
        licenseKey = try container.decodeIfPresent(String.self, forKey: .licenseKey)
        instanceID = try container.decodeIfPresent(String.self, forKey: .instanceID)
        instanceName = try container.decodeIfPresent(String.self, forKey: .instanceName)
        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        activatedAt = try container.decodeIfPresent(Date.self, forKey: .activatedAt)
        validatedAt = try container.decodeIfPresent(Date.self, forKey: .validatedAt)
    }

    static let earlyAccess = LicenseState(
        tier: .earlyAccess,
        provider: .lemonSqueezy,
        licenseKey: nil,
        instanceID: nil,
        instanceName: nil,
        customerEmail: nil,
        productName: nil,
        activatedAt: Date(),
        validatedAt: nil
    )

    static let free = LicenseState(
        tier: .free,
        provider: .lemonSqueezy,
        licenseKey: nil,
        instanceID: nil,
        instanceName: nil,
        customerEmail: nil,
        productName: nil,
        activatedAt: nil,
        validatedAt: nil
    )

    var isPremiumEnabled: Bool {
        tier == .earlyAccess || tier == .premium
    }

    var entitlements: LicenseEntitlements {
        isPremiumEnabled ? .premium : .free
    }

    var statusText: String {
        switch tier {
        case .free:
            "Fonctionnalités de base"
        case .earlyAccess:
            "Premium actif pendant la bêta"
        case .premium:
            "Licence active"
        }
    }

    var maskedLicenseKey: String {
        guard let licenseKey, licenseKey.count > 8 else { return "Non connectée" }
        return "\(licenseKey.prefix(4))...\(licenseKey.suffix(4))"
    }
}
