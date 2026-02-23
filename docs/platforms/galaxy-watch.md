---
summary: "Research and plan for Samsung Galaxy Watch 8 (Wear OS) integration as an OpenClaw companion node"
read_when:
  - Planning Galaxy Watch companion development
  - Understanding Watch-tier node architecture
  - Comparing Apple Watch vs Galaxy Watch integration paths
title: "Galaxy Watch Integration (Research & Plan)"
---

# Galaxy Watch 8 Integration — Research & Plan

**Status:** Research / Pre-implementation
**Target:** Samsung Galaxy Watch 8 (Wear OS 4) via Android companion
**Branch context:** `claude/research-watch-integration-fjp1Q`

---

## 1. Current Apple Watch Integration (Baseline)

The iOS app already ships a working Apple Watch companion. Understanding it is essential before designing the Galaxy Watch equivalent.

### Architecture

```
OpenClaw Gateway
      |
   WebSocket
      |
  iOS App (node) ──── WatchConnectivity ──── Apple Watch App
      |
   NodeAppModel
   WatchMessagingService
```

The iOS app (`WatchMessagingService.swift`) acts as the **bridge** between the gateway and the watch. The watch itself never connects to the gateway — all transport goes through the phone.

### iOS → Watch: Sending notifications

The gateway issues a `watch.notify` node command. The iOS node handler calls `WatchMessagingService.sendNotification(id:params:)`. This serialises the payload as a `[String: Any]` dictionary keyed with `"type": "watch.notify"` and delivers it via:

1. `WCSession.sendMessage` — when the watch is reachable (immediate, connected-only).
2. `WCSession.transferUserInfo` — queued delivery when the watch is not reachable.

The watch-side `WatchConnectivityReceiver` receives either variant and hands it to `WatchInboxStore`, which persists state and posts a local `UNUserNotificationCenter` notification with appropriate haptics (mapped from the `risk` field: `low → .click`, `medium → .notification`, `high → .failure`).

### Watch → iOS: Quick replies

The watch user taps an action button in `WatchInboxView`. The `WatchInboxStore` builds a `WatchReplyDraft` and the receiver sends it back to iOS via `WCSession.sendMessage` (reachable) or `transferUserInfo` (queued). The iOS `WatchMessagingService` parses the `"type": "watch.reply"` payload and calls the registered reply handler, which the gateway ultimately receives as the user's action response.

### Payload schema (current)

**iOS → Watch (`watch.notify`):**

```json
{
  "type": "watch.notify",
  "id": "<uuid>",
  "title": "OpenClaw",
  "body": "Your PR was merged.",
  "sentAtMs": 1740000000000,
  "promptId": "<id>",
  "sessionKey": "main",
  "kind": "info",
  "details": "Optional extended text",
  "expiresAtMs": 1740003600000,
  "risk": "low",
  "actions": [
    { "id": "ack", "label": "OK" },
    { "id": "dismiss", "label": "Dismiss", "style": "cancel" }
  ]
}
```

**Watch → iOS (`watch.reply`):**

```json
{
  "type": "watch.reply",
  "replyId": "<uuid>",
  "promptId": "<id>",
  "actionId": "ack",
  "actionLabel": "OK",
  "sessionKey": "main",
  "note": null,
  "sentAtMs": 1740000005000
}
```

### Gateway node commands

| Command | Description |
|---------|-------------|
| `watch.status` | Returns `WatchMessagingStatus` (supported, paired, appInstalled, reachable, activationState) |
| `watch.notify` | Sends a notification to the watch with optional quick-reply actions |

---

## 2. Samsung Galaxy Watch 8 — Platform Capabilities

### Hardware specs (Galaxy Watch 8, released 2024)

| Feature | Detail |
|---------|--------|
| OS | Wear OS 4 + One UI Watch 6 |
| Chip | Exynos W1000 (5-core) |
| RAM / Storage | 2 GB / 32 GB |
| Display | 1.5" / 1.3" Super AMOLED, touch |
| Sensors | Heart rate (BioActive), SpO2, ECG, skin temperature, barometer, gyroscope, accelerometer, compass |
| GPS | GPS + GLONASS + BeiDou + Galileo (standalone) |
| Connectivity | BT 5.3, Wi-Fi 2.4/5 GHz, LTE (optional), NFC, UWB |
| Audio | Microphone + speaker |
| Battery | ~40 h typical, ~30 h with AOD |
| Health platform | Samsung Health SDK + Privileged Health SDK |

