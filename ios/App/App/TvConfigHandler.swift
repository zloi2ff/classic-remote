import Foundation
import WebKit
import WidgetKit

/// WKScriptMessageHandler that receives TV config posted from JavaScript
/// and persists it to the App Group UserDefaults so the widget can read it.
///
/// JS usage:
///   window.webkit.messageHandlers.tvConfig.postMessage({
///       ip, port, apiVersion,
///       authUser, authPass,   // Philips Digest Auth
///       brand,                // "philips" | "lg" | "samsung" | "sony" | "tcl" | "xiaomi" | "hisense"
///       token,                // Samsung/LG session token
///       psk,                  // Sony Pre-Shared Key
///   })
final class TvConfigHandler: NSObject, WKScriptMessageHandler {

    private static let appGroupID = "group.com.philips.remote"

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            let body = message.body as? [String: Any],
            let ip   = body["ip"]   as? String,
            !ip.isEmpty,
            TvConfigHandler.isPrivateIPv4(ip)
        else {
            print("[TvConfigHandler] Received invalid or non-private IP: \(message.body)")
            return
        }

        let port       = (body["port"]       as? Int)    ?? 1925
        let apiVersion = (body["apiVersion"] as? Int)    ?? 1
        let authUser   = (body["authUser"]   as? String) ?? ""
        let authPass   = (body["authPass"]   as? String) ?? ""
        let brand      = (body["brand"]      as? String) ?? "philips"
        let token      = (body["token"]      as? String) ?? ""
        let psk        = (body["psk"]        as? String) ?? ""

        persist(ip: ip, port: port, apiVersion: apiVersion,
                authUser: authUser, authPass: authPass,
                brand: brand, token: token, psk: psk)
    }

    // MARK: - Private

    /// Accept only well-formed RFC-1918 private IPv4 addresses (mirrors server.py is_valid_tv_ip).
    /// Validates structural format (4 numeric octets) before prefix check.
    static func isPrivateIPv4(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) else { return false }
        let privateRanges = ["10.", "192.168.", "172.16.", "172.17.", "172.18.", "172.19.",
                             "172.20.", "172.21.", "172.22.", "172.23.", "172.24.", "172.25.",
                             "172.26.", "172.27.", "172.28.", "172.29.", "172.30.", "172.31."]
        return privateRanges.contains(where: { ip.hasPrefix($0) })
    }

    private func persist(ip: String, port: Int, apiVersion: Int,
                         authUser: String, authPass: String,
                         brand: String, token: String, psk: String) {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("[TvConfigHandler] Cannot open App Group UserDefaults — check entitlements.")
            return
        }

        defaults.set(ip,         forKey: "tvIp")
        defaults.set(port,       forKey: "tvPort")
        defaults.set(apiVersion, forKey: "tvApiVersion")
        defaults.set(authUser,   forKey: "tvAuthUser")
        defaults.set(authPass,   forKey: "tvAuthPass")
        defaults.set(brand,      forKey: "tvBrand")
        defaults.set(token,      forKey: "tvToken")
        defaults.set(psk,        forKey: "tvPsk")

        WidgetCenter.shared.reloadAllTimelines()

        // Send config to Apple Watch via WatchConnectivity
        WatchSessionManager.shared.sendConfig([
            "tvIp": ip,
            "tvPort": port,
            "tvApiVersion": apiVersion,
            "tvAuthUser": authUser,
            "tvAuthPass": authPass,
            "tvBrand": brand,
            "tvToken": token,
            "tvPsk": psk,
        ])

        #if DEBUG
        print("[TvConfigHandler] Saved config — ip:\(ip) port:\(port) apiVersion:\(apiVersion) brand:\(brand)")
        #endif
    }
}
