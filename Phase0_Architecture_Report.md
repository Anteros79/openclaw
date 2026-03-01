# OpenClaw iOS App -- Architecture Report (Phase 0.1)

## 1. Project Configuration Overview

**Path:** `/home/user/openclaw/apps/ios/`
**Build system:** XcodeGen (`project.yml`)
**Swift version:** 6.0 with `SWIFT_STRICT_CONCURRENCY: complete`
**Minimum deployment target:** iOS 18.0
**Bundle ID prefix:** `ai.openclaw`
**Version:** 2026.2.21 (build 20260220)

### Targets

| Target | Type | Platform | Key Dependencies |
|---|---|---|---|
| `OpenClaw` | application | iOS | OpenClawKit, OpenClawChatUI, OpenClawProtocol, SwabbleKit, AppIntents.framework |
| `OpenClawShareExtension` | app-extension | iOS | OpenClawKit |
| `OpenClawWatchApp` | application.watchapp2 | watchOS 11.0 | OpenClawWatchExtension |
| `OpenClawWatchExtension` | watchkit2-extension | watchOS 11.0 | WatchConnectivity, UserNotifications |
| `OpenClawTests` | bundle.unit-test | iOS | OpenClaw (host), SwabbleKit, AppIntents |

### Pre-build Scripts
- SwiftFormat (lint-only, via `.swiftformat` config)
- SwiftLint (via `.swiftlint.yml`)

---

## 2. Module Inventory

**Total Swift source files:** 57
**Total lines of code (app sources only):** ~14,750

| Module | Files | LOC (est.) | Primary Responsibility |
|---|---|---|---|
| **Root** (top-level Sources/) | 5 | 1,148 | App entry, root view hierarchy, session key utils |
| **Gateway** | 13 | 2,314 | Bonjour discovery, WebSocket connection, TLS trust, settings persistence, health monitoring |
| **Model** | 2 | 2,681 | Central app state (`NodeAppModel`), gateway session orchestration, capability dispatch |
| **Voice** | 5 | 2,559 | Voice wake (always-on keyword detection), Talk Mode (push-to-talk + continuous STT + TTS) |
| **Onboarding** | 4 | 1,392 | First-run wizard, QR scanner, connection mode selection, pairing flow |
| **Settings** | 3 | 1,180 | Settings UI, voice wake word editor, networking helpers |
| **Screen** | 4 | 953 | WKWebView canvas, screen recording (ReplayKit), URL navigation, A2UI bridge |
| **Services** | 3 | 441 | Protocol definitions for all device services, notification abstraction, Watch messaging |
| **Status** | 3 | 245 | Status pill UI, voice wake toast, activity builder |
| **Location** | 2 | 244 | CoreLocation wrapper, significant location monitoring for background wake |
| **Contacts** | 1 | 212 | CNContactStore search/add operations |
| **Device** | 3 | 204 | Battery/thermal/storage/network status, device info, display name resolution |
| **Chat** | 2 | 184 | Chat sheet UI, gateway chat transport adapter |
| **Media** | 1 | 164 | Photo Library access (PHPhotoLibrary) |
| **Calendar** | 1 | 135 | EventKit calendar events read/add |
| **Reminders** | 1 | 133 | EventKit reminders read/add |
| **Motion** | 1 | 100 | CoreMotion activity/pedometer queries |
| **Camera** | 1 | 402 | AVCaptureSession photo/video capture |
| **EventKit** | 1 | 34 | Shared authorization helpers for Calendar/Reminders |
| **Capabilities** | 1 | 25 | Command router (string -> handler dispatch) |

---

## 3. Architecture Diagram

