# Phase 1 Preview: Example Deliverables

## Preview 1: Refactored NodeAppModel Architecture

```
Before (2,681 LOC monolith):
┌─────────────────────────────────────────────┐
│         NodeAppModel (2,681 LOC)            │
├─────────────────────────────────────────────┤
│ • Gateway connection loops                  │
│ • All capability handlers                   │
│ • Background lifecycle                      │
│ • Deep link routing                         │
│ • Voice wake state                          │
│ • Talk mode state                           │
│ • Device service delegation                 │
│ • Chat coordination                         │
│ • Screen/canvas management                  │
│ • Watch communication                       │
└─────────────────────────────────────────────┘

After (Modular, ~400 LOC core):
┌──────────────────────┐
│  NodeAppModel        │  Core model (400 LOC)
│  (@Observable)       │  • Gateway config state
├──────────────────────┤  • Service references
│ Delegates to:        │  • Main environment root
├──────────────────────┤
│ ┌────────────────────┐
│ │ CapabilityCoordinator (new, 300 LOC)
│ │ • Routes invoke() → specific handler
│ │ • Camera, Screen, Location, Device, Chat
│ │ • Error mapping
│ └────────────────────┘
│ ┌────────────────────┐
│ │ BackgroundLifecycle (new, 250 LOC)
│ │ • Scene phase → connection state
│ │ • Silent push wake
│ │ • Voice wake suspend/resume
│ │ • Reconnect leases
│ └────────────────────┘
│ ┌────────────────────┐
│ │ DeepLinkCoordinator (new, 150 LOC)
│ │ • Parse url → action
│ │ • Agent deep links
│ │ • Gateway connect links
│ │ • A2UI canvas actions
│ └────────────────────┘
│ ┌────────────────────┐
│ │ GatewayCoordinator (existing, refactored)
│ │ • nodeGateway session
│ │ • operatorGateway session
│ │ • Capability discovery
│ │ • Reconnect loops
│ └────────────────────┘
└──────────────────────┘
```

---

## Preview 2: Test Coverage Expansion

### TalkModeManager Test Suite (Example)

```swift
@Suite("TalkModeManager")
struct TalkModeManagerTests {

  @Test("enablement toggles recording")
  async func enablementToggling() {
    let manager = TalkModeManager()
    #expect(manager.isEnabled == false)
    await manager.setEnabled(true)
    #expect(manager.isEnabled == true)
  }

  @Test("ptt start initiates recording")
  async func pttStartRecording() {
    let manager = TalkModeManager()
    await manager.handlePushToTalkStart()
    #expect(manager.recordingState == .recording)
  }

  @Test("silence detection stops recording after threshold")
  async func silenceDetection() {
    let manager = TalkModeManager(_test_silenceThresholdMs: 500)
    await manager.handlePushToTalkStart()
    await manager._test_seedAudio(silent: 600ms)  // Exceed threshold
    await manager._test_runSilenceCheck()
    #expect(manager.recordingState == .stopping)
  }

  @Test("transcript incremental ingestion")
  async func incrementalTranscript() {
    let manager = TalkModeManager()
    await manager.handleTranscript("hello", isFinal: false)
    #expect(manager.currentTranscript == "hello")
    await manager.handleTranscript("hello world", isFinal: true)
    #expect(manager.currentTranscript == "hello world")
    #expect(manager.lastWordConfidence > 0.8)
  }

  @Test("TTS playback blocks new PTT")
  async func ttsBlocksPTT() {
    let manager = TalkModeManager()
    await manager.playTTS("Speaking...")
    #expect(manager.isSpeaking == true)

    let pttResult = await manager.handlePushToTalkStart()
    #expect(pttResult == .blocked(.currentlySpeaking))
  }
}
```

---

## Preview 3: Documentation Structure

```markdown
## iOS Architecture Guide

### 1. Quickstart
   - 5-min setup guide
   - npm scripts reference
   - Common tasks (build, test, run)

### 2. Module Organization (Interactive Map)
   ┌─ Gateway (13 files)
   │  ├─ Discovery & Bonjour
   │  ├─ WebSocket Connection
   │  ├─ TLS Trust Management
   │  └─ Health Monitoring
   ├─ Voice (5 files)
   │  ├─ Voice Wake (always-on)
   │  └─ Talk Mode (PTT + STT + TTS)
   ├─ Screen (4 files)
   │  ├─ Canvas (WKWebView)
   │  ├─ A2UI Bridge
   │  └─ Screen Recording
   ├─ Model (2 files)
   │  ├─ NodeAppModel (core)
   │  └─ Gateway Sessions
   └─ [9 other modules...]

### 3. Architecture Decisions
   - ADR-001: Dual-session gateway design
   - ADR-002: Observable-based state management
   - ADR-003: Protocol-oriented services
   - ADR-004: Background lifecycle with leases

### 4. Data Flow Diagrams
   - User interaction → capability dispatch
   - Gateway discovery flow
   - Deep link handling
   - Voice wake pipeline

### 5. Testing Guide
   - Unit test patterns
   - Async testing with Swift Testing
   - Mock service creation
   - Coverage gaps & priorities
```

---

## Preview 4: Service Layer Refactoring

