# OpenClaw iOS Test Suite Baseline Report (Phase 0.3)

## 1. Test File Inventory

**23 Swift test files** in `apps/ios/Tests/` using **100% Swift Testing** framework (`@Suite`/`@Test` macros). Zero XCTest usage.

| # | File | Module Under Test | Test Count | Type | Serialized? |
|---|------|-------------------|------------|------|-------------|
| 1 | `AppCoverageTests.swift` | NodeAppModel, VoiceWakeManager | 2 | Unit | No |
| 2 | `CameraControllerClampTests.swift` | Camera (CameraController) | 2 | Unit | No |
| 3 | `CameraControllerErrorTests.swift` | Camera (CameraController.CameraError) | 1 | Unit | No |
| 4 | `DeepLinkParserTests.swift` | DeepLinkParser, GatewayConnectDeepLink | 16 | Unit | No |
| 5 | `GatewayConnectionControllerTests.swift` | GatewayConnectionController, GatewaySettingsStore | 6 | Unit/Integration | Yes |
| 6 | `GatewayConnectionIssueTests.swift` | GatewayConnectionIssue | 5 | Unit | Yes |
| 7 | `GatewayConnectionSecurityTests.swift` | GatewayConnectionController (TLS/security) | 5 | Unit/Integration | Yes |
| 8 | `GatewayDiscoveryModelTests.swift` | GatewayDiscoveryModel | 1 | Unit | Yes |
| 9 | `GatewayEndpointIDTests.swift` | GatewayEndpointID, BonjourEscapes | 3 | Unit | No |
| 10 | `GatewaySettingsStoreTests.swift` | GatewaySettingsStore, KeychainStore | 5 | Unit/Integration | Yes |
| 11 | `IOSGatewayChatTransportTests.swift` | IOSGatewayChatTransport | 1 | Unit | No |
| 12 | `KeychainStoreTests.swift` | KeychainStore | 1 | Unit | No |
| 13 | `NodeAppModelInvokeTests.swift` | NodeAppModel (invoke dispatch) | 19 | Unit/Integration | Yes |
| 14 | `OnboardingStateStoreTests.swift` | OnboardingStateStore | 3 | Unit | Yes |
| 15 | `ScreenControllerTests.swift` | ScreenController | 6 | Unit/Integration | No |
| 16 | `ScreenRecordServiceTests.swift` | ScreenRecordService | 2 | Unit | Yes |
| 17 | `SettingsNetworkingHelpersTests.swift` | SettingsNetworkingHelpers | 9 | Unit | No |
| 18 | `ShareToAgentDeepLinkTests.swift` | ShareToAgentDeepLink, ShareToAgentSettings | 4 | Unit | No |
| 19 | `SwiftUIRenderSmokeTests.swift` | StatusPill, SettingsTab, RootTabs, VoiceTab, ChatSheet, VoiceWakeToast | 8 | Smoke/UI | No |
| 20 | `VoiceWakeGatewaySyncTests.swift` | VoiceWakePreferences (gateway sync) | 3 | Unit | No |
| 21 | `VoiceWakeManagerExtractCommandTests.swift` | VoiceWakeManager.extractCommand | 5 | Unit | No |
| 22 | `VoiceWakeManagerStateTests.swift` | VoiceWakeManager (state transitions) | 3 | Unit | Yes |
| 23 | `VoiceWakePreferencesTests.swift` | VoiceWakePreferences | 6 | Unit | No |

**Total: 116 `@Test` methods across 23 files.**

---

## 2. Test Infrastructure

### 2.1 Test Target Configuration
- Hosted unit test bundle inside the app (`TEST_HOST` / `BUNDLE_LOADER`)
- Swift 6.0 with `SWIFT_STRICT_CONCURRENCY: complete`
- Dependencies: `OpenClaw` (host), `SwabbleKit`, `AppIntents.framework`

### 2.2 Test Helpers (built into test files)

| Helper | Location | Purpose |
|---|---|---|
| `withUserDefaults(_:_:)` | GatewayConnectionControllerTests, NodeAppModelInvokeTests | UserDefaults snapshot/restore for test isolation (DUPLICATED) |
| `snapshotDefaults/Keychain` | GatewaySettingsStoreTests | Keychain/defaults isolation |
| `makeSegments(transcript:words:)` | VoiceWakeManagerExtractCommandTests | WakeWordSegment test data builder |
| `mountScreen(_:)` | ScreenControllerTests | WKWebView coordinator factory |
| `host(_:)` | SwiftUIRenderSmokeTests | SwiftUI UIWindow hosting |

### 2.3 Mock Objects
- **`MockWatchMessagingService`** -- Only mock class (in NodeAppModelInvokeTests)
- No mocking framework used (manual mocks only)

### 2.4 Production Test Hooks (`#if DEBUG`)

**30+ `_test_` prefixed methods** scattered across production source files:
- `VoiceWakeManager._test_handleRecognitionCallback(...)`
- `NodeAppModel._test_handleInvoke(...)`, `_test_decodeParams(...)`, `_test_encodePayload(...)`, `_test_queuedWatchReplyCount()`
- `GatewayConnectionController._test_resolvedDisplayName(...)`, `_test_currentCaps()`, `_test_currentCommands()`, `_test_setGateways(...)`, `_test_triggerAutoConnect(...)`, `_test_resolveDiscoveredTLSParams(...)`, `_test_resolveManualUseTLS(...)`, `_test_resolveManualPort(...)`
- `ScreenRecordService._test_clampDurationMs(...)`, `_test_clampFps(...)`
- `TalkModeManager._test_seedTranscript(...)`, `_test_handleTranscript(...)`, `_test_backdateLastHeard(...)`, `_test_runSilenceCheck()`, `_test_incrementalReset()`, `_test_incrementalIngest(...)`