The Galaxy Watch 8 runs standard **Wear OS 4** and supports the full Jetpack / Google Mobile Services (GMS) Wearable Data Layer API stack.

### Key Wear OS APIs

#### Wearable Data Layer API (primary IPC channel)

The `com.google.android.gms:play-services-wearable` library provides three transports:

| Transport | Delivery | Size limit | Persistence |
|-----------|----------|-----------|-------------|
| `MessageClient` | Push, connected-only | 100 KB | No |
| `DataClient` | Synchronized data store | 100 KB per item | Yes (survives disconnects) |
| `ChannelClient` | Streaming | Unlimited | No |

For OpenClaw the relevant transports mirror the Apple Watch model:
- **`MessageClient`** ≈ `WCSession.sendMessage` (immediate, reachable)
- **`DataClient`** ≈ `WCSession.transferUserInfo` (queued, synced)

Both operate via the paired phone — the watch app calls into the Wearable API and the phone-side Data Layer routes the message.

#### Health data (Samsung-specific)

Samsung provides two SDKs:
- **Samsung Health SDK for Android** (`com.samsung.android.sdk.healthdata`) — read aggregated health data (steps, heart rate, sleep, workouts) from the Samsung Health data store on the phone.
- **Samsung Health Platform (privileged)** — real-time raw sensor streams; requires Samsung partnership.

For the OpenClaw use-case, the standard **Health Services API** (`androidx.health:health-services-client`) available on all Wear OS devices is sufficient for:
- Passive heart rate monitoring
- Step count / cadence
- Activity recognition
- Location (via Wear OS built-in GPS)

#### Complications & Tiles

| Surface | Description |
|---------|-------------|
| **Complications** | Small data slots on watch faces (text, short text, icon, ranged value) |
| **Tiles** | Quick-glance panels swiped left/right on the watch face |
| **Notifications** | Standard `NotificationCompat` — bridged from phone or posted locally |

These are optional but high-value for an "ambient awareness" use-case.

---

## 3. Architecture Proposal

### Overall topology

```
OpenClaw Gateway
      |
   WebSocket
      |
  Android App (node) ──── Wearable Data Layer ──── Galaxy Watch App
      |
  NodeRuntime
  WatchBridgeService (new)
```

The Android app (`apps/android`) already connects to the gateway as a full node. The Galaxy Watch app would be a Wear OS module inside the same Android project, communicating with the phone app over the Wearable Data Layer — exactly mirroring the iOS/Apple Watch relationship.

### Android project changes

The Android app uses a single-module Gradle layout today. Adding Wear OS requires a new `:wear` module:

```
apps/android/
├── app/                        # Existing phone app
│   └── src/main/java/ai/openclaw/android/
│       ├── ...existing files...
│       └── watch/
│           ├── WatchBridgeService.kt   # New: Wearable DataLayer bridge
│           └── WatchModels.kt          # New: shared payload models
└── wear/                       # New: Wear OS app module
    ├── build.gradle.kts
    └── src/main/java/ai/openclaw/wear/
        ├── OpenClawWearApp.kt
        ├── WearMainActivity.kt
        ├── WearInboxStore.kt
        ├── WearConnectivityReceiver.kt
        └── ui/
            ├── WearInboxScreen.kt
            └── WearTheme.kt
```

### New gateway node commands

Extending the existing `watch.*` command namespace to add health/sensor commands is natural:

| Command | Description | Source |
|---------|-------------|--------|
| `watch.status` | Wearable pairing status | Android ← Wearable API |
| `watch.notify` | Send notification + quick replies | Android → Watch |
| `watch.health.heart_rate` | Latest or streaming heart rate (BPM) | Watch sensor |
| `watch.health.steps` | Step count (today / interval) | Watch/phone Health Services |
| `watch.health.activity` | Detected activity (walking, running, etc.) | Watch Health Services |
| `watch.location.get` | GPS fix from the watch (standalone GPS) | Watch GPS |

