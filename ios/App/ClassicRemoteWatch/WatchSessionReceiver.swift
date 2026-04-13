import WatchConnectivity
import Foundation

/// Manages WCSession on the watchOS side — receives TV config from the iPhone
/// and persists it to App Group UserDefaults (same store TvConfig.load() reads).
final class WatchSessionReceiver: NSObject, WCSessionDelegate, ObservableObject {

    static let shared = WatchSessionReceiver()

    /// Called on the main queue when new config arrives from the iPhone.
    var onConfigReceived: (() -> Void)?

    private override init() {
        super.init()
    }

    /// Call once from the watch app's init or onAppear.
    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if DEBUG
        print("[WatchSession] Watch activation: \(activationState.rawValue), error: \(String(describing: error))")
        #endif

        // On activation, check if there's a queued applicationContext from the phone
        if activationState == .activated {
            let ctx = session.receivedApplicationContext
            if !ctx.isEmpty {
                saveConfig(ctx)
            }
        }
    }

    /// Called when the iPhone sends updateApplicationContext.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WatchSession] didReceiveApplicationContext: \(applicationContext["tvBrand"] ?? "nil")")
        saveConfig(applicationContext)
    }

    /// Called when the iPhone sends sendMessage (immediate delivery).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("[WatchSession] didReceiveMessage: \(message["tvBrand"] ?? "nil")")
        saveConfig(message)
        replyHandler(["status": "ok"])
    }

    // MARK: - Private

    private func saveConfig(_ data: [String: Any]) {
        guard let ip = data["tvIp"] as? String,
              !ip.isEmpty,
              WatchSessionReceiver.isPrivateIPv4(ip)
        else {
            print("[WatchSession] Rejected config — missing or non-RFC-1918 IP")
            return
        }

        let defaults = UserDefaults(suiteName: "group.com.philips.remote") ?? .standard

        // Clear all TV keys first, then write what arrived — prevents stale values from previous TV
        let keys = ["tvIp", "tvPort", "tvApiVersion", "tvAuthUser", "tvAuthPass", "tvBrand", "tvToken", "tvPsk"]
        keys.forEach { defaults.removeObject(forKey: $0) }
        for key in keys {
            if let value = data[key] {
                defaults.set(value, forKey: key)
            }
        }

        #if DEBUG
        print("[WatchSession] Saved config from iPhone — brand: \(data["tvBrand"] ?? "?")")
        #endif

        DispatchQueue.main.async {
            self.onConfigReceived?()
        }
    }

    private static func isPrivateIPv4(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) else { return false }
        let prefixes = ["10.", "192.168.",
                        "172.16.", "172.17.", "172.18.", "172.19.", "172.20.", "172.21.",
                        "172.22.", "172.23.", "172.24.", "172.25.", "172.26.", "172.27.",
                        "172.28.", "172.29.", "172.30.", "172.31."]
        return prefixes.contains(where: { ip.hasPrefix($0) })
    }
}
