# DialWave

> **Native macOS companion for Android using Bluetooth-first communication.**  
> DialWave runs silently in your macOS menubar, connects to your Android phone via Bluetooth RFCOMM, and upgrades to local Wi-Fi sockets to mirror call states, route audio, sync messages, and handle contacts.

> 🔒 **100% Offline. Nothing leaves your local network.** No cloud, no external servers, no logging endpoints, no accounts. Your synced contacts, SMS threads, and call audio streams remain entirely on your own local devices.

---

## About DialWave

### What it is

DialWave is a **local-first communication integration suite** between Android and macOS. It acts as an integration bridge so you can interact with calls and SMS on your Mac while leaving your phone in your pocket. The system operates with sub-second call alerts, rapid dial capability, and near-zero latency audio routing.

### How it works

1.  **Initial Discovery & Handshake:**
    On startup, the macOS menubar app begins scanning for the companion phone using `CoreBluetooth`. An RFCOMM channel is opened using a shared custom UUID service record.
2.  **Wi-Fi Upgrade:**
    Because macOS Bluetooth stacks are historically unstable for high-throughput, continuous data flow, DialWave uses RFCOMM only for the initial handshake and exchange of local IP addresses. Once both nodes are verified, the connection upgrades to a local TCP/UDP Wi-Fi socket.
3.  **Bypassing the macOS SCO Audio Block:**

    > [!IMPORTANT]
    > macOS completely blocks third-party applications from directly opening and routing audio via Bluetooth SCO (HFP voice profile).

    DialWave solves this limitation by implementing a direct **Network Audio Bridge**:
    - When a call goes active, the Android app captures voice streams using `AudioRecord` (16kHz mono 16-bit PCM).
    - This audio payload is packetized and streamed over a local **UDP Socket** to the Mac.
    - The Mac decodes and plays the PCM stream through the system output devices using `AVFoundation`.
    - Simultaneously, the Mac captures microphone input, packages it, and streams it back to Android over UDP, where it is injected into the call path using `AudioTrack`.

---

## Architecture

DialWave operates as a multi-threaded, asynchronous service broker on both platforms:

### macOS Application Process Thread Model

```
Process: DialWave macOS
│
├── Main Thread — RunLoop & View Updates
│   ├── MenuBar View updates, popup window lifecycle, preference tabs
│   └── ServiceRegistry coordinator
│
├── Bluetooth / Network Threads
│   ├── CBCentralManager discovery queues
│   ├── TCP Control socket listener (Incoming events/JSON payloads)
│   └── UDP Audio stream client (Real-time PCM reader/writer)
│
└── Storage & Core Services Thread
    └── SQLite database writes, contact queries, and message thread caches
```

---

## File Structure

```text
Dialwave/
├── App/                          # App Entry Point & Delegation
│   ├── AppDelegate.swift         # AppKit integration, background daemon agent
│   ├── AppEnvironment.swift      # Context locator & dependency injector
│   └── DialwaveApp.swift         # SwiftUI lifecycle start
├── UI/                           # User Interfaces
│   ├── Screens/                  # Multi-tab view layouts
│   │   ├── Settings/             # UI for preferences and limits
│   │   ├── CallPopup/            # Incoming call HUD popup
│   │   └── Contacts/             # Sync list view with contact search
│   ├── Menubar/                  # Status bar components
│   ├── Popovers/                 # Quick actions panel
│   ├── Windows/                  # Standalone floating window management
│   └── Components/               # Reusable views (buttons, wave visualizers)
├── Services/                     # Core Business Logic
│   ├── Base/                     # Coordinator registry
│   ├── Call/                     # Call monitoring & audio triggers
│   ├── SMS/                      # Message thread indexers
│   ├── Contacts/                 # Contact fetcher & sync managers
│   └── Notifications/            # System banners and notification relays
├── Bluetooth/                    # Device Interfacing
│   ├── Core/                     # CBCentral wrappers
│   ├── Connection/               # Socket coordinators
│   ├── Discovery/                # Peer scanning routines
│   └── Transport/                # RFCOMM & Wi-Fi stream sockets
├── Protocol/                     # Cross-Platform Communication Protocol
│   ├── Base/                     # Message frames & envelope wrappers
│   ├── Commands/                 # Request models (Dial, SMS reply)
│   └── Events/                   # Notification models (Incoming call, text)
├── Storage/                      # Persistence Controllers
│   ├── Database/                 # SQLite configuration and schema versions
│   ├── Preferences/              # UserDefaults bindings
│   └── Repositories/             # Data access layers (Contacts, SMS threads)
├── Models/                       # Domain data representations
└── Utilities/                    # Helpers, extensions, unified logging
```

---

## Features

- **Zero-Dock Menubar Daemon:** Sits cleanly in the status bar with connection state indicators (Connected, Handshake, Disconnected).
- **WiFi Audio Link:** Direct microphone and speaker routing using UDP, maintaining clear call quality and avoiding macOS SCO blocks.
- **Programmable Call Control:** Full answer, reject, and dial capabilities triggered directly from HUD popup notifications.
- **Local SQLite Storage:** Instant contact lookup and call logs stored locally inside the Application Support folder.
- **SMS Thread Popovers:** Read conversation blocks and write replies directly from the menu bar drop-down.
- **Notification Mirroring:** Relays specific app notifications from your Android device to macOS notifications natively.

---

## Technical Stack

### macOS Stack

| Module            | Technology                            |
| :---------------- | :------------------------------------ |
| **GUI Framework** | SwiftUI + AppKit                      |
| **Peripherals**   | CoreBluetooth (RFCOMM / L2CAP client) |
| **Audio Routing** | AVFoundation / AudioToolbox           |
| **Local Storage** | SQLite.swift / CoreData               |
| **Networking**    | Network.framework (TCP / UDP)         |

### Android Stack

| Module              | Technology                                            |
| :------------------ | :---------------------------------------------------- |
| **Language**        | Kotlin                                                |
| **Audio Interface** | AudioRecord + AudioTrack (Low-latency stream capture) |
| **Bluetooth API**   | Android Bluetooth API (RFCOMM socket server)          |
| **System Hooks**    | TelecomManager, BroadcastReceiver, ContentResolver    |
| **UI Framework**    | Jetpack Compose (Config / logging dashboard)          |

---

MIT License. Developed by [Rishi Shah](https://github.com/rishis26).
