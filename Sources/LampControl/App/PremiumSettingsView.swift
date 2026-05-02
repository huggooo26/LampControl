import SwiftUI

struct PremiumSettingsView: View {
    @EnvironmentObject private var appState: AppState
    let licenseState: LicenseState
    @State private var licenseKey = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                header
                infoRow("premium.lamps",
                        value: licenseState.entitlements.maxLamps.map { "\($0) max" } ?? NSLocalizedString("premium.lamps.unlimited", comment: ""),
                        icon: "lightbulb.2")
                premiumFeatureRow("premium.groups",        isEnabled: licenseState.entitlements.canUseGroups)
                premiumFeatureRow("premium.custom.scenes", isEnabled: licenseState.entitlements.canUseCustomScenes)
                premiumFeatureRow("premium.quick.ambiances", isEnabled: licenseState.entitlements.canUseScenePresets)
            }
            .padding(14)
            .liquidGlassSurface(radius: 22)

            activationCard

            earlyAccessNote
        }
        .onAppear {
            licenseKey = licenseState.licenseKey ?? ""
            email = licenseState.customerEmail ?? ""
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.yellow)
                .frame(width: 34, height: 34)
                .liquidGlassSurface(radius: 12, tint: Color.yellow.opacity(0.12))

            VStack(alignment: .leading, spacing: 2) {
                Text(licenseState.tier.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(licenseState.statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LCTheme.muted)
            }

            Spacer()
        }
    }

    private var activationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("premium.activation")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Text(LicenseProviderConfig.providerName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LCTheme.muted)
            }

            VStack(alignment: .leading, spacing: 7) {
                TextField("premium.license.key", text: $licenseKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06))

                TextField("premium.email", text: $email)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .liquidGlassSurface(radius: 12, tint: Color.white.opacity(0.06))

                if let instanceName = licenseState.instanceName {
                    Text(instanceName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LCTheme.muted)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                Button {
                    Task { await appState.activateLicense(licenseKey, email: email) }
                } label: {
                    Label(licenseState.tier == .premium ? "premium.reactivate" : "premium.activate",
                          systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .disabled(appState.isBusy || licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .liquidGlassButtonStyle(prominent: true)

                if licenseState.tier == .premium {
                    Button {
                        Task { await appState.validateLicense() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(appState.isBusy)
                    .liquidGlassButtonStyle()

                    Button {
                        Task { await appState.deactivateLicense() }
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(appState.isBusy)
                    .liquidGlassButtonStyle()
                }
            }

            Button {
                appState.openPremiumCheckout()
            } label: {
                Label("premium.buy", systemImage: "cart.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
            .liquidGlassButtonStyle()
        }
        .padding(14)
        .liquidGlassSurface(radius: 22)
    }

    private var earlyAccessNote: some View {
        Text("premium.early.access.note")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(LCTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func infoRow(_ titleKey: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LCTheme.accent)
                .frame(width: 28, height: 28)
                .liquidGlassSurface(radius: 10)

            Text(titleKey)
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LCTheme.muted)
                .lineLimit(1)
        }
    }

    private func premiumFeatureRow(_ titleKey: LocalizedStringKey, isEnabled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isEnabled ? "checkmark.seal.fill" : "lock.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.green : LCTheme.muted)
                .frame(width: 28, height: 28)
                .liquidGlassSurface(radius: 10, tint: isEnabled ? Color.green.opacity(0.08) : nil)

            Text(titleKey)
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            Text(isEnabled ? "premium.active" : "premium.locked")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LCTheme.muted)
        }
    }
}
