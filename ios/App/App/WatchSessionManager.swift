import WatchConnectivity

/// Manages WCSession on the iPhone side — sends TV config to the paired Apple Watch.
final class WatchSessionManager: NSObject, WCSessionDelegate {

    static let shared = WatchSessionManager()

    private override init() {
        super.init()
    }

    /// Call once from AppDelegate.didFinishLaunching.
    func activate() {
        guard WCSession.isSupported() else {
            print("[WatchSession] WCSession NOT supported on this device")
            return
        }
        print("[WatchSession] Activating WCSession on iPhone...")
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Push the current TV config dictionary to the watch via applicationContext.
    /// applicationContext is delivered even if the watch app is not running — watchOS
    /// queues the latest value and delivers it on next launch.
    func sendConfig(_ config: [String: Any]) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated
        else {
            print("[WatchSession] Cannot send — session not activated")
            return
        }

        let session = WCSession.default
        print("[WatchSession] Sending config — paired: \(session.isPaired), watchAppInstalled: \(session.isWatchAppInstalled), reachable: \(session.isReachable)")

        do {
            try session.updateApplicationContext(config)
            print("[WatchSession] Sent applicationContext to watch: \(config["tvBrand"] ?? "?")")
        } catch {
            print("[WatchSession] updateApplicationContext failed: \(error)")
        }

        // Also try sendMessage for immediate delivery when watch is reachable
        if session.isReachable {
            session.sendMessage(config, replyHandler: { reply in
                print("[WatchSession] sendMessage reply: \(reply)")
            }, errorHandler: { error in
                print("[WatchSession] sendMessage error: \(error)")
            })
        }
    }

    // MARK: - WCSessionDelegate (required on iOS)

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("[WatchSession] iPhone activation: \(activationState.rawValue), paired: \(session.isPaired), watchAppInstalled: \(session.isWatchAppInstalled), error: \(String(describing: error))")

        // Send existing config to watch on activation (covers the case where
        // TV was configured before WatchConnectivity was added)
        if activationState == .activated {
            sendExistingConfigIfNeeded()
        }
    }

    /// Reads TV config from App Group UserDefaults and sends it to the watch.
    private func sendExistingConfigIfNeeded() {
        guard let defaults = UserDefaults(suiteName: "group.com.philips.remote"),
              let ip = defaults.string(forKey: "tvIp"),
              !ip.isEmpty
        else { return }

        let config: [String: Any] = [
            "tvIp": ip,
            "tvPort": defaults.integer(forKey: "tvPort"),
            "tvApiVersion": defaults.integer(forKey: "tvApiVersion"),
            "tvAuthUser": defaults.string(forKey: "tvAuthUser") ?? "",
            "tvAuthPass": defaults.string(forKey: "tvAuthPass") ?? "",
            "tvBrand": defaults.string(forKey: "tvBrand") ?? "philips",
            "tvToken": defaults.string(forKey: "tvToken") ?? "",
            "tvPsk": defaults.string(forKey: "tvPsk") ?? "",
        ]
        sendConfig(config)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after switching Apple Watches
        WCSession.default.activate()
    }
}
