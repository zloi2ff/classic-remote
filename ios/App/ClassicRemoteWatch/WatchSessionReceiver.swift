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
        let defaults = UserDefaults.standard

        // Write each key individually (matches TvConfigHandler.persist() keys)
        let keys = ["tvIp", "tvPort", "tvApiVersion", "tvAuthUser", "tvAuthPass", "tvBrand", "tvToken", "tvPsk"]
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
}
