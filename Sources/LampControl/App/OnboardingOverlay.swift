import SwiftUI

struct OnboardingOverlay: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            LCTheme.overlayScrim
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        appState.dismissOnboarding()
                    }
                }

            VStack(alignment: .leading, spacing: 14) {
                header
                steps
                actions
            }
            .padding(16)
            .frame(maxWidth: 380)
            .liquidGlassSurface(radius: 24, tint: Color.white.opacity(0.08))

            Button("onboarding.close") { appState.dismissOnboarding() }
                .keyboardShortcut(.escape, modifiers: [])
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LCTheme.accent)
                .frame(width: 42, height: 42)
                .liquidGlassSurface(radius: 15, tint: Color.blue.opacity(0.10))

            VStack(alignment: .leading, spacing: 2) {
                Text("onboarding.title")
                    .font(.system(size: 17, weight: .semibold))
                Text("onboarding.subtitle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LCTheme.muted)
            }

            Spacer()
        }
    }

    private var steps: some View {
        VStack(spacing: 8) {
            OnboardingStepRow(
                number: "1",
                titleKey: "onboarding.step1.title",
                detailKey: "onboarding.step1.detail"
            )
            OnboardingStepRow(
                number: "2",
                titleKey: "onboarding.step2.title",
                detailKey: "onboarding.step2.detail"
            )
            OnboardingStepRow(
                number: "3",
                titleKey: "onboarding.step3.title",
                detailKey: "onboarding.step3.detail"
            )
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button {
                appState.openOnboardingSettings()
            } label: {
                Label("onboarding.configure", systemImage: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .liquidGlassButtonStyle(prominent: true)

            Button {
                appState.openConfigurationGuide()
            } label: {
                Image(systemName: "book")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LCTheme.accent)
                    .frame(width: 38, height: 38)
            }
            .liquidGlassButtonStyle()
            .help("onboarding.guide")

            Button {
                appState.dismissOnboarding()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LCTheme.muted)
                    .frame(width: 38, height: 38)
            }
            .liquidGlassButtonStyle()
            .help("onboarding.dismiss")
        }
    }
}

private struct OnboardingStepRow: View {
    let number: String
    let titleKey: LocalizedStringKey
    let detailKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(LCTheme.accent)
                .frame(width: 26, height: 26)
                .background(LCTheme.accent.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(titleKey)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LCTheme.ink)
                Text(detailKey)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(LCTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .liquidGlassSurface(radius: 14)
    }
}