```
                         +------------------+
                         |  OpenClawApp     |  @main SwiftUI App
                         |  (App Delegate)  |  APNs, BGTask, UNNotification
                         +--------+---------+
                                  |
                          creates & owns
                         +--------+---------+
                         |  RootCanvas      |  Primary full-screen view
                         |  (or RootTabs)   |  Sheet modals: Settings, Chat, QuickSetup
                         +--------+---------+
                                  |
             .environment()       |       .environment()
          +----------+    +-------+--------+    +------------------+
          | VoiceWake|    | NodeAppModel   |    | GatewayConnection|
          | Manager  |    | (@Observable)  |    | Controller       |
          +----------+    +-------+--------+    | (@Observable)    |
                                  |             +--------+---------+
                    owns          |                      |
           +------+------+-------+------+       +-------+--------+
           |      |      |      |       |       |  GatewayDisc-  |
        Screen  Camera  Talk  Location  ...     |  overyModel    |
        Ctrl    Ctrl    Mode  Service          |  (NWBrowser)   |
           |      |     Mgr     |               +----------------+
           |      |      |      |
      WKWebView  AV   Speech   CL
              Capture  Recog   Location
                       + TTS   Manager

                                  NodeAppModel
                                  +-----+-----+
                       role=node  |           |  role=operator
                   +---------+   |           |   +---------+
                   | nodeGW  |   |           |   | operGW  |
                   | Session |   |           |   | Session |
                   +----+----+   |           |   +----+----+
                        |        |           |        |
                        +--------+-----------+--------+
                                 |
                          WebSocket(s) to Gateway
                          (TLS, token auth, JSON-RPC)
```

---

## 4. Observable Model Hierarchy

All primary models use Swift `@Observable` (Observation framework) and are `@MainActor`-isolated.

```
OpenClawApp
  |-- @State NodeAppModel          (central truth for app state)
  |     |-- ScreenController       (@Observable, WKWebView management)
  |     |-- VoiceWakeManager       (@Observable, @MainActor, SFSpeech)
  |     |-- TalkModeManager        (@Observable, @MainActor, STT+TTS)
  |     |-- GatewayHealthMonitor   (@MainActor, polling health check)
  |     |-- nodeGateway            (GatewayNodeSession - network layer)
  |     |-- operatorGateway        (GatewayNodeSession - network layer)
  |     |-- [service protocols]    (camera, location, device, photos, contacts, etc.)
  |
  |-- @State GatewayConnectionController  (@Observable, discovery + connect orchestration)
        |-- GatewayDiscoveryModel  (@Observable, NWBrowser Bonjour)
```

**Environment injection pattern:**
```swift
RootCanvas()
    .environment(appModel)              // NodeAppModel
    .environment(appModel.voiceWake)    // VoiceWakeManager
    .environment(gatewayController)     // GatewayConnectionController
```

All child views access models via `@Environment(NodeAppModel.self)` etc.

---

## 5. Gateway Connection Architecture

### 5.1 Dual-Session Design

The app maintains **two concurrent WebSocket connections** to the same gateway:

| Session | Role | Purpose | Key Methods |
|---|---|---|---|
| `nodeGateway` | `role=node` | Device capabilities: camera, canvas, location, screen, etc. Receives `node.invoke` requests. | `connect()`, `sendEvent()` |
| `operatorGateway` | `role=operator` | Chat, talk, config, voicewake, agents, health checks. | `connect()`, `request()`, `subscribeServerEvents()` |

Both sessions are `GatewayNodeSession` instances (from `OpenClawKit`). They share the same URL, token, password, and TLS params but advertise different roles and scopes.

### 5.2 Connection State Machine

