# Multi-Brand TV Remote — Design Spec

**Date:** 2026-03-21
**Platform:** iOS only (Capacitor direct mode)
**Brands:** Philips, LG, Samsung, Sony, TCL, Xiaomi, Hisense

## 1. Architecture: TvDriver Abstraction

Single-file architecture preserved (`www/index.html`). Each brand is a driver object implementing a common interface.

```javascript
// Interface every driver must implement:
{
  name: String,           // "LG"
  brandId: String,        // "lg"

  // Discovery
  discover(subnet): [{ip, port, name, model, brandId}],
  probe(ip): {ip, port, name, model, apiVersion} | null,

  // Connection & auth
  connect(tv): Boolean,
  needsPairing(): Boolean,
  pair(pin): Boolean,
  disconnect(): void,

  // Control
  sendKey(universalKey): void,
  getVolume(): Number | null,
  setVolume(level): void,

  // Key mapping
  keyMap: { universalKey -> protocolKey },
  extraButtons: [{ label, key, icon }],

  // Widget config
  getWidgetConfig(): { brand, ip, port, ... },
}
```

Active driver: `localStorage.tvBrand` → `TvDrivers[brand]`.
All existing functions (`sendKey`, `getVolume`, `setVolume`, `startDiscovery`) delegate to `currentDriver`.

## 2. Protocols per Brand

### Philips — JointSpace API (existing)
- HTTP REST, ports 1925/1926, API v1/v5/v6
- v6: HTTPS + Digest Auth + PIN pairing
- Discovery: HTTP probe `/system` endpoint

### LG — WebOS SSAP (WebSocket)
- `ws://TV_IP:3000` → handshake → send JSON commands
- Pairing: TV shows prompt, user accepts on TV (no PIN)
- Client token stored after first pairing, reused for reconnect
- Key send: `{"type":"request","uri":"ssap://com.webos.service.networkinput/getPointerInputSocket"}` → separate WebSocket for keys
- Volume: `ssap://audio/getVolume`, `ssap://audio/setVolume`
- Discovery: SSDP `urn:lge-com:service:webOSSecondScreen:1` or HTTP probe port 3000

### Samsung — Tizen WebSocket
- `wss://TV_IP:8002/api/v2/channels/samsung.remote.control?name=BASE64_APP_NAME`
- First connect: TV shows "Allow" prompt, returns token
- Token stored, sent in subsequent connections via URL param `&token=XXX`
- Key send: `{"method":"ms.remote.control","params":{"Cmd":"Click","DataOfCmd":"KEY_VOLUP","Option":"false","TypeOfRemote":"SendRemoteKey"}}`
- Volume: no direct GET API — send KEY_VOLUP/KEY_VOLDOWN
- Discovery: SSDP `urn:samsung.com:device:RemoteControlReceiver:1` or HTTP `http://IP:8001/api/v2/`

### Sony — Bravia REST API
- HTTP REST on port 80, JSON-RPC
- Auth: PSK (Pre-Shared Key) header or PIN pairing via `/accessControl`
- Key send: POST `/IRCC` with SOAP XML (IRCC code)
- Volume: JSON-RPC `system` service → `getVolumeInformation` / `setAudioVolume`
- Discovery: SSDP `urn:schemas-sony-com:service:IRCC:1` or HTTP probe

### TCL — Roku API (for Roku-based TCL TVs)
- HTTP REST on port 8060, no auth
- Key send: POST `/keypress/{key}` (e.g., `/keypress/VolumeUp`)
- Volume: no direct API — send keypress
- Discovery: SSDP `roku:ecp` or HTTP probe port 8060 `/query/device-info`
- Note: Android TV-based TCL uses same protocol as Xiaomi

### Xiaomi — Android TV Remote Protocol
- Google's Android TV Remote protocol (protobuf over TLS, port 6466)
- Too complex for pure JS — fallback to basic HTTP endpoints if available
- Practical approach: use Google Cast protocol (port 8008/8443) for basic discovery + external input simulation
- Discovery: mDNS `_androidtvremote2._tcp` or HTTP probe
- Limited control: Power, Volume (via CEC), basic nav

### Hisense — VIDAA / Roku
- VIDAA models: MQTT protocol on port 36669 (complex)
- Roku-based models: same as TCL Roku API (port 8060)
- Practical approach: detect Roku first (port 8060), fallback to VIDAA MQTT if available
- Discovery: HTTP probe port 8060 (Roku) or port 36669 (VIDAA)

## 3. First Launch Flow

```
App opens
  ↓
loadConfig() → no tvBrand/tvIp
  ↓
Show Brand Selection Screen (#brandSelectScreen)
  - Grid of brand logos/icons
  - "Scan All" button at top
  ↓
Option A: User taps "Scan All"
  → scanAllBrands(subnet) — parallel probe all protocols
  → Show results with brand icons
  → User taps TV → saveConfig(brand, tv) → main remote
  ↓
Option B: User taps specific brand
  → TvDrivers[brand].discover(subnet)
  → Show results for that brand
  → If none found → manual IP input
  → User taps TV → saveConfig(brand, tv) → main remote
  ↓
Option C: Nothing found / user taps "Manual"
  → Brand selector + IP input
  → probe specific brand+IP
  → saveConfig(brand, tv) → main remote
```