The first two mirror the Apple Watch commands exactly; the health/location commands are Galaxy Watch–specific enhancements made possible by the richer sensor set.

---

## 4. Feature Mapping: Apple Watch vs Galaxy Watch

| Feature | Apple Watch (iOS) | Galaxy Watch 8 (Android) | Notes |
|---------|------------------|--------------------------|-------|
| Notification delivery | `WCSession.sendMessage` / `transferUserInfo` | `MessageClient` / `DataClient` | Equivalent |
| Quick replies | `watch.reply` payload | Same schema over `MessageClient` | Reuse schema |
| Local notification | `UNUserNotificationCenter` | `NotificationCompat` | Standard |
| Haptics | `WKHapticType` (click/notification/failure) | `VibratorManager` patterns | Equivalent |
| Action buttons | `WatchPromptAction` (SwiftUI `Button`) | `NotificationCompat.Action` or Compose UI | Equivalent |
| Persistent inbox | `UserDefaults` (WatchKit group) | `DataStore<Preferences>` or `DataClient` | Equivalent |
| Heart rate | Not exposed by current Watch app | `PassiveMonitoringClient` | New capability |
| Steps | Not exposed | `PassiveMonitoringClient` | New capability |
| Standalone GPS | Not exposed | `ExerciseClient` / `LocationClient` | New capability |
| Complications | Not implemented | `ComplicationDataSourceService` | Optional enhancement |
| Tiles | Not implemented | `TileService` | Optional enhancement |
| Voice input | Not implemented | `RemoteInputCompat` or `SpeechRecognizer` | Optional |
| ECG / SpO2 | Not exposed | Samsung Health SDK (privileged) | Future |

---

## 5. Payload Schema (proposed Galaxy Watch)

The Galaxy Watch implementation should reuse the same `watch.notify` / `watch.reply` JSON schemas as the Apple Watch for gateway protocol consistency. The only addition is the new health/sensor commands.

### `watch.health.heart_rate` response

```json
{
  "bpm": 72,
  "timestamp": 1740000000000,
  "accuracy": "high"
}
```

### `watch.health.steps` response

```json
{
  "steps": 4321,
  "periodStartMs": 1739952000000,
  "periodEndMs": 1740038400000
}
```

### `watch.health.activity` response

```json
{
  "activity": "WALKING",
  "confidence": 0.95,
  "timestamp": 1740000000000
}
```

### `watch.location.get` response

```json
{
  "latitude": 48.2082,
  "longitude": 16.3738,
  "accuracyMeters": 4.5,
  "altitudeMeters": 171.0,
  "source": "gps",
  "timestamp": 1740000000000
}
```

---

## 6. Implementation Plan

### Phase 1 — Foundation (core notification parity with Apple Watch)

**Android phone app** (`apps/android/app`):

1. Add `com.google.android.gms:play-services-wearable` dependency.
2. Create `WatchModels.kt` — shared Kotlin data classes for `WatchNotifyParams`, `WatchReplyEvent`, `WatchStatus`.
3. Create `WatchBridgeService.kt` — a `WearableListenerService` subclass that:
   - Receives `watch.reply` messages from the watch via `MessageClient.onMessageReceived`.
   - Emits them into `NodeRuntime` (same handler path as other node commands).
4. Add `watch.notify` node command handler in `NodeRuntime` — constructs the JSON payload and sends via `MessageClient` (reachable) or `DataClient` (fallback queued).
5. Add `watch.status` node command handler — queries `CapabilityClient` for connected nodes.
6. Register `WatchBridgeService` in `AndroidManifest.xml` with the `BIND_LISTENER` intent filter.

**Wear OS app** (`apps/android/wear`, new module):

1. Create `wear/build.gradle.kts` with:
   - `com.google.android.gms:play-services-wearable`
   - `androidx.wear.compose:compose-material`
   - `androidx.datastore:datastore-preferences`