```
                    App Launch
                        |
              GatewaySettingsStore.bootstrapPersistence()
                        |
              GatewayConnectionController.init()
                        |
              GatewayDiscoveryModel.start()   <-- NWBrowser(_openclaw-gw._tcp)
                        |
              maybeAutoConnect()
                        |
             +----------+-----------+
             |                      |
        Manual config         Discovered gateway
        (host:port)          (Bonjour SRV resolve)
             |                      |
             +----------+-----------+
                        |
              TLS fingerprint check (TOFU)
                        |
           +-- pendingTrustPrompt? --+
           |                          |
        Trust accepted          Trust declined
           |                          |
  GatewayTLSStore.save()         Status="Offline"
           |
  startAutoConnect()
           |
  NodeAppModel.applyGatewayConnectConfig()
           |
   +-------+-------+
   |               |
startOperator-  startNode-
GatewayLoop()  GatewayLoop()
   |               |
   |  (infinite reconnect loop with exponential backoff)
   |               |
  onConnected:    onConnected:
   - refresh       - set Connected
     branding      - show A2UI
   - refresh       - register ShareRelay
     agents        - start SignificantLocation
   - start VW       monitoring
     sync
   - start Health
     Monitor
```

### 5.3 Connection Issue Detection

`GatewayConnectionIssue.detect(from:)` classifies status text into:
- `.pairingRequired(requestId:)` -- pauses reconnect, shows approval instructions
- `.tokenMissing` / `.unauthorized` -- stops auto-reconnect
- `.network` -- transient, retries
- `.unknown(String)` -- surfaces error text

### 5.4 Background Lifecycle

1. **Scene goes to `.background`**: discovery stops, voice wake mic released, background grace period begins (25s via `UIBackgroundTask`).
2. **Grace period expires**: both WebSocket connections disconnected, reconnect suppressed.
3. **Silent push wake** (`didReceiveRemoteNotification`): `handleSilentPushWake()` grants a background reconnect lease and processes pending commands.
4. **BGAppRefreshTask**: scheduled every 15 minutes as fallback wake.
5. **Significant location change**: wakes app, grants reconnect lease, forwards location to gateway.
6. **Scene returns to `.active`**: connections health-checked, reconnected if stale (>3s background).

---

## 6. Capability Router (Command Dispatch)

`NodeCapabilityRouter` maps command strings to async handlers. Built lazily in `NodeAppModel.buildCapabilityRouter()`.

| Command Group | Commands | Handler |
|---|---|---|
| Canvas | `canvas.present`, `canvas.hide`, `canvas.navigate`, `canvas.evalJS`, `canvas.snapshot` | `handleCanvasInvoke` |
| A2UI | `a2ui.push`, `a2ui.pushJSONL`, `a2ui.reset` | `handleCanvasA2UIInvoke` |
| Camera | `camera.list`, `camera.snap`, `camera.clip` | `handleCameraInvoke` |
| Screen | `screen.record` | `handleScreenRecordInvoke` |
| Location | `location.get` | `handleLocationInvoke` |
| Device | `device.status`, `device.info` | `handleDeviceInvoke` |
| Watch | `watch.status`, `watch.notify` | `handleWatchInvoke` |
| Photos | `photos.latest` | `handlePhotosInvoke` |
| Contacts | `contacts.search`, `contacts.add` | `handleContactsInvoke` |
| Calendar | `calendar.events`, `calendar.add` | `handleCalendarInvoke` |
| Reminders | `reminders.list`, `reminders.add` | `handleRemindersInvoke` |
| Motion | `motion.activity`, `motion.pedometer` | `handleMotionInvoke` |
| Talk | `talk.pttStart`, `talk.pttStop`, `talk.pttCancel`, `talk.pttOnce` | `handleTalkInvoke` |
| System | `system.notify` | `handleSystemNotify` |
| Chat | `chat.push` | `handleChatPushInvoke` |

Background-restricted commands: anything prefixed `canvas.`, `camera.`, `screen.`, `talk.`

---

## 7. Key Patterns & Architecture Decisions

### 7.1 Swift 6 Strict Concurrency

The entire codebase compiles with `SWIFT_STRICT_CONCURRENCY: complete`. Key patterns:

