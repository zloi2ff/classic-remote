# Philips TV Remote

Web-based remote control for Philips Smart TV (JointSpace API v1/v5/v6). Available as web app and native iOS app with Home Screen widget.

**English** | [Українська](README.uk.md)

<p align="center">
  <img src="screenshot-collapsed.png" width="280" alt="Collapsed">
  <img src="screenshot-expanded.png" width="280" alt="Expanded">
</p>

![Version](https://img.shields.io/badge/version-1.1-blue)
![Remote](https://img.shields.io/badge/TV-Philips%206158-blue)
![Python](https://img.shields.io/badge/Python-3.x-green)
![Capacitor](https://img.shields.io/badge/Capacitor-8.x-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Supported TVs

The app uses the JointSpace API (port 1925) and auto-detects the API version. The app tries v1 → v6 → v5 on connection.

> **To activate JointSpace on 2011–2015 TVs:** open the TV menu and enter code `5646877223` on the remote.

### API v1 — HTTP, no authentication (2009–2015)

All non-Android Philips TVs from 2009 to 2015. No pairing required.

| Year | Model pattern | Example |
|------|--------------|---------|
| 2009 | xxPFL8xxx, xxPFL9xxx | 42PFL8684H/12 |
| 2010 | xxPFL7xxx, xxPFL8xxx, xxPFL9xxx | 46PFL8605H/12 |
| 2011 | xxPFL5**6**xx–xxPFL9**6**xx | 42PFL6158K/12 |
| 2012 | xxPFL5**7**xx–xxPFL8**7**xx | 47PFL6678S/12 |
| 2013 | xxPFL5**8**xx–xxPFL8**8**xx _(non-Android)_ | 55PFL6678S/12 |
| 2014 | xxPFL5**9**xx, xxPUS6**9**xx _(non-Android)_ | 42PUS6809/12 |
| 2015 | xxPFL5**0**xx, xxPUS6**0**xx _(non-Android)_ | 43PUS6031/12 |

The last digit of the 4-digit series number encodes the year (6=2011, 7=2012, 8=2013, 9=2014, 0=2015).

### API v5 — HTTP, no authentication (2014–2015)

Transitional generation. Same protocol as v1, superset of commands. Many v5 TVs also respond on `/1/`.

| Year | Model pattern |
|------|--------------|
| 2014–2015 | xxPUS6**9**xx, xxPUS7**9**xx, xxPUS6**0**xx, xxPUS7**0**xx _(non-Android / Saphi OS)_ |

### API v6 — HTTPS, PIN pairing required (2016–present)

#### Saphi OS (non-Android) — port 1925, HTTPS

Budget and mid-range TVs from 2016+ running Philips' own Saphi Linux OS.

| Year | Model pattern | Example |
|------|--------------|---------|
| 2016 | xxPUS6**1**xx, xxPFT5**1**xx | 43PUS6162/12 |
| 2017 | xxPUS6**2**xx | 65PUS6162/12 |
| 2018 | xxPUS6**3**xx | 43PUS6753/12 |
| 2019+ | xxPUS6**4**xx and lower-end PUS7xxx | — |

#### Android TV — port 1926, HTTPS

Mid-to-high range TVs from 2016+ running Android TV OS. Basic commands (volume, standby, navigation) work. Full control requires port 1926 + digest auth pairing.

| Year | Model pattern | Example |
|------|--------------|---------|
| 2016 | xxPUS7**1**xx, xxPUS8**1**xx | 49PUS7101/12 |
| 2017 | xxPUS7**2**xx, OLEDxx**2** | 55PUS7502/12 |
| 2018 | xxPUS7**3**xx, xxPUS8**3**xx | 58PUS7304/12 |
| 2019 | xxPUS7**4**xx, OLEDxx**4** | 55OLED804/12 |
| 2020+ | xxPUS7**5**xx and newer | — |

> All OLED models (OLED803, OLED804, etc.) are Android TV and use API v6 on port 1926.

## Features

- Auto-discovery of Philips TVs on local network
- Manual TV IP configuration
- Power on/off
- Navigation (arrows, OK, Back, Home)
- Volume control (+/-, mute, slider)
- Channel switching (+/-)
- Color buttons (red, green, yellow, blue)
- Playback controls (play, pause, stop, rewind, forward)
- Quick source switching (TV, HDMI, Blu-ray, etc.)
- Visual button feedback with haptic (iOS)
- PWA support (add to home screen on iOS/Android)
- Native iOS app (Capacitor)
- **Home Screen widget** — Vol+/Vol-/Mute/Standby controls without opening the app (iOS 17+, Liquid Glass on iOS 26+)

## Installation

### Quick Start

```bash
git clone https://github.com/zloi2ff/philips-remote.git
cd philips-remote
python3 server.py
```

Open http://localhost:8888 in your browser. The app will prompt you to scan the network or enter your TV's IP address.

### Configuration

The server can be configured via environment variables:

```bash
# Set TV IP (optional — can be configured from the web UI)
TV_IP=192.168.1.100 python3 server.py

# Change server port
SERVER_PORT=9000 python3 server.py

# Set TV port (default: 1925)
TV_PORT=1925 python3 server.py
```

## Usage on iPhone/Android

### Web App (PWA)

1. Open `http://YOUR_SERVER_IP:8888` in Safari/Chrome
2. Tap Share button → "Add to Home Screen"
3. Use as a native app

### Native iOS App

Build and install with Xcode:

```bash
# Install dependencies
npm install

# Sync with iOS
npx cap sync ios

# Open in Xcode
npx cap open ios
```

In Xcode:
1. Select your iPhone device
2. Configure signing (Signing & Capabilities → Team)
3. Press Run (Cmd+R)

## API Reference

The TV uses JointSpace API v1:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/1/system` | GET | System info |
| `/1/audio/volume` | GET/POST | Volume control |
| `/1/sources` | GET | Available sources |
| `/1/sources/current` | POST | Switch source |
| `/1/input/key` | POST | Send remote key |

### Server Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/discover` | GET | Scan local network for Philips TVs |
| `/config` | GET | Get current TV IP configuration |
| `/config` | POST | Set TV IP (`{"ip": "...", "port": ...}`) |

### Key codes

`Standby`, `VolumeUp`, `VolumeDown`, `Mute`, `ChannelStepUp`, `ChannelStepDown`, `CursorUp`, `CursorDown`, `CursorLeft`, `CursorRight`, `Confirm`, `Back`, `Home`, `Source`, `Info`, `Options`, `Find`, `Adjust`, `Digit0`-`Digit9`, `Play`, `Pause`, `Stop`, `Rewind`, `FastForward`, `Record`, `RedColour`, `GreenColour`, `YellowColour`, `BlueColour`

## License

MIT