```swift
// BEFORE: Scattered responsibility in NodeAppModel
class NodeAppModel: @unchecked Sendable {
  func handleLocationInvoke(_ params: LocationParams) -> LocationPayload { ... }
  func handleCameraInvoke(_ params: CameraParams) -> CameraPayload { ... }
  func handleDeviceInvoke(_ params: DeviceParams) -> DevicePayload { ... }
  // ... 40+ similar methods
}

// AFTER: Organized coordinator
@MainActor
class CapabilityCoordinator {
  private let camera: CameraServicing
  private let location: LocationServicing
  private let device: DeviceStatusServicing
  private let screen: ScreenController
  private let contacts: ContactsServicing
  // ... etc

  func handle(_ request: BridgeInvokeRequest) async throws -> BridgeInvokeResponse {
    switch request.command {
      case .camera(let params):
        return try await camera.handle(params)
      case .location(let params):
        return try await location.handle(params)
      case .device(let params):
        return try await device.handle(params)
      // ... clean dispatch pattern
    }
  }
}

// Each service is now testable independently:
@Suite("CameraServiceTests")
struct CameraServiceTests {
  let camera: MockCameraService

  @Test("snap captures photo")
  async func snapCapture() { ... }
}
```

---

## Preview 5: Build System Improvements

### Before
```bash
$ pnpm ios:build
# Runs generic signing script, SwiftFormat/SwiftLint on every build
# Takes 15+ seconds just for linting
# Signing config buried in 4 xcconfig files
```

### After
```bash
$ pnpm ios:build
# Uses incremental Xcode build cache
# Pre-commit hooks prevent bad code from being staged
# Single source of truth for signing config
# Clear errors on missing team ID

$ pnpm ios:setup
# One-time setup: detects team, creates local config, validates toolchain

$ pnpm ios:lint
# Run linters separately (not on every build)

$ pnpm ios:fix
# Auto-format code with SwiftFormat
```

---

## Preview 6: Test Coverage Dashboard (Final)

```
Module Coverage Summary (After Phase 2)
┌─────────────────────┬─────────┬────────────┐
│ Module              │ Files   │ Coverage   │
├─────────────────────┼─────────┼────────────┤
│ Gateway             │ 13      │ ████████░░ 82% │
│ Voice (VoiceWake)   │ 3       │ ██████████ 95% │
│ Voice (TalkMode)    │ 2       │ ████████░░ 78% │ ← NOW COVERED
│ Model               │ 2       │ ███████░░░ 65% │
│ Screen              │ 4       │ ██████░░░░ 58% │
│ Camera              │ 1       │ █████░░░░░ 52% │
│ Contacts            │ 1       │ ████░░░░░░ 42% │ ← NOW COVERED
│ Location            │ 2       │ ███░░░░░░░ 35% │ ← NOW COVERED
│ Settings            │ 3       │ ███░░░░░░░ 32% │
│ Device              │ 3       │ ██░░░░░░░░ 25% │
│ Other               │ 9       │ ██░░░░░░░░ 18% │
├─────────────────────┼─────────┼────────────┤
│ OVERALL             │ 57      │ ██████░░░░ 52% │
└─────────────────────┴─────────┴────────────┘

Test Count: 116 → 240+ tests
High-Priority Gaps Closed: 5/5 ✓
```

---

## Preview 7: Developer Onboarding Guide

### New Developer Checklist (After improvements)

```markdown
## Getting Started with OpenClaw iOS

### 1. Prerequisites
- [ ] Xcode 16+ installed
- [ ] pnpm installed
- [ ] Apple Developer account

### 2. Clone & Setup (5 minutes)
  $ git clone <repo>
  $ cd openclaw
  $ pnpm install
  $ pnpm ios:setup
  → Automatically detects team, creates signing config

### 3. Build & Run
  $ pnpm ios:run
  → Builds, boots simulator, launches app

### 4. Understand the Architecture
  Read: docs/ios-architecture.md (10 min overview)
  Then: Check relevant module guide (Voice, Gateway, Screen, etc.)

### 5. Run Tests
  $ pnpm ios:test           # All tests
  $ pnpm ios:test --module Voice  # One module
  $ pnpm ios:coverage       # Coverage report

### 6. Make Changes
  $ git checkout -b feature/your-feature
  (code)
  $ pnpm ios:lint --fix     # Auto-format
  $ pnpm ios:test           # Run tests
  $ git commit …
  $ git push origin feature/your-feature
  → Create PR

### 7. Common Tasks
  See docs/ios-common-tasks.md for:
  - Adding a new service
  - Creating tests
  - Debugging WebSocket connection
  - Voice wake tuning
```

---

## Summary: Phase 1 Output

| Deliverable | Format | Size | Impact |
|---|---|---|---|
| Refactored NodeAppModel | Swift code | 4 files, ~700 LOC | ⬇️ 75% LOC reduction, ⬆️ testability |
| TalkModeManager tests | Swift tests | 1 file, ~350 LOC | ⬆️ 62 new tests, 100% coverage |
| Architecture documentation | Markdown | 8 docs, ~200 KB | ⬆️ developer velocity |
| Build system improvements | Scripts + xcconfig | 3 files | ⬇️ 60% build lint time |
| Service layer examples | Swift code | 5 files | 🧪 mock patterns, testability |
| Coverage dashboard | Markdown/metrics | Interactive | 📊 visibility into quality |