- **`@MainActor` isolation** on all `@Observable` model classes (`NodeAppModel`, `GatewayConnectionController`, `GatewayDiscoveryModel`, `ScreenController`, `VoiceWakeManager`, `TalkModeManager`).
- **`actor` isolation** for thread-unsafe hardware access (`CameraController` is an `actor`).
- **`@unchecked Sendable`** used sparingly for lock-based thread-safe wrappers (`ScreenRecordService.CaptureState`, `AudioBufferQueue`, `NotificationInvokeLatch`).
- **`nonisolated` methods** for delegate callbacks from system frameworks (CLLocationManagerDelegate, AVCapturePhotoCaptureDelegate).
- **`@ObservationIgnored`** on properties that should not trigger view updates (e.g. `cameraHUDDismissTask`, lazy `capabilityRouter`).

### 7.2 Protocol-Oriented Service Layer

All device services are accessed through protocols defined in `NodeServiceProtocols.swift`:
- `CameraServicing`, `ScreenRecordingServicing`, `LocationServicing`, `DeviceStatusServicing`, `PhotosServicing`, `ContactsServicing`, `CalendarServicing`, `RemindersServicing`, `MotionServicing`, `WatchMessagingServicing`

Concrete implementations conform via extensions: `extension CameraController: CameraServicing {}`.
This enables test doubles via constructor injection into `NodeAppModel.init(...)`.

### 7.3 SwiftUI View Composition

- **Single-window app**: `WindowGroup` containing `RootCanvas`.
- **No TabView in production**: `RootCanvas` uses a `ZStack` overlay pattern. `RootTabs` exists as an alternative but `RootView` delegates directly to `RootCanvas`.
- **Sheet-based navigation**: Settings, Chat, and QuickSetup are presented as `.sheet(item:)` modals.
- **Full-screen cover**: Onboarding wizard uses `.fullScreenCover(isPresented:)`.
- **ViewModifier pattern**: `GatewayTrustPromptAlert` is a `ViewModifier` applied via `.gatewayTrustPromptAlert()`.
- **Overlay HUD**: Status pill, voice wake toast, camera flash overlay, and talk orb are positioned as `.overlay(alignment:)` layers.

### 7.4 Persistence Strategy

| Store | Data | Mechanism |
|---|---|---|
| `UserDefaults` | Feature toggles, display name, instance ID, gateway config, onboarding state | `@AppStorage` in views, direct `UserDefaults.standard` in services |
| `Keychain` (via `KeychainStore`) | Gateway token, password, instance ID, preferred gateway stable ID, ElevenLabs API key | `Security` framework (kSecClassGenericPassword) |
| `GatewayTLSStore` | TLS certificate fingerprints (SHA-256 pinning) | Keychain |
| `GatewayDiagnostics` | Rolling log file (512KB max) in Documents | File I/O on serial dispatch queue |
| `ShareGatewayRelaySettings` | Relay config for Share Extension | App group container (shared with extension) |

### 7.5 Error Handling

- Gateway RPC errors: `GatewayResponseError` propagated from `GatewayNodeSession.request()`.
- Capability invocation: errors caught in `handleInvoke()`, mapped to `BridgeInvokeResponse` with `OpenClawNodeError` codes (`.unavailable`, `.invalidRequest`, `.backgroundUnavailable`).
- Best-effort pattern: many operator-session RPCs (`refreshBranding`, `refreshAgents`, `refreshWakeWords`) use `catch` with comments "// Best-effort only." and swallow errors.
- Connection errors: exponential backoff (`0.5 * 1.7^attempt`, capped at 8s for operator, similar for node).

### 7.6 Deep Link Handling

URL scheme: `openclaw://`
- Parsed by `DeepLinkParser.parse(url:)` into `.agent(AgentDeepLink)` or `.gateway`.
- Agent deep links forwarded to gateway via `node.invoke` event `agent.request`.
- A2UI actions from the canvas WebView are routed through `ScreenController.onA2UIAction` -> `NodeAppModel.handleCanvasA2UIAction()`.

---

## 8. Import Dependency Matrix

