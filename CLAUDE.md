# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Philips TV Remote — web-based remote control for Philips Smart TV (JointSpace API v1/v5/v6, port 1925). Runs as a Python proxy server with a single-page web UI, also packaged as a standalone native iOS app via Capacitor 8.

## Architecture

```
server.py                              ← Python proxy: serves www/, proxies /api/* to TV
www/index.html                         ← Single-file web UI (HTML + CSS + JS inline), 1700+ lines
ios/App/App/AppDelegate.swift          ← Registers WKScriptMessageHandler for tvConfig bridge
ios/App/App/TvConfigHandler.swift      ← Saves tvIp/tvPort/tvApiVersion to App Group UserDefaults
ios/App/App/TvConfigPlugin.swift       ← Capacitor plugin stub (secondary approach, not primary)
ios/App/PhilipsWidgetExtension/        ← WidgetKit extension (iOS 17+)
  PhilipsWidget.swift                  ← Widget UI + timeline provider
  TvControlIntent.swift                ← 4 AppIntents: VolumeUp/Down, Mute, Standby
capacitor.config.json
RELEASE_CHECKLIST.md                   ← Step-by-step App Store release instructions
```

**Dual-mode frontend:** The same `www/index.html` runs in two contexts:
- **Browser** (via `server.py`): `IS_CAPACITOR=false` → relative URLs `/api/1/input/key` → proxy → TV
- **iOS/Capacitor** (`capacitor://localhost`): `IS_CAPACITOR=true` → direct URLs `http://{tvIp}:1925/1/input/key` → TV

**Key server endpoints:**
- `GET /discover` — scans local /24 subnet, 254 concurrent threads, rate-limited with `_discover_lock`
- `GET/POST /config` — runtime TV IP/port/apiVersion (mutable `tv_config` dict); IP validated against RFC-1918 ranges to prevent SSRF
- `/api/*` — transparent proxy; strips `/api` prefix, uses HTTPS for API v6+

**iOS direct mode** (no server needed):
- TV discovery: `getLocalIpViaWebRTC()` → `scanSubnetDirect()`, fallback to `scanCommonSubnets()` (sequential, stops on first found)
- **AbortController is required** for scan timeouts — `CapacitorHttp` passes `signal` to WKWebView for GET requests. `Promise.race` without signal does NOT cancel connections and causes URLSession pool exhaustion (762 zombie connections → TV not found).
- CORS bypass: `CapacitorHttp.enabled: true` in `capacitor.config.json` patches `fetch()` through native Swift `URLSession`
- TV config stored in `localStorage`: keys `tvIp`, `tvPort`, `tvApiVersion`

**App Group data flow (widget):**
1. JS `saveConfig()` calls `window.webkit.messageHandlers.tvConfig.postMessage({ip, port, apiVersion})`
2. `TvConfigHandler.swift` writes to `UserDefaults(suiteName: "group.com.philips.remote")`
3. `WidgetCenter.shared.reloadAllTimelines()` triggers widget refresh
4. `PhilipsProvider.makeEntry()` reads from same App Group UserDefaults

**JointSpace API versions:** `probeTvDirect()` tries v1 HTTP → v6 HTTPS → v5 HTTP in order. v6 uses HTTPS with self-signed certs (verification disabled intentionally).

## Commands

```bash
# Run server (stdlib only, no pip install)
python3 server.py
TV_IP=192.168.1.100 SERVER_PORT=9000 python3 server.py

# iOS — sync and build to connected device
npx cap sync ios
xcodebuild -project ios/App/App.xcodeproj -scheme App -configuration Debug \
  -destination 'id=<DEVICE_UDID>' -allowProvisioningUpdates build

# Find connected device UDID
xcrun devicectl list devices

# Install and launch on device
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/App-*/Build/Products/Debug-iphoneos -name "App.app" -maxdepth 1 | head -1)
xcrun devicectl device install app --device <DEVICE_UDID> "$APP_PATH"
xcrun devicectl device process launch --device <DEVICE_UDID> com.philips.remote

# Deploy to production server
scp server.py zloi2ff@192.168.31.73:/home/zloi2ff/philips-remote/
scp www/index.html zloi2ff@192.168.31.73:/home/zloi2ff/philips-remote/www/
ssh zloi2ff@192.168.31.73 "sudo systemctl restart philips-remote"
```

## Key Design Decisions

- **Zero Python dependencies** — `server.py` uses only stdlib. No pip install.
- **Single HTML file** — all CSS/JS inline in `www/index.html`. No build step, no bundler.
- **`ThreadingHTTPServer`** — critical: TV API calls have 5s timeout; blocking would freeze all clients.
- **`selectTvByIndex(i, el, context)`** — TV list items use index into `_discoveredTvs{}` map instead of inline JSON args to avoid HTML attribute quote-escaping bugs.
- **`IS_CAPACITOR` flag** — `window.location.protocol === 'capacitor:'` — gates all iOS-specific paths.
- **Optional `API_TOKEN`** — env var for shared-secret auth on `/api/*`, `/config`, `/discover`; checked via `hmac.compare_digest`. Absent = open access.
- **Widget AppIntents** — `TvButtonView<Intent: AppIntent>` must stay generic (not `any AppIntent` array) to avoid `AppIntentsSSUTraining` build failures. Top-level functions also break SSUTraining — keep all helpers inside `enum` namespaces.
- **`applicationDidBecomeActive`** — WKScriptMessageHandler is registered here (not `didFinishLaunching`) because `CAPBridgeViewController.webView` is only available after Capacitor finishes loading.

## WidgetKit Notes

- Widget entitlements: `ios/App/App/App.entitlements` (main app) and `ios/App/PhilipsWidgetExtension/PhilipsWidgetExtension.entitlements` — both must have `group.com.philips.remote`
- `CODE_SIGN_ENTITLEMENTS` must be set in all 4 build configurations in `project.pbxproj`
- Widget design: iOS 26+ uses `.glassEffect()` on `RoundedRectangle` inside `.background {}` — NOT on the `Button` itself (makes button invisible). Pre-iOS 26 uses dark gradient fallback.

## Monetization (iOS)

- **Free**: AdMob banner (`@capacitor-community/admob`)
- **Pro**: RevenueCat IAP (`@revenuecat/purchases-capacitor`) — entitlement `pro`, product `remove_ads`
- Config object `MONETIZATION` in `www/index.html` has all placeholder IDs
- Currently using **Google test AdMob IDs** — replace before App Store. See `RELEASE_CHECKLIST.md`.

## Deployment

Production server: `zloi2ff@192.168.31.73` (Wyse 5070, Ubuntu), systemd service `philips-remote`, port 8888. SSH key auth. UFW must allow port 8888.

## Language

User communication: Ukrainian. Code, variables, commits: English.