2. Create `OpenClawWearApp.kt` — `@WearApp` entry point.
3. Create `WearInboxStore.kt` — `DataStore`-backed observable state (title, body, actions, replyStatus), mirroring iOS `WatchInboxStore`.
4. Create `WearConnectivityReceiver.kt` — `WearableListenerService` subclass that:
   - Receives `watch.notify` messages from the phone.
   - Parses payload, updates `WearInboxStore`.
   - Posts a `NotificationCompat` notification with haptic pattern.
5. Create `WearInboxScreen.kt` — Wear Compose UI:
   - Title + body text.
   - Details (secondary text).
   - Action buttons (mapped to `WatchPromptAction`).
   - Reply status indicator.
   - `updatedAt` timestamp.
6. Send replies on button tap via `MessageClient`.

**Capability advertisement:**

Both modules must declare capabilities in their `res/xml/wear_app_capability.xml` to allow node discovery:

```xml
<!-- phone app -->
<capability name="openclaw_phone_app" />

<!-- wear app -->
<capability name="openclaw_wear_app" />
```

### Phase 2 — Health & location sensors

1. Add `androidx.health:health-services-client` to `:wear`.
2. Create `WearHealthService.kt` — background `Service` that:
   - Opens a `PassiveMonitoringClient` subscription for heart rate and steps.
   - Caches the latest sample in `DataStore`.
3. Add `WearLocationService.kt` — uses Wear OS `FusedLocationProviderClient` for GPS fixes.
4. Expose new gateway commands in the phone app's `NodeRuntime`:
   - `watch.health.heart_rate` — reads cached heart rate from `DataClient` DataItem.
   - `watch.health.steps` — reads cached steps DataItem.
   - `watch.health.activity` — uses `ActivityRecognitionClient` (or cached DataItem).
   - `watch.location.get` — sends a `MessageClient` request to the watch and awaits the GPS fix reply.

### Phase 3 — Complications & Tiles (optional)

1. Create `OpenClawComplicationService.kt` — `SuspendingComplicationDataSourceService` returning short text (last message preview or active alert count).
2. Create `OpenClawTileService.kt` — `TileService` rendering the latest inbox item plus quick-reply actions as a Tile.

### Phase 4 — Documentation & testing

1. Write `docs/platforms/galaxy-watch-setup.md` — user-facing setup guide.
2. Update `docs/platforms/android.md` — cross-link to Galaxy Watch companion.
3. Unit tests for `WatchBridgeService` payload parsing.
4. Integration tests for `DataClient` round-trip.

---

## 7. Key Risks & Open Questions

| Risk | Mitigation |
|------|-----------|
| Samsung Health SDK requires partnership agreement for real-time sensor streams | Phase 2 uses standard Jetpack Health Services, which does not require this |
| Wear OS GMS availability varies (some markets / non-Samsung watches have limited GMS) | Target GMS-enabled watches only; document minimum `play-services-wearable` version |
| `MessageClient` 100 KB payload limit | OpenClaw notifications are small (<2 KB); not a concern |
| Background execution limits on Wear OS (Doze, battery optimisation) | `WearableListenerService` is exempt from Doze; health monitoring uses `PassiveMonitoringClient` which is background-safe |
| Multiple paired watches (user has both Apple Watch and Galaxy Watch) | Not a concern — iOS bridges Apple Watch, Android bridges Galaxy Watch; they are independent nodes |
| Action button count on small watch display | Recommend ≤ 3 actions; gateway should truncate if more are provided |

---

## 8. References

- [Wearable Data Layer API](https://developer.android.com/training/wearables/data/data-layer)
- [Wear OS Compose](https://developer.android.com/training/wearables/compose)
- [Health Services on Wear OS](https://developer.android.com/training/wearables/health-services)
- [Samsung Health SDK](https://developer.samsung.com/health)
- [WatchConnectivity (Apple)](https://developer.apple.com/documentation/watchconnectivity)
- Existing iOS implementation: `apps/ios/Sources/Services/WatchMessagingService.swift`
- Existing Watch app: `apps/ios/WatchExtension/Sources/`
- Shared protocol: `apps/shared/OpenClawKit/Sources/OpenClawKit/WatchCommands.swift`