| Module | OpenClawKit | OpenClawChatUI | OpenClawProtocol | SwabbleKit | SwiftUI | UIKit | Observation | Network | System Frameworks |
|---|---|---|---|---|---|---|---|---|---|
| Root | X | | | | X | X | | | BackgroundTasks, UserNotifications |
| Gateway | X | | | | X | X | X | X | CryptoKit, Security, Darwin, AVFoundation, Contacts, CoreLocation, CoreMotion, EventKit, Photos, ReplayKit, Speech |
| Model | X | X | X | | X | X | X | X | UserNotifications |
| Voice | X | X | X | X | X | | X | | AVFAudio, Speech |
| Screen | X | | | | X | X | X | | WebKit, AVFoundation, ReplayKit |
| Chat | X | X | X | | X | | | | |
| Onboarding | X | | | | X | X | | | CoreImage, Combine, PhotosUI, VisionKit |
| Settings | X | | | | X | X | X | X | |
| Services | X | | | | | X | | | CoreLocation, UserNotifications |
| Location | X | | | | | | | | CoreLocation |
| Camera | X | | | | | | | | AVFoundation |
| Device | X | | | | | X | | X | |
| Contacts | X | | | | | | | | Contacts |
| Media | X | | | | | X | | | Photos |
| Calendar | X | | | | | | | | EventKit |
| Reminders | X | | | | | | | | EventKit |
| Motion | X | | | | | | | | CoreMotion |
| Status | | | | | X | | | | |
| Capabilities | X | | | | | | | | |

---

## 9. Critical Dependencies

### 9.1 OpenClawKit (local package: `../shared/OpenClawKit`)

Three library products consumed:

| Product | Usage |
|---|---|
| `OpenClawKit` | Core types: `GatewayNodeSession`, `GatewayConnectOptions`, `GatewayTLSParams`, `BridgeInvokeRequest/Response`, `OpenClawNodeError`, all `OpenClaw*Params/Payload` types, Bonjour constants, `OpenClawCapability`, `OpenClawCanvasCommand`, `OpenClawKitResources.bundle` |
| `OpenClawChatUI` | `OpenClawChatView`, `OpenClawChatViewModel`, `OpenClawChatTransport` protocol, chat event types |
| `OpenClawProtocol` | `GatewayPayloadDecoding`, `AgentSummary`, `AgentsListResult`, `OpenClawGatewayHealthOK`, protocol-level event types |

Transitive dependencies: `ElevenLabsKit` (TTS), `Textual` (Markdown rendering in chat).

### 9.2 SwabbleKit (local package: `../../Swabble`)

Used by `VoiceWakeManager` (imported as `SwabbleKit`). Provides audio processing utilities for the voice wake keyword detection pipeline.

### 9.3 System Framework Summary

| Framework | Usage |
|---|---|
| AVFoundation | Camera capture (photo + video), audio engine for Voice/Talk |
| BackgroundTasks | BGAppRefreshTask scheduling |
| Contacts | Contact search and creation |
| CoreImage | QR code generation in onboarding |
| CoreLocation | Location services, significant change monitoring |
| CoreMotion | Activity recognition, pedometer |
| CryptoKit | TLS fingerprint computation |
| EventKit | Calendar events and reminders |
| Network | NWBrowser (Bonjour discovery), NWEndpoint |
| Photos / PhotosUI | Photo library access, photo picker in onboarding |
| ReplayKit | Screen recording |
| Security | Keychain storage |
| Speech | SFSpeechRecognizer for voice wake and talk mode |
| UserNotifications | Local notifications (watch prompt mirroring) |
| VisionKit | DataScannerViewController for QR scanning |
| WatchConnectivity | Watch extension messaging |
| WebKit | WKWebView for canvas rendering |

---

## 10. Entry Points by Feature

