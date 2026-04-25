import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject private var appState: AppState

    private let ink = LCTheme.ink
    private let muted = LCTheme.muted
    private let accent = LCTheme.accent

    var body: some View {
        ZStack {
            background

            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 16) {
                    content
                }
            } else {
                content
            }
        }
        .frame(width: appState.preferredPopoverSize.width, height: appState.preferredPopoverSize.height)
        .foregroundStyle(ink)
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.30, dampingFraction: 0.88), value: appState.preferredPopoverSize.height)
    }

    private var content: some View {
        VStack(spacing: 12) {
            header
            tabs

            if !appState.message.isEmpty {
                messageView
            }

            switch appState.selectedTab {
            case .lamps:
                LampsView()
            case .settings:
                SettingsView()
            }
        }
        .padding(16)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.95, blue: 0.96),
                    Color(red: 0.88, green: 0.89, blue: 0.91),
                    Color(red: 0.98, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.30))
                .frame(width: 210, height: 210)
                .offset(x: -150, y: -230)
                .blur(radius: 34)

            Circle()
                .fill(Color.black.opacity(0.08))
                .frame(width: 240, height: 240)
                .offset(x: 150, y: 205)
                .blur(radius: 40)

            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -130)
                .blur(radius: 34)

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.52)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(systemName: "lightbulb.led")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 42, height: 42)
            .liquidGlassSurface(radius: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text("LampControl")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink)
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.canSync ? Color.blue.opacity(0.70) : Color.gray.opacity(0.45))
                        .frame(width: 6, height: 6)
                    Text(appState.canSync ? "Cloud actif" : "Configuration requise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(muted)
                }
            }
            Spacer()

            Button(action: appState.quit) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(muted)
                    .frame(width: 34, height: 34)
                    .liquidGlassSurface(radius: 13, interactive: true)
            }
            .buttonStyle(.plain)
            .help("Quitter l'app")
        }
    }

    private var tabs: some View {
        HStack(spacing: 6) {
            tabButton(.lamps, title: "Lampes", icon: "slider.horizontal.3")
            tabButton(.settings, title: "Réglages", icon: "gearshape")
        }
        .padding(4)
        .liquidGlassSurface(radius: 18)
    }

    private func tabButton(_ tab: ControlTab, title: String, icon: String) -> some View {
        let isActive = appState.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                appState.selectedTab = tab
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : muted)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Capsule().fill(isActive ? accent.opacity(0.92) : Color.clear))
                .overlay {
                    if isActive {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.white.opacity(0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .shadow(color: isActive ? accent.opacity(0.20) : .clear, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var messageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
            Text(appState.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .liquidGlassSurface(radius: 15, tint: Color.blue.opacity(0.08))
    }
}

extension View {
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if let tint {
                if interactive {
                    self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: radius))
                } else {
                    self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: radius))
                }
            } else {
                if interactive {
                    self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: radius))
                } else {
                    self.glassEffect(.regular, in: .rect(cornerRadius: radius))
                }
            }
        } else {
            self.fallbackGlassSurface(radius: radius, tint: tint)
        }
    }

    @ViewBuilder
    func liquidGlassCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if let tint {
                if interactive {
                    self.glassEffect(.regular.tint(tint).interactive(), in: .circle)
                } else {
                    self.glassEffect(.regular.tint(tint), in: .circle)
                }
            } else {
                if interactive {
                    self.glassEffect(.regular.interactive(), in: .circle)
                } else {
                    self.glassEffect(.regular, in: .circle)
                }
            }
        } else {
            self.fallbackGlassSurface(radius: 999, tint: tint)
        }
    }

    private func fallbackGlassSurface(radius: CGFloat, tint: Color?) -> some View {
        self
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.58),
                        (tint ?? Color.white).opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.82), Color.white.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 12)
    }

    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(.plain)
        }
    }
}

enum LCTheme {
    static let ink = Color(red: 0.08, green: 0.085, blue: 0.095)
    static let muted = Color(red: 0.40, green: 0.41, blue: 0.44)
    static let accent = Color(red: 0.24, green: 0.25, blue: 0.28)
    static let softAccent = Color(red: 0.84, green: 0.85, blue: 0.88)
}