## 4. Remote UI Changes

### Universal buttons (all brands):
- Power, Volume+/-, Mute, Channel+/-
- D-pad (Up/Down/Left/Right/OK)
- Home, Back, Source/Input
- Play/Pause/Stop/Rewind/FastForward
- Color buttons (Red/Green/Yellow/Blue)
- Number pad (0-9)

### Brand-specific extra buttons:
- **Philips:** Ambilight, Options, Adjust
- **LG:** Magic Remote pointer mode (if feasible), Screen Share, LG Channels
- **Samsung:** Bixby, Ambient Mode, Smart Hub
- **Sony:** Google Assistant, Action Menu, Netflix direct
- **TCL:** Roku Home, Star (*), Instant Replay
- **Xiaomi:** Mi Home, Google Assistant, PatchWall
- **Hisense:** VIDAA Hub, Netflix direct, Prime Video direct

Extra buttons rendered dynamically from `currentDriver.extraButtons`.

## 5. Universal Key Map

| Universal Key | Philips | LG | Samsung | Sony | TCL (Roku) |
|---|---|---|---|---|---|
| Power | Standby | power | KEY_POWER | PowerOff | Power |
| VolumeUp | VolumeUp | volumeUp | KEY_VOLUP | VolumeUp | VolumeUp |
| VolumeDown | VolumeDown | volumeDown | KEY_VOLDOWN | VolumeDown | VolumeDown |
| Mute | Mute | mute | KEY_MUTE | Mute | VolumeMute |
| Up | CursorUp | UP | KEY_UP | Up | Up |
| Down | CursorDown | DOWN | KEY_DOWN | Down | Down |
| Left | CursorLeft | LEFT | KEY_LEFT | Left | Left |
| Right | CursorRight | RIGHT | KEY_RIGHT | Right | Right |
| OK | Confirm | ENTER | KEY_ENTER | Confirm | Select |
| Home | Home | HOME | KEY_HOME | Home | Home |
| Back | Back | BACK | KEY_RETURN | Return | Back |
| Play | Play | play | KEY_PLAY | Play | Play |
| Pause | Pause | pause | KEY_PAUSE | Pause | Pause |

## 6. Storage Changes

### localStorage additions:
- `tvBrand` — brand identifier ("philips", "lg", "samsung", etc.)
- `tvToken_{ip}` — auth token (Samsung token, LG client key)
- `tvPsk_{ip}` — Pre-Shared Key (Sony)

### App Group UserDefaults additions:
- `tvBrand` — for widget to know which protocol to use
- `tvToken` — auth token if needed
- `tvPsk` — Sony PSK

## 7. Widget Changes

### TvControlIntent.swift:
- `TvConfig` gains `brand` field
- `TvSender.sendKey()` branches on brand:
  - Philips: existing HTTP POST (JointSpace)
  - LG: WebSocket → too complex for widget extension → HTTP fallback via Luna API
  - Samsung: WebSocket → same issue → use wake-on-LAN for power only
  - Sony: HTTP POST (IRCC) — works well in widget
  - TCL/Roku: HTTP POST — works well in widget
  - Xiaomi/Hisense: limited widget support

### Practical widget support:
- **Full widget support:** Philips, Sony, TCL (Roku) — HTTP-based, simple
- **Partial widget support:** Samsung (power via WoL), LG (limited HTTP endpoints)
- **No widget support:** Xiaomi (needs persistent connection)

## 8. Discovery Architecture

```javascript
async function scanAllBrands(subnets) {
  const allTvs = [];

  // Parallel scan all brands across all subnets
  const promises = subnets.flatMap(subnet =>
    Object.values(TvDrivers).map(driver =>
      driver.discover(subnet)
        .then(tvs => allTvs.push(...tvs))
        .catch(() => {}) // brand not found on this subnet
    )
  );

  await Promise.allSettled(promises);
  return allTvs;
}
```

Each driver's `discover()` probes brand-specific ports/endpoints with AbortController timeouts.

## 9. File Changes Summary

| File | Changes |
|---|---|
| `www/index.html` | TvDriver objects, brand select screen, universal key mapping, dynamic extra buttons, multi-protocol discovery |
| `ios/App/App/TvConfigHandler.swift` | Add `tvBrand`, `tvToken`, `tvPsk` to App Group |
| `ios/App/PhilipsWidgetExtension/TvControlIntent.swift` | Multi-brand TvSender with HTTP-based protocols |
| `ios/App/PhilipsWidgetExtension/PhilipsWidget.swift` | Show brand icon, rename to TvWidget |
| `capacitor.config.json` | No changes needed |

## 10. Constraints & Limitations

1. **WebSocket in widget:** iOS widget extensions cannot maintain WebSocket connections → LG/Samsung widget support is limited to HTTP-only operations
2. **Xiaomi Android TV Remote:** Requires protobuf + TLS certificate exchange → implement basic Cast/CEC control only
3. **Hisense VIDAA MQTT:** Complex protocol, implement Roku fallback first
4. **Samsung HTTPS:** Self-signed cert on port 8002 → need SSL bypass (already have pattern from Philips v6)
5. **AbortController:** Must use for all discovery probes (existing pattern)
6. **Single HTML file:** All driver code inline — file will grow to ~4500-5500 lines