---

## 3. Test Patterns

### 3.1 Framework
100% Swift Testing (`@Suite`/`@Test`/`#expect`). Zero legacy XCTest.

### 3.2 Async Testing
~25 tests (22%) are async. `@MainActor` annotation on ~70 tests (60%). `.serialized` trait on 9 of 23 suites.

### 3.3 Network-Dependent Tests
None -- all gateway tests use logic-level assertions without real WebSocket connections.

### 3.4 Permission-Dependent Tests
None -- all permission-gated features are untested at the permission-request level.

---

## 4. Coverage Analysis

### Module Coverage Summary

| Module | Has Tests? | Estimated Coverage |
|--------|------------|-------------------|
| **Gateway** (13 files) | Yes (8 test files) | ~40-50% |
| **Voice** (5 files) | Partial (5 test files, VoiceWake only) | ~35% (VoiceWake ~65%, TalkMode **0%**) |
| **Model** (2 files) | Yes (2 test files) | ~30-35% |
| **Screen** (4 files) | Partial (2 test files) | ~25-30% |
| **Deep Link / Share** | Yes (2 test files) | ~70% |
| **Settings** | Partial (1 test file) | ~25% |
| **Camera** (1 file) | Partial (pure functions only) | ~15% |
| **Chat** (2 files) | Partial (1 test file) | ~10% |
| **Onboarding** (4 files) | Partial (1 test file) | ~15% |
| **SwiftUI Views** | Smoke only (1 test file) | ~5% |
| **Location** (2 files) | **No** | **0%** |
| **Device** (3 files) | **No** | **0%** |
| **Contacts** (1 file) | **No** | **0%** |
| **Calendar** (1 file) | **No** | **0%** |
| **Media** (1 file) | **No** | **0%** |
| **Reminders** (1 file) | **No** | **0%** |
| **Motion** (1 file) | **No** | **0%** |
| **Services** (3 files) | **No** | **0%** |
| **EventKit** (1 file) | **No** | **0%** |

---

## 5. Critical Coverage Gaps

### Priority 1 -- Critical

| Gap | Source File | LOC | Risk | Notes |
|-----|-----------|-----|------|-------|
| **TalkModeManager** | `Voice/TalkModeManager.swift` | ~1,870 | HIGH | Largest untested file. Core feature with STT, TTS, push-to-talk, silence detection. Has 6 `_test_` hooks ready. |
| **GatewayHealthMonitor** | `Gateway/GatewayHealthMonitor.swift` | ~85 | HIGH | Controls connection stability. Injectable `sleep`/`check` closures make it very testable. |
| **SessionKey** | `SessionKey.swift` | ~23 | MEDIUM | Pure functions for session key derivation. Trivially testable. |

### Priority 2 -- Important

| Gap | Source File | Risk |
|-----|-----------|------|
| **LocationService** | `Location/LocationService.swift` | MEDIUM |
| **ContactsService** | `Contacts/ContactsService.swift` | MEDIUM (has `_test_matches` hook) |
| **WatchMessagingService** | `Services/WatchMessagingService.swift` | MEDIUM |
| **DeviceStatusService** | `Device/DeviceStatusService.swift` | LOW |

### Priority 3 -- Existing Test Depth

| Gap | What Is Missing |
|-----|----------------|
| Camera capture flow | No tests for `snap()` or `clip()` |
| ScreenRecordService.record() | No test for recording pipeline |
| NodeAppModel background lifecycle | No reconnect/voice wake suspend tests |
| Gateway reconnection logic | Manual connect, TLS trust, post-disconnect untested |

---

## 6. Test Quality Assessment

### Strengths
- **Well-scoped, atomic tests** -- each test method verifies one behavior
- **Descriptive naming** -- `parseHostPortParsesIPv4`, `handleInvokeRejectsBackgroundCommands`
- **Good async patterns** -- proper `@MainActor`, `.serialized` where needed
- **Zero skipped/disabled tests** -- all 116 active

### Concerns
- **Timing-sensitive tests** in VoiceWakeManagerStateTests (900ms `Task.sleep` assertions)
- **Duplicated helpers** (`withUserDefaults` in 2 files, not shared)
- **Single mock class** (only `MockWatchMessagingService`; 11+ service protocols lack mocks)
- **No UI test target** (no XCUITest)

---

## 7. Recommendations for Phase 2 Test Expansion

### Immediate (Priority 1)
1. **Add TalkModeManager tests** -- 6 `_test_` hooks ready, ~1,870 LOC untested
2. **Add GatewayHealthMonitor tests** -- injectable closures, ~85 LOC
3. **Add SessionKey tests** -- pure functions, trivial to test
4. **Extract shared test helpers** -- deduplicate `withUserDefaults`

### Medium-Term (Priority 2)
5. **Create mock implementations** for: `MockLocationService`, `MockCameraService`, `MockScreenRecordingService`, `MockNotificationCenter`
6. **Expand NodeAppModel invoke tests** for location, notification, device, photo, contact commands
7. **Add GatewayConnectionController reconnect tests**

### Long-Term (Priority 3)
8. **Add UI test target** (XCUITest) for critical flows
9. **Replace `Task.sleep` timing** with deterministic synchronization
10. **Add ContactsService tests** using existing `_test_matches` hook
