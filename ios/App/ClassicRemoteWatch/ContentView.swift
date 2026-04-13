import SwiftUI
import WatchKit

// MARK: - Design Tokens

private enum WatchDesign {
    static let volUpColor   = Color(red: 0.18, green: 0.72, blue: 0.45)
    static let volDownColor = Color(red: 0.18, green: 0.72, blue: 0.45)
    static let muteColor    = Color(red: 0.98, green: 0.62, blue: 0.11)
    static let powerColor   = Color(red: 0.86, green: 0.22, blue: 0.18)
    static let cornerRadius: CGFloat = 14

    // Gradient mesh — same palette as iOS app
    static let bgBase   = Color(red: 0.047, green: 0.043, blue: 0.078)
    static let bgPurple = Color(red: 0.345, green: 0.220, blue: 0.839)
    static let bgBlue   = Color(red: 0.000, green: 0.392, blue: 1.000)
    static let bgGreen  = Color(red: 0.157, green: 0.706, blue: 0.314)
    static let bgPink   = Color(red: 0.784, green: 0.235, blue: 0.706)
}

// MARK: - Liquid Glass Background

private struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            WatchDesign.bgBase
            RadialGradient(colors: [WatchDesign.bgPurple.opacity(0.65), .clear],
                           center: UnitPoint(x: 0.15, y: 0.18), startRadius: 0, endRadius: 90)
            RadialGradient(colors: [WatchDesign.bgBlue.opacity(0.50), .clear],
                           center: UnitPoint(x: 0.85, y: 0.62), startRadius: 0, endRadius: 90)
            RadialGradient(colors: [WatchDesign.bgGreen.opacity(0.32), .clear],
                           center: UnitPoint(x: 0.45, y: 0.90), startRadius: 0, endRadius: 75)
            RadialGradient(colors: [WatchDesign.bgPink.opacity(0.26), .clear],
                           center: UnitPoint(x: 0.72, y: 0.14), startRadius: 0, endRadius: 65)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Remote Button (Liquid Glass)

private struct RemoteButton: View {
    let icon: String
    let label: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: WatchDesign.cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay {
                    // Border
                    RoundedRectangle(cornerRadius: WatchDesign.cornerRadius)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                }
                .overlay {
                    // Specular highlight at top edge
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: WatchDesign.cornerRadius))
                }
        }
    }
}

// MARK: - Status Overlay

private struct StatusOverlay: View {
    let isSending: Bool
    let lastSuccess: Bool
    let lastError: String?

    var body: some View {
        Group {
            if isSending {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(0.8)
            } else if lastSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if let error = lastError {
                Text(error)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSending)
        .animation(.easeInOut(duration: 0.2), value: lastSuccess)
        .animation(.easeInOut(duration: 0.2), value: lastError)
    }
}

// MARK: - Not Configured View

private struct NotConfiguredView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tv.slash")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.secondary)
            Text("Open iPhone app\nto configure")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WebSocket Brand View

private struct WebSocketBrandView: View {
    let brandName: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.orange)
            Text("\(brandName)\nnot supported on Watch")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Use iPhone app")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var controller = TvController()

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            Group {
                if controller.config == nil {
                    NotConfiguredView()
                } else if let cfg = controller.config, cfg.isWebSocketOnly {
                    WebSocketBrandView(brandName: cfg.displayBrand)
                } else {
                    TabView {
                        remoteView
                            .tag(0)
                        navigationView
                            .tag(1)
                    }
                    .tabViewStyle(.page)
                    .toolbar(.hidden)
                    .persistentSystemOverlays(.hidden)
                }
            }
        }
        .onAppear {
            controller.reload()
            WatchSessionReceiver.shared.onConfigReceived = { [weak controller] in
                controller?.reload()
            }
        }
    }

    // MARK: Remote Grid

    private var remoteView: some View {
        GeometryReader { geo in
            let cell = (min(geo.size.width, geo.size.height) - 6) / 2
            ZStack(alignment: .top) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        RemoteButton(icon: "speaker.plus.fill",  label: "VOL +", accentColor: WatchDesign.volUpColor)   { controller.send("VolumeUp") }
                            .frame(width: cell, height: cell)
                        RemoteButton(icon: "speaker.minus.fill", label: "VOL -", accentColor: WatchDesign.volDownColor) { controller.send("VolumeDown") }
                            .frame(width: cell, height: cell)
                    }
                    HStack(spacing: 6) {
                        RemoteButton(icon: "speaker.slash.fill", label: "MUTE",  accentColor: WatchDesign.muteColor)  { controller.send("Mute") }
                            .frame(width: cell, height: cell)
                        RemoteButton(icon: "power",              label: "POWER", accentColor: WatchDesign.powerColor) { controller.send("Standby") }
                            .frame(width: cell, height: cell)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                StatusOverlay(
                    isSending: controller.isSending,
                    lastSuccess: controller.lastSuccess,
                    lastError: controller.lastError
                )
                .frame(height: 16)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    // MARK: Navigation Pad

    private var navigationView: some View {
        GeometryReader { geo in
            let cell = (geo.size.width - 14) / 3

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Color.clear.frame(width: cell, height: cell)
                    RemoteButton(icon: "chevron.up", label: "UP", accentColor: Color.white.opacity(0.7)) {
                        controller.send("Up")
                    }
                    .frame(width: cell, height: cell)
                    Color.clear.frame(width: cell, height: cell)
                }

                HStack(spacing: 6) {
                    RemoteButton(icon: "chevron.left", label: "LEFT", accentColor: Color.white.opacity(0.7)) {
                        controller.send("Left")
                    }
                    .frame(width: cell, height: cell)

                    RemoteButton(icon: "checkmark", label: "OK", accentColor: Color.blue) {
                        controller.send("Ok")
                    }
                    .frame(width: cell, height: cell)

                    RemoteButton(icon: "chevron.right", label: "RIGHT", accentColor: Color.white.opacity(0.7)) {
                        controller.send("Right")
                    }
                    .frame(width: cell, height: cell)
                }

                HStack(spacing: 6) {
                    Color.clear.frame(width: cell, height: cell)
                    RemoteButton(icon: "chevron.down", label: "DOWN", accentColor: Color.white.opacity(0.7)) {
                        controller.send("Down")
                    }
                    .frame(width: cell, height: cell)
                    Color.clear.frame(width: cell, height: cell)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}

// MARK: - Previews

#Preview("Configured — Philips") {
    ContentView()
}

#Preview("Not Configured") {
    ZStack {
        LiquidGlassBackground()
        NotConfiguredView()
    }
}

#Preview("Samsung (unsupported)") {
    ZStack {
        LiquidGlassBackground()
        WebSocketBrandView(brandName: "Samsung")
    }
}