| Feature | Primary Entry Point | Key Files |
|---|---|---|
| App Launch | `OpenClawApp.init()` | `Sources/OpenClawApp.swift` |
| Main UI | `RootCanvas.body` | `Sources/RootCanvas.swift` |
| Gateway Discovery | `GatewayDiscoveryModel.start()` | `Sources/Gateway/GatewayDiscoveryModel.swift` |
| Gateway Connection | `GatewayConnectionController.connectDiscoveredGateway()` / `connectManual()` | `Sources/Gateway/GatewayConnectionController.swift` |
| Node Capability Dispatch | `NodeAppModel.handleInvoke()` -> `capabilityRouter.handle()` | `Sources/Model/NodeAppModel.swift` (line ~813) |
| Chat | `ChatSheet` -> `IOSGatewayChatTransport` | `Sources/Chat/ChatSheet.swift` |
| Voice Wake | `VoiceWakeManager.setEnabled(true)` | `Sources/Voice/VoiceWakeManager.swift` |
| Talk Mode | `TalkModeManager.setEnabled(true)` | `Sources/Voice/TalkModeManager.swift` |
| Canvas/A2UI | `ScreenController.navigate(to:)` | `Sources/Screen/ScreenController.swift` |
| Camera | `CameraController.snap()` / `.clip()` | `Sources/Camera/CameraController.swift` |
| Screen Recording | `ScreenRecordService.record()` | `Sources/Screen/ScreenRecordService.swift` |
| Onboarding | `OnboardingWizardView` | `Sources/Onboarding/OnboardingWizardView.swift` |
| Settings | `SettingsTab` | `Sources/Settings/SettingsTab.swift` |
| Deep Links | `NodeAppModel.handleDeepLink(url:)` | `Sources/Model/NodeAppModel.swift` (line ~747) |
| Background Wake | `OpenClawAppDelegate.handleBackgroundWakeRefresh()` | `Sources/OpenClawApp.swift` (line ~130) |
| Share Extension | `ShareViewController` | `ShareExtension/ShareViewController.swift` |
| Watch Extension | `OpenClawWatchApp` | `WatchExtension/Sources/OpenClawWatchApp.swift` |

---

## 11. Notable Patterns and Concerns

### Strengths
1. **Clean protocol-based DI**: All hardware services are behind protocols, enabling comprehensive testability. `NodeAppModel.init()` accepts all services as parameters with production defaults.
2. **Full Swift 6 concurrency compliance**: No data races; all observable models are `@MainActor`-isolated.
3. **Robust background lifecycle management**: Sophisticated grace period, lease-based reconnect suppression, and silent push / significant location wake strategies.
4. **TLS pinning with trust-on-first-use**: Security-conscious design that refuses auto-connect to untrusted gateways.
5. **Good test coverage** of critical gateway connection and voice wake logic.

### Concerns
1. **`NodeAppModel.swift` is 2,681 LOC** (118KB on disk). It centralizes gateway connection loops, all capability handlers, background lifecycle, deep link routing, and more. This is the single most complex file in the codebase and a prime candidate for decomposition.
2. **`GatewayConnectionController.swift` is 962 lines** with heavy responsibilities: discovery observation, auto-connect logic, manual/discovered connect paths, TLS trust flow, capability/permission reporting. The class imports 16 system frameworks.
3. **`TalkModeManager.swift` is 79KB** (~2,000+ LOC). The file comment explicitly acknowledges this: "This file intentionally centralizes talk mode state + behavior."
4. **`SettingsTab.swift` is 49KB** -- a single monolithic settings view with ~38 `@AppStorage` properties.
5. **Heavy use of `UserDefaults`**: Configuration state is spread across dozens of string-keyed `UserDefaults` entries without a centralized schema.
6. **Two separate view hierarchies**: `RootCanvas` (canvas mode with overlay buttons) and `RootTabs` (traditional tab bar) both exist. `RootView` currently delegates to `RootCanvas` only, making `RootTabs` unused/dead code or a legacy alternative.
