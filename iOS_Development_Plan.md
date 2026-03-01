# OpenClaw iOS Development Implementation Plan

**Document Version:** 1.0
**Created:** March 1, 2026
**Status:** Ready for Review
**Scope:** Comprehensive iOS app development and maintenance framework

---

## Executive Summary

This plan provides a structured, context-optimized framework for iOS app development work on the OpenClaw iOS companion application. The OpenClaw iOS app is a **super-alpha, foreground-only node application** that connects to an OpenClaw Gateway and provides voice activation, canvas surface interaction, and direct device control capabilities on iOS 18.0+.

**Key Characteristics:**
- **57 Swift source files** (~13,602 lines of code)
- **5 primary build targets**: OpenClaw, OpenClawShareExtension, OpenClawWatchApp, OpenClawWatchExtension, OpenClawTests
- **Architecture**: SwiftUI-based MVVM with Observable models, real device deployment via Xcode
- **Status**: Internal-use super-alpha, local manual deployment only (no TestFlight)
- **Swift 6.0 strict concurrency**: Full adoption with `SWIFT_STRICT_CONCURRENCY: complete`

**Current Development Challenges:**
1. Background socket reliability (dead-socket states after app backgrounding)
2. Wake/reconnect stability across scene transitions
3. Voice Wake vs Talk microphone contention
4. Background command blocking (camera, canvas, screen, talk)
5. Location polling and geofence trigger hardening

---

## Context Optimization Strategy

### Design Principles

1. **Minimal Context Windows**: Each sub-agent receives ONLY the files it needs
2. **Atomic Responsibilities**: Agents handle single, focused concerns
3. **Parallel Execution**: Independent work streams run simultaneously
4. **File Path Specificity**: Use exact paths, not glob patterns for agent input
5. **Data Isolation**: Minimize cross-agent data dependencies

### Context Allocation Guidelines

| Agent Type | Typical Context Size | File Examples | Rationale |
|---|---|---|---|
| **Architecture Scout** | 10-15 files | `project.yml`, key protocol definitions, module structure | Broad understanding without deep dives |
| **Feature Developer** | 8-12 files | Specific feature module, models, tests, integration points | Focused implementation scope |
| **Test Engineer** | 6-10 files | Test suite, models under test, mock protocols, fixtures | Isolated testing scope |
| **Build/Configuration** | 4-6 files | Build files, signing scripts, scheme definitions | Narrow, specialized scope |
| **Integration Engineer** | 12-18 files | Multiple related modules, gateway controller, service layers | Cross-module coordination |

---

## Dependency Graph & Phase Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 0: Project Assessment & Setup (Parallel Preparation)      │
│ - Architecture Analysis              (Agent: Architecture Scout) │
│ - Build System Validation            (Agent: Build Engineer)     │
│ - Test Suite Baseline                (Agent: Test Engineer)      │
└────────────────────┬────────────────────────────────────────────┘
                     │ (Sequential dependency: baseline established)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: Core Stability Work (Parallel Tracks)                  │
│                                                                   │
│ Track A: Background Socket Hardening                             │
│   └─ Gateway reconnection recovery (Dev Agent A1)                │
│   └─ Scene transition handling (Dev Agent A2)                    │
│                                                                   │
│ Track B: Voice & Audio Improvements                              │
│   └─ Microphone access coordination (Dev Agent B1)               │
│   └─ Voice Wake vs Talk arbitration (Dev Agent B2)               │
│                                                                   │
│ Track C: Location & Automation (Dev Agent C1)                    │
│   └─ Geofence trigger reliability                                │
│   └─ Background location state management                        │
└────────┬─────────────────┬─────────────────────┬────────────────┘
         │                 │                     │ (Parallel execution)
         ▼                 ▼                     ▼
     (Tests A)        (Tests B)            (Tests C)
         │                 │                     │
         └─────────────────┼─────────────────────┘
                           │ (Merge & validation)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: Feature Enhancement & Testing (Parallel Streams)       │
│                                                                   │
│ Track A: Command Surface Improvements                            │
│   └─ Foreground command reliability (Dev Agent D)                │
│                                                                   │
│ Track B: Watch App Hardening                                     │
│   └─ WatchConnectivity protocol optimization (Dev Agent E)       │
│                                                                   │
│ Track C: Share Extension Robustness                              │
│   └─ Deep link handling under memory pressure (Dev Agent F)      │
│                                                                   │
│ Track D: Testing & Validation Coverage                           │
│   └─ Integration test suite (Test Agent)                         │
│   └─ UI smoke tests (Test Agent)                                 │
└────────┬─────────────────┬─────────────────────┬────────────────┘
         │                 │                     │ (Parallel execution)
         ▼                 ▼                     ▼
    (Int Tests A)   (Int Tests B)         (Int Tests C)
         │                 │                     │
         └─────────────────┼─────────────────────┘
                           │ (Integration validation)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: Polish & Documentation (Sequential)                    │
│ - Signing/deployment guide updates (Agent: Docs)                │
│ - Release checklist validation (Maintainer)                      │
│ - Final integration testing (QA Agent)                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Phase Breakdown

---

## PHASE 0: Project Assessment & Setup (Preparation - Days 1-2)

### Phase Objectives
- Establish baseline understanding of iOS app architecture
- Validate build system and tooling
- Confirm test suite health
- Document critical technical constraints
- Prepare context bundles for specialized agents

### Phase 0.1: Architecture Analysis & Baseline Assessment

**Step 1**: Read core application structure files
- `/home/user/openclaw/apps/ios/project.yml` - XCGen configuration, all targets, dependencies
- `/home/user/openclaw/apps/ios/Sources/OpenClawApp.swift` - App delegate, lifecycle, APNs setup
- `/home/user/openclaw/apps/ios/Sources/RootCanvas.swift` - Main UI composition
- `/home/user/openclaw/apps/ios/Sources/RootTabs.swift` - Tab navigation structure

**Step 2**: Map module organization
- List all module directories: `ls -la /home/user/openclaw/apps/ios/Sources/*/`
- Count files per module (Gateway: 13, Voice: 5, Camera: 1, Screen: 4, etc.)
- Identify module dependencies via imports

**Step 3**: Analyze gateway connection architecture
- Read `/home/user/openclaw/apps/ios/Sources/Gateway/GatewayConnectionController.swift` (core connection logic)
- Read `/home/user/openclaw/apps/ios/Sources/Gateway/GatewayDiscoveryModel.swift` (Bonjour discovery)
- Read `/home/user/openclaw/apps/ios/Sources/Model/NodeAppModel.swift` (primary app model, ~2000+ LOC)

**Step 4**: Document critical dependencies
- OpenClawKit package (shared between iOS/macOS)
- SwabbleKit (UI framework)
- Built-in frameworks: AVFoundation, CoreLocation, Speech, WatchConnectivity, UserNotifications

**Step 5**: Document known limitations and workarounds
- Background socket dead-state behavior
- Voice Wake/Talk microphone contention
- Foreground-only reliable operation
- Canvas/camera/screen/talk blocked in background
- APNs registration timing (only after gateway connection)

**Sub-Agent Specifications (Phase 0.1)**

| Agent | Type | Role | Input Files | Expected Output | Context Window |
|---|---|---|---|---|---|
| **Scout-iOS-Arch** | Exploration | Map architecture and identify patterns | `project.yml`, `OpenClawApp.swift`, `RootCanvas.swift`, module listing | Architecture diagram (Markdown), module dependency matrix, 2-3 key insights | 12 files, 4000 LOC |

**Success Criteria**
- Detailed architecture diagram showing module relationships
- Complete module inventory with LOC per module
- Clear map of Observable model hierarchy
- Documented entry points for each major feature (Camera, Voice, Location, etc.)

---

### Phase 0.2: Build System Validation

**Step 1**: Verify xcodegen setup
- Confirm `apps/ios/project.yml` is valid YAML
- Check all target definitions (OpenClaw, OpenClawShareExtension, OpenClawWatchApp, OpenClawWatchExtension, OpenClawTests)
- Verify all dependencies are resolvable

**Step 2**: Validate signing configuration
- Read `/home/user/openclaw/scripts/ios-configure-signing.sh` (signing orchestration)
- Read `/home/user/openclaw/scripts/ios-team-id.sh` (team detection)
- Understand team ID detection flow and bundle ID override mechanism
- Document Push Notifications capability requirements

**Step 3**: Verify build scripts
- Check pre-build scripts: SwiftFormat lint, SwiftLint
- Verify script paths and exit conditions
- Check file list inputs: `SwiftSources.input.xcfilelist`
- Confirm code signing identity settings

**Step 4**: Check npm integration
- Review iOS npm scripts: `ios:build`, `ios:gen`, `ios:open`, `ios:run`
- Understand command chaining and simulator selection
- Document environment variables: `IOS_DEST`, `IOS_SIM`

**Step 5**: Review entitlements and Info.plist
- `/home/user/openclaw/apps/ios/Sources/OpenClaw.entitlements` - Capabilities and permissions
- `/home/user/openclaw/apps/ios/Sources/Info.plist` - Configuration properties
- Document required permissions: Camera, Location, Microphone, Contacts, Calendar, Photos, Local Network

**Sub-Agent Specifications (Phase 0.2)**

| Agent | Type | Role | Input Files | Expected Output | Context Window |
|---|---|---|---|---|---|
| **BuildEngineer-iOS** | Build/Config | Validate and document build system | `project.yml`, signing scripts, `Info.plist`, entitlements, npm scripts | Build system validation report, signing flow diagram, known gotchas | 8 files, 2500 LOC |

**Success Criteria**
- xcodegen project generation tested successfully
- Signing configuration understood and documentable
- Pre-build script requirements clear
- All target dependencies resolvable
- Environment setup documented

---

### Phase 0.3: Test Suite Baseline

**Step 1**: Inventory test files
- List all test files: `find /home/user/openclaw/apps/ios/Tests -name "*.swift"`
- Categorize by feature: Gateway (5 tests), VoiceWake (4 tests), Camera (2 tests), Screen (2 tests), etc.
- Count total test count (15+ test files identified)

**Step 2**: Analyze test infrastructure
- Check test target configuration in `project.yml`
- Verify test dependencies (OpenClaw target, SwabbleKit, AppIntents)
- Look for test utilities and mocks

**Step 3**: Run baseline test suite
- Execute `xcodebuild -project OpenClaw.xcodeproj -scheme OpenClaw -configuration Debug test`
- Document pass/fail status
- Note any flaky tests

**Step 4**: Document test coverage gaps
- Identify untested modules (Media, EventKit, Capabilities)
- Note missing integration tests
- Document smoke test vs unit test distribution

**Step 5**: Establish test baseline metrics
- Line count per test file
- Mock/fixture inventory
- Protocol coverage

**Sub-Agent Specifications (Phase 0.3)**

| Agent | Type | Role | Input Files | Expected Output | Context Window |
|---|---|---|---|---|---|
| **TestEngineer-iOS** | Testing | Baseline test suite health | All test files, `project.yml`, fixtures | Test inventory report, baseline metrics, coverage gaps | 15 files, 3500 LOC |

**Success Criteria**
- All tests pass (or document known failures)
- Test coverage map created
- Flaky test behaviors documented
- Test infrastructure limitations identified
- Baseline metrics established

---

### Phase 0.4: Documentation & Constraint Capture

**Step 1**: Compile critical constraints
- iOS 18.0 minimum deployment target
- Swift 6.0 strict concurrency requirement
- Foreground-only reliable operation
- Background socket unreliability
- Voice/Talk microphone contention

**Step 2**: Document current limitations
- Background command blocking
- Voice Wake/Talk arbitration needs
- Location polling constraints
- APNs registration timing

**Step 3**: Create context bundles for specialized agents
- Gateway module context bundle (13 files, all Gateway/*.swift)
- Voice module context bundle (5 files, all Voice/*.swift)
- Camera module context bundle (Camera/, minimal context)
- Model layer context bundle (Model/*.swift, key entry points)

**Step 4**: Create reference documents
- Module dependency graph (Markdown)
- Feature command matrix (which commands work in background?)
- Gateway connection state machine (simplified flow)

**Success Criteria**
- Critical constraints documented and accessible
- Context bundles prepared for Phase 1 agents
- Reference documents created
- All baseline information captured

---

## PHASE 1: Core Stability Work (Days 3-10)

### Phase Objectives
- Harden background socket reconnection behavior
- Improve scene transition handling
- Reduce dead-socket states
- Implement voice/audio access coordination
- Stabilize location-based automations

### Phase 1.A: Background Socket & Reconnection Hardening

This work addresses the **most critical limitation**: background socket dead states that degrade user experience when the app is backgrounded/foregrounded.

#### Phase 1.A.1: Gateway Reconnection Recovery Enhancement

**Step 1**: Understand current reconnection flow
- Read `GatewayConnectionController.swift` - Connection state machine
- Read `GatewayHealthMonitor.swift` - Health checking logic
- Read `NodeAppModel.swift` (search for "reconnect" patterns) - App-level coordination
- Identify all reconnection triggers: manual user action, background wake, push notifications, scene resume

**Step 2**: Diagnose dead-socket scenarios
- Create test fixture for background->foreground transition
- Simulate network disruption during background period
- Document current recovery behavior vs. expected behavior
- Identify socket state not being properly cleaned on transition

**Step 3**: Implement socket cleanup on scene phase change
- Add explicit socket close/cleanup when transitioning to background
- Implement graceful re-establishment on foreground transition
- Prevent orphaned socket handles
- Add logging for socket lifecycle events

**Step 4**: Enhance reconnection retry logic
- Implement exponential backoff with jitter (avoid thundering herd)
- Set maximum retry attempts before manual intervention required
- Log retry attempts with timestamp and attempt count
- Add metrics for success rate

**Step 5**: Improve health monitoring
- Implement regular heartbeat pings to detect dead sockets early
- Add TCP state validation before attempting command dispatch
- Implement proactive reconnect before socket death detected
- Document health monitor metrics

**Step 6**: Test reconnection under various conditions
- Background wake via push notification
- Background wake via location event
- Manual foreground return
- Network change during background
- Prolonged background period (> 5 minutes)

**Sub-Agent Specifications (Phase 1.A.1)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-A1-Reconnect** | Feature | Implement socket reconnection hardening | `GatewayConnectionController.swift`, `GatewayHealthMonitor.swift`, `NodeAppModel.swift`, relevant test files | Updated connection controller with improved reconnection, test cases, documentation | Code editing, Swift knowledge | 10 files, 3000 LOC |

**Success Criteria**
- [ ] Dead-socket states eliminated in foreground->background->foreground cycle
- [ ] Reconnection success rate > 95% under normal conditions
- [ ] Exponential backoff implemented with jitter
- [ ] Heartbeat mechanism prevents stale socket usage
- [ ] Test coverage for reconnection scenarios (minimum 5 test cases)
- [ ] Documentation updated with socket lifecycle guarantees

---

#### Phase 1.A.2: Scene Transition Stability

**Step 1**: Understand scene phase lifecycle
- Review `OpenClawApp.swift` for scene phase observation
- Check for any `.onReceive(scenePhase)` handlers
- Document app state during transitions: `.active` -> `.inactive` -> `.background` -> `.inactive` -> `.active`

**Step 2**: Identify state inconsistencies during transitions
- Check if gateway controller pauses during `.inactive`
- Verify that voice wake is properly suspended/resumed
- Check if camera/screen recording state is saved
- Document any race conditions during transition

**Step 3**: Implement transition guards
- Add explicit state checkpoint before background transition
- Persist minimal required state (connection status, in-progress operations)
- Implement state restoration on foreground return
- Add transition logging for debugging

**Step 4**: Handle in-flight operations
- Document what operations are in-flight when transition occurs
- Implement cancellation of time-sensitive background operations
- Ensure user is notified if foreground operation interrupted
- Implement graceful resume of non-destructive operations

**Step 5**: Test transition scenarios
- Rapid background/foreground cycling
- Transition with active voice wake
- Transition with in-flight command
- Transition with active location tracking
- Home button press vs. swipe-up dismissal

**Sub-Agent Specifications (Phase 1.A.2)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-A2-Transitions** | Feature | Stabilize scene transitions | `OpenClawApp.swift`, `NodeAppModel.swift`, `VoiceWakeManager.swift`, relevant state managers | Transition guard implementation, state persistence layer, test cases | Code editing, Swift concurrency | 12 files, 3500 LOC |

**Success Criteria**
- [ ] No state corruption during rapid transitions
- [ ] Voice wake properly suspended/resumed
- [ ] In-flight operations handled gracefully
- [ ] Transition logging aids debugging
- [ ] Test coverage for 5+ transition scenarios
- [ ] Dead socket counts reduced by 80%+ in practice

---

### Phase 1.B: Voice & Audio Improvements

#### Phase 1.B.1: Microphone Access Coordination

**Step 1**: Understand current microphone usage
- Read `VoiceWakeManager.swift` - Voice wake implementation
- Read `TalkModeManager.swift` - Talk feature implementation
- Identify microphone access patterns: exclusive vs. shared
- Document current permission request flow

**Step 2**: Analyze microphone contention scenarios
- Identify conflict when both Voice Wake and Talk active
- Document audio session configuration
- Check for missing audio session category setup
- Identify permission flow gaps

**Step 3**: Implement microphone access arbitration
- Add mutual exclusion for exclusive microphone access
- Implement Talk pausing Voice Wake during active session
- Add user-facing indicator for microphone state
- Implement state machine for microphone lifecycle

**Step 4**: Enhance audio session management
- Ensure proper audio session category selection (record, default, etc.)
- Handle audio interruptions (incoming call, alarm, etc.)
- Implement audio focus management
- Add debugging for audio state transitions

**Step 5**: Test microphone coordination
- Voice Wake active, user taps Talk
- Talk session ends, Voice Wake resumes
- Audio interruption during active Talk
- Audio interruption during Voice Wake
- Rapid toggle between Voice Wake and Talk

**Sub-Agent Specifications (Phase 1.B.1)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-B1-Microphone** | Feature | Implement microphone arbitration | `VoiceWakeManager.swift`, `TalkModeManager.swift`, audio permission utilities | Microphone access coordinator, state machine, test cases | Code editing, Audio frameworks | 8 files, 2500 LOC |

**Success Criteria**
- [ ] Voice Wake and Talk never both access microphone simultaneously
- [ ] User clearly sees which audio feature is active
- [ ] Audio interruptions handled gracefully
- [ ] Audio session properly configured for each mode
- [ ] Test coverage for contention scenarios (minimum 6 test cases)

---

#### Phase 1.B.2: Voice Wake vs Talk Arbitration

**Step 1**: Understand current arbitration
- Read `VoiceWakeManager.swift` - Activation, command extraction, gateway dispatch
- Read `TalkModeManager.swift` - UI, audio playback, speech input
- Identify current priority system (if any)
- Document user expectations vs. current behavior

**Step 2**: Implement clear activation precedence
- Define priority: Talk > Voice Wake (user explicit interaction > background listening)
- Implement Talk activation suppressing Voice Wake
- Implement Voice Wake resumption after Talk ends
- Add visual/audio feedback for mode switches

**Step 3**: Enhance user experience
- Clear indication when Voice Wake is suspended for Talk
- Notification when Voice Wake resumes
- Option to quickly exit Talk and return to Voice Wake
- Documentation of expected behavior

**Step 4**: Test arbitration scenarios
- User talks while Voice Wake active
- Voice Wake triggers while Talk setting up (race condition)
- Rapid Talk start/stop cycles
- Voice Wake activation during Talk error recovery
- Complex multi-turn interactions

**Sub-Agent Specifications (Phase 1.B.2)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-B2-VoiceArbitration** | Feature | Implement Voice Wake/Talk arbitration | `VoiceWakeManager.swift`, `TalkModeManager.swift`, UI components | Arbitration state machine, UX improvements, test cases | Code editing, Swift UI | 10 files, 3000 LOC |

**Success Criteria**
- [ ] Clear, predictable Voice Wake/Talk interaction
- [ ] No missed Voice Wake activations due to Talk
- [ ] User always knows which mode is active
- [ ] 8+ test cases for arbitration scenarios
- [ ] Documentation of expected behavior

---

### Phase 1.C: Location & Automation Hardening

#### Phase 1.C.1: Geofence Trigger Reliability

**Step 1**: Understand current location implementation
- Read `Sources/Location/` module files
- Understand geofence setup and event handling
- Review background location capability requirements
- Document current reliability issues

**Step 2**: Validate geofence configuration
- Check CLLocationManager setup
- Verify geofence regions are properly created
- Validate entry/exit event handling
- Test on real device (simulator behavior differs significantly)

**Step 3**: Implement geofence state persistence
- Store geofence boundaries persistently
- Recover geofence state on app launch
- Handle maximum region limit (iOS allows ~20 regions)
- Implement region priority system

**Step 4**: Enhance event reliability
- Implement duplicate event suppression
- Add debouncing for rapid entry/exit
- Improve timestamp accuracy
- Add detailed event logging

**Step 5**: Test geofence scenarios
- Cross single geofence boundary
- Overlapping geofence regions
- Geofence at app launch (in-region state)
- Geofence boundary oscillation (user walking back/forth)
- Maximum region limit handling
- Background app state during geofence trigger

**Sub-Agent Specifications (Phase 1.C.1)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-C1-Geofence** | Feature | Harden geofence trigger reliability | Location module files, `NodeAppModel.swift` location handlers, test fixtures | Enhanced geofence handling, event reliability improvements, test cases | Code editing, CoreLocation | 10 files, 2800 LOC |

**Success Criteria**
- [ ] Geofence entry/exit events delivered reliably (>99% on real device)
- [ ] No duplicate events in normal scenarios
- [ ] State recovery on app launch verified
- [ ] 7+ test cases for geofence scenarios
- [ ] Real device testing completed (not just simulator)

---

#### Phase 1.C.2: Background Location State Management

**Step 1**: Understand location permissions and capabilities
- Review `NSLocationAlwaysAndWhenInUseUsageDescription` requirement
- Check background location mode setup in `project.yml`
- Verify "Always" permission grant flow
- Document battery impact expectations

**Step 2**: Implement location state machine
- Document desired states: stopped, when-in-use, always
- Implement state transitions
- Add permission change detection
- Implement recovery when permission revoked

**Step 3**: Add power management
- Implement location accuracy tuning (reduce unnecessary updates)
- Add frequency tuning based on app state
- Monitor battery impact
- Implement user-configurable update intervals

**Step 4**: Enhance notification relay
- Ensure location events reach gateway even when app backgrounded
- Handle notification payload limits
- Implement fallback if push notification unavailable
- Add event queuing for offline scenarios

**Step 5**: Test location state management
- Grant/deny/revoke location permissions
- Transition between when-in-use and always
- Background location updates during app suspension
- Prolonged background location monitoring (1+ hour)
- Location service system toggle

**Sub-Agent Specifications (Phase 1.C.2)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-C2-LocationState** | Feature | Implement location state management | Location module, `NodeAppModel.swift`, settings UI, tests | Location state machine, permission handling, battery optimization, test cases | Code editing, CoreLocation | 10 files, 2800 LOC |

**Success Criteria**
- [ ] Location state machine well-defined and tested
- [ ] Permission changes handled gracefully
- [ ] Battery impact acceptable (<5% increase in normal monitoring)
- [ ] Location events reach gateway reliably when backgrounded
- [ ] 8+ test cases for location state scenarios

---

## PHASE 2: Feature Enhancement & Testing (Days 11-18)

### Phase Objectives
- Enhance foreground command reliability
- Harden Watch app connectivity
- Improve Share extension robustness
- Expand integration test coverage
- Validate all features work correctly

### Phase 2.A: Foreground Command Surface Improvements

**Step 1**: Audit all supported commands
- Document gateway commands: camera snap/clip, canvas operations, screen record, location, contacts, calendar, reminders, photos, motion, notifications
- Verify each command works in foreground
- Identify any command failures or edge cases
- Document expected behavior vs. actual

**Step 2**: Enhance camera capture
- Test snap/clip capture in various lighting conditions
- Verify frame rate consistency in clip capture
- Test concurrent access (multiple clips)
- Implement proper error handling for camera unavailability

**Step 3**: Improve canvas reliability
- Test canvas navigation and interaction
- Verify snapshot capture works reliably
- Test canvas timeout recovery
- Implement better error messages for canvas failures

**Step 4**: Harden screen recording
- Test screen recording start/stop cycles
- Verify frame rates and quality settings
- Test simultaneous recording + other operations
- Implement safe cleanup on errors

**Step 5**: Validate device query commands
- Test location accuracy and freshness
- Verify contact/calendar/reminders queries return expected data
- Test permission handling during queries
- Implement caching where appropriate

**Sub-Agent Specifications (Phase 2.A)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-D-Commands** | Feature | Enhance command reliability | All command handler modules, `NodeAppModel.swift`, command tests | Enhanced error handling, reliability improvements, test cases | Code editing, Swift | 15 files, 4000 LOC |

**Success Criteria**
- [ ] All documented commands work reliably in foreground
- [ ] Error messages are user-friendly and actionable
- [ ] Commands time out gracefully
- [ ] 15+ integration test cases added
- [ ] Command reliability > 99%

---

### Phase 2.B: Watch App Hardening

**Step 1**: Understand WatchConnectivity protocol
- Review `WatchApp/` and `WatchExtension/` structure
- Check `WatchConnectivity` usage in main app
- Understand current data sync mechanism
- Document prompt action mirroring

**Step 2**: Harden connectivity
- Improve reliability of Watch<->iPhone communication
- Handle Watch unavailability gracefully
- Implement message queuing if needed
- Test with Watch simulator and real Watch if available

**Step 3**: Improve prompt action handling
- Test prompt action delivery from Watch to iPhone
- Verify response relay back to Watch
- Handle concurrent prompt actions
- Implement timeout for stale actions

**Step 4**: Enhance Watch UI
- Test all Watch app screens
- Verify proper state updates
- Test on multiple Watch device types (if possible)
- Implement offline fallback UI

**Step 5**: Test Watch integration
- iPhone and Watch in background
- iPhone backgrounded while Watch active
- Watch app crashes and recovery
- Network unavailability

**Sub-Agent Specifications (Phase 2.B)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-E-Watch** | Feature | Harden Watch app | `WatchApp/`, `WatchExtension/`, WatchConnectivity integration, tests | Enhanced WatchConnectivity, reliability improvements, test cases | Code editing, WatchKit | 12 files, 3000 LOC |

**Success Criteria**
- [ ] Watch<->iPhone communication reliable > 99%
- [ ] Prompt actions delivered correctly
- [ ] Watch app offline handling tested
- [ ] 10+ Watch integration test cases
- [ ] Works with Watch simulator and real Watch (if available)

---

### Phase 2.C: Share Extension Robustness

**Step 1**: Understand Share extension
- Review `ShareExtension/ShareViewController.swift`
- Understand deep link forwarding mechanism
- Check shared App Groups configuration
- Document current limitations

**Step 2**: Enhance memory management
- Test with large image selections (10+ photos)
- Test with large video file
- Verify memory cleanup after share
- Implement progress feedback for large transfers

**Step 3**: Improve error handling
- Test sharing when gateway unavailable
- Test sharing with invalid content
- Implement graceful error messaging
- Test timeout scenarios

**Step 4**: Test various share scenarios
- Single item vs. multiple items
- Text vs. images vs. video
- Share during app background
- Share when not paired with gateway
- Share with network unavailability

**Step 5**: Validate deep link routing
- Verify deep links reach correct destination in gateway
- Test with various URL schemes
- Test URL encoding edge cases
- Implement deep link logging

**Sub-Agent Specifications (Phase 2.C)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **DevAgent-F-ShareExt** | Feature | Improve Share extension | `ShareExtension/`, deep link handlers, extension tests | Enhanced error handling, memory management, test cases | Code editing, App Extensions | 8 files, 2000 LOC |

**Success Criteria**
- [ ] Share extension handles large content without crashing
- [ ] Deep links route correctly
- [ ] Error messages are clear
- [ ] 8+ Share extension test cases
- [ ] Memory usage stays <50MB during large transfers

---

### Phase 2.D: Integration Test Suite Expansion

**Step 1**: Analyze test coverage gaps
- Identify untested modules (Media, EventKit, Capabilities, Settings)
- Review existing test patterns
- Document testing infrastructure

**Step 2**: Expand gateway integration tests
- Test pairing flow end-to-end (setup code entry, approval)
- Test disconnection and reconnection scenarios
- Test TLS certificate validation
- Test multiple connection endpoints

**Step 3**: Add command integration tests
- Test command dispatch and response
- Test concurrent commands
- Test command timeouts
- Test background command blocking

**Step 4**: Add UI smoke tests
- SwiftUI view rendering tests
- Tab switching tests
- Settings screen tests
- Onboarding flow tests

**Step 5**: Implement test metrics
- Track test coverage percentage
- Document flaky tests
- Identify test performance issues
- Set baseline for regression testing

**Sub-Agent Specifications (Phase 2.D)**

| Agent | Type | Role | Input Files | Expected Output | Skills | Context Size |
|---|---|---|---|---|---|---|
| **TestAgent-Integration** | Testing | Expand integration test suite | All app modules, existing test patterns, test utilities | 30+ new integration tests, coverage report, test metrics | Code editing, testing frameworks | 20 files, 5000 LOC |

**Success Criteria**
- [ ] Test coverage > 70% for core modules
- [ ] 30+ new integration test cases
- [ ] All major features have integration tests
- [ ] Flaky tests identified and documented
- [ ] CI integration ready

---

## PHASE 3: Polish & Documentation (Days 19-21)

### Phase Objectives
- Update deployment and signing guides
- Create release checklist
- Finalize documentation
- Prepare for stable release

### Phase 3.1: Documentation Updates

**Step 1**: Update signing guide
- Verify step-by-step signing instructions are accurate
- Document team ID detection process
- Document bundle ID override for personal teams
- Add troubleshooting for common signing issues

**Step 2**: Create deployment checklist
- Build and sign procedures
- Testing before release
- Verification steps
- Release notes preparation

**Step 3**: Document known limitations
- Background mode constraints
- Voice Wake/Talk behavior
- Location polling recommendations
- Performance considerations

**Step 4**: Create debugging guides
- Logging subsystem reference
- Connection troubleshooting
- Permission verification
- Simulator vs. real device differences

**Success Criteria**
- [ ] Deployment guide is complete and verified
- [ ] All critical constraints documented
- [ ] Troubleshooting guide addresses common issues
- [ ] No deprecated information in docs

---

### Phase 3.2: Release Preparation

**Step 1**: Run full test suite
- Execute all unit tests
- Run integration tests
- Perform smoke testing on real device
- Test all major workflows

**Step 2**: Validate code quality
- Run SwiftLint and SwiftFormat
- Check for any warnings
- Verify no deprecated API usage
- Audit memory management

**Step 3**: Prepare release notes
- Document all enhancements from Phase 1-2
- Note any breaking changes
- List known issues and workarounds
- Provide upgrade guidance

**Step 4**: Create release checklist
- All tests passing
- Code quality verified
- Documentation updated
- Release notes prepared
- Version numbers updated

**Success Criteria**
- [ ] All tests passing
- [ ] Code quality > A grade
- [ ] Release notes complete
- [ ] Release checklist signed off

---

## Cross-Phase Coordination

### Data Flow Between Phases

```
Phase 0 Output (Baseline Assessment)
├─ Architecture diagram
├─ Module dependency map
├─ Build system documentation
├─ Test coverage baseline
└─ Critical constraints document
    ↓
Phase 1 Input (Specialized agents receive focused context bundles)
├─ Agent A1: reconnection module context
├─ Agent A2: scene transition handlers context
├─ Agent B1: microphone/audio context
├─ Agent B2: voice feature context
├─ Agent C1: location/geofence context
└─ Agent C2: location state context
    ↓
Phase 1 Outputs (Stability improvements)
├─ Socket reconnection implementation
├─ Scene transition guards
├─ Microphone arbitration
├─ Voice Wake/Talk sequencing
├─ Geofence reliability
└─ Location state machine
    ↓
Phase 2 Input (Enhanced app modules)
├─ Test suite expansion input
├─ Command reliability test cases
├─ Watch integration context
└─ Share extension context
    ↓
Phase 2 Outputs (Feature enhancements)
├─ Enhanced command reliability
├─ Watch app hardening
├─ Share extension robustness
└─ Expanded test coverage (30+ tests)
    ↓
Phase 3 Input (Ready for release)
├─ All implementations from Phase 1-2
├─ Complete test suite
├─ Code quality metrics
└─ Documentation baseline
    ↓
Phase 3 Outputs (Stable release ready)
├─ Updated documentation
├─ Release notes
├─ Release checklist (signed off)
└─ Stable version ready for deployment
```

### Parallel Execution Strategy

**Phase 1 Parallel Tracks** (can execute in parallel):
- **Track A** (Socket & Scene): Can run independently
- **Track B** (Voice/Audio): Can run independently
- **Track C** (Location): Can run independently
- **Sync point**: All Phase 1 tests pass before Phase 2 starts

**Phase 2 Parallel Tracks** (can execute in parallel):
- **Track A** (Commands): Can run independently
- **Track B** (Watch): Can run independently
- **Track C** (ShareExt): Can run independently
- **Track D** (Integration Tests): Can reference Tracks A-C work
- **Sync point**: All Phase 2 implementations complete before Phase 3 starts

---

## Agent Specifications Summary

### Complete Agent Roster

| Phase | Agent | Type | Specialization | Files | LOC | Duration |
|---|---|---|---|---|---|---|
| **0** | Scout-iOS-Arch | Exploration | Architecture baseline | 12 | 4000 | 1 day |
| **0** | BuildEngineer-iOS | Config | Build system validation | 8 | 2500 | 0.5 days |
| **0** | TestEngineer-iOS | Testing | Test baseline | 15 | 3500 | 0.5 days |
| **1.A** | DevAgent-A1-Reconnect | Feature | Socket reconnection | 10 | 3000 | 2 days |
| **1.A** | DevAgent-A2-Transitions | Feature | Scene transitions | 12 | 3500 | 2 days |
| **1.B** | DevAgent-B1-Microphone | Feature | Mic arbitration | 8 | 2500 | 1.5 days |
| **1.B** | DevAgent-B2-VoiceArbitration | Feature | Voice/Talk arbitration | 10 | 3000 | 1.5 days |
| **1.C** | DevAgent-C1-Geofence | Feature | Geofence reliability | 10 | 2800 | 2 days |
| **1.C** | DevAgent-C2-LocationState | Feature | Location state mgmt | 10 | 2800 | 2 days |
| **2.A** | DevAgent-D-Commands | Feature | Command reliability | 15 | 4000 | 2 days |
| **2.B** | DevAgent-E-Watch | Feature | Watch hardening | 12 | 3000 | 1.5 days |
| **2.C** | DevAgent-F-ShareExt | Feature | Share extension | 8 | 2000 | 1 day |
| **2.D** | TestAgent-Integration | Testing | Integration tests | 20 | 5000 | 2 days |
| **3** | DocsAgent-Release | Docs | Release docs | 5 | 1000 | 1 day |

**Total Estimated Duration**: 21 days (5 weeks) with full parallel execution

---

## Critical Dependencies & Blocking Issues

### Hard Dependencies
1. **xcodegen installation**: Required for any build work
2. **Xcode 16.0+**: Required for Swift 6.0 compilation
3. **OpenClawKit package**: Must be available for all builds
4. **SwiftLint/SwiftFormat**: Required for pre-build checks

### Known Blockers
1. **Real device testing**: Some features (location, camera) behave differently on simulator
2. **Push Notifications setup**: Requires Apple Developer account with Push capability enabled
3. **Gateway availability**: Some integration tests require running gateway
4. **Watch device**: Watch app testing requires watchOS device or simulator

### Risk Mitigation
- Document simulator limitations explicitly
- Provide fallback testing procedures
- Use fixtures for gateway communication tests
- Create mock APNs environment for testing

---

## Success Criteria & Verification

### Phase 0 Success Criteria
- [ ] Architecture diagram complete and accurate
- [ ] All modules mapped with dependencies
- [ ] Build system fully validated
- [ ] Test suite runs without errors
- [ ] Critical constraints documented

### Phase 1 Success Criteria
- [ ] Dead-socket rate reduced by 80%+
- [ ] Scene transitions handle state properly
- [ ] Microphone arbitration prevents conflicts
- [ ] Voice Wake/Talk interaction predictable
- [ ] Geofence triggers reliable on real device
- [ ] Location state machine passes all tests
- [ ] All Phase 1 tests passing (target: >90% pass rate)

### Phase 2 Success Criteria
- [ ] All foreground commands work reliably (>99% success)
- [ ] Watch app connectivity stable (>99% message delivery)
- [ ] Share extension handles edge cases
- [ ] 30+ new integration tests added
- [ ] Test coverage > 70% for core modules
- [ ] All Phase 2 tests passing

### Phase 3 Success Criteria
- [ ] Documentation complete and verified
- [ ] Release notes prepared
- [ ] All tests passing
- [ ] Code quality A grade
- [ ] Ready for stable release

---

## Resource Requirements

### Developer Resources
- **Architecture Scout**: 1 person, 1 day (Phase 0)
- **Build Engineer**: 1 person, 0.5 days (Phase 0)
- **Test Engineer**: 1 person, 0.5 days (Phase 0)
- **Feature Developers**: 6-8 people in parallel (Phase 1-2)
- **Integration Test Engineer**: 1 person, 2 days (Phase 2)
- **Documentation Engineer**: 1 person, 1 day (Phase 3)

### Infrastructure Requirements
- Mac development machine with Xcode 16.0+
- iOS real device for testing (iPhone 18.0+)
- Apple Developer account with Push Notifications enabled
- Git repository with main branch access
- Optional: watchOS device or simulator

### External Dependencies
- OpenClawKit package (must be available)
- SwabbleKit UI framework
- Apple frameworks: AVFoundation, CoreLocation, Speech, WatchConnectivity, UserNotifications
- Build tools: xcodegen, SwiftLint, SwiftFormat

---

## Context Optimization in Practice

### Agent Context Bundle Examples

#### Example 1: DevAgent-A1-Reconnect Context Bundle
```
Files to provide:
- /home/user/openclaw/apps/ios/Sources/Gateway/GatewayConnectionController.swift
- /home/user/openclaw/apps/ios/Sources/Gateway/GatewayHealthMonitor.swift
- /home/user/openclaw/apps/ios/Sources/Model/NodeAppModel.swift (lines containing "reconnect")
- /home/user/openclaw/apps/ios/Tests/GatewayConnectionControllerTests.swift
- /home/user/openclaw/apps/ios/Sources/Gateway/TCPProbe.swift
- /home/user/openclaw/apps/ios/project.yml (dependencies section)

Exclude:
- All Voice module files
- All Camera module files
- All UI view components
- All Settings code
- Watch extension code
```

#### Example 2: DevAgent-B1-Microphone Context Bundle
```
Files to provide:
- /home/user/openclaw/apps/ios/Sources/Voice/VoiceWakeManager.swift
- /home/user/openclaw/apps/ios/Sources/Voice/TalkModeManager.swift
- /home/user/openclaw/apps/ios/Sources/Voice/TalkOrbOverlay.swift (UI feedback only)
- /home/user/openclaw/apps/ios/Sources/Model/NodeAppModel.swift (voice-related sections)
- Audio framework documentation (system knowledge)

Exclude:
- Gateway connection code
- Camera/screen modules
- Location code
- Watch code
- Share extension code
```

#### Example 3: TestAgent-Integration Context Bundle
```
Files to provide:
- All existing test files (15 files, ~3500 LOC)
- Test utilities and fixtures
- /home/user/openclaw/apps/ios/project.yml (test target config)
- Sample integration test patterns from existing tests
- Mocking framework setup

Exclude:
- Detailed implementation of each feature
- Asset files
- Configuration files (unless relevant to testing)
```

---

## Risk Assessment & Mitigation

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Socket reconnection proves hard to fix | High | Medium | Spike investigation early, consider alternative architectures |
| Watch app unavailable for testing | Medium | Low | Use simulator, provide fallback testing procedure |
| Location behavior differs on simulator | Medium | High | Require real device testing, document clearly |
| Voice/Talk microphone issues deeper than expected | Medium | Medium | Create isolated test app if needed |
| Test coverage insufficient for regressions | Medium | Medium | Plan additional test development time |
| Push Notifications setup blocker | High | Medium | Document fallback non-APNs testing approach |

---

## Approval Checklist

- [ ] **Architecture Scout**: Phase 0.1 Architecture Analysis approved
- [ ] **Build Engineer**: Phase 0.2 Build System Validation approved
- [ ] **Test Engineer**: Phase 0.3 Test Suite Baseline approved
- [ ] **Feature Team Lead**: Phase 1 socket/scene/voice/location work approved
- [ ] **QA Lead**: Phase 2 testing expansion approved
- [ ] **Maintainer**: Phase 3 release preparation approved
- [ ] **Product Owner**: Overall plan timeline and scope approved

---

## Next Steps

1. **Immediate**: Review and approve this plan
2. **Day 1**: Assign Phase 0 agents and begin baseline assessment
3. **Day 2**: Complete Phase 0, review findings, approve Phase 1
4. **Days 3-10**: Execute Phase 1 work in parallel tracks
5. **Days 11-18**: Execute Phase 2 work in parallel tracks
6. **Days 19-21**: Execute Phase 3 release preparation

---

## Document History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-03-01 | Planning Agent | Initial comprehensive plan |

---

## Critical Files for Implementation

Based on this comprehensive plan, the following files are most critical for implementation:

1. **/home/user/openclaw/apps/ios/Sources/Model/NodeAppModel.swift** - Primary app model containing lifecycle, gateway connection, and command routing logic; will be modified across all phases
2. **/home/user/openclaw/apps/ios/Sources/Gateway/GatewayConnectionController.swift** - Gateway connection state machine; critical for Phase 1.A reconnection hardening
3. **/home/user/openclaw/apps/ios/project.yml** - Build configuration and target definitions; needed for build system understanding and potential swift package updates
4. **/home/user/openclaw/apps/ios/Sources/Voice/VoiceWakeManager.swift** - Voice Wake activation and command extraction; critical for Phase 1.B microphone arbitration
5. **/home/user/openclaw/apps/ios/Sources/Voice/TalkModeManager.swift** - Talk feature implementation; critical for Phase 1.B voice/talk arbitration

---

This comprehensive plan provides a structured framework for iOS development work with careful attention to context optimization, parallel execution, and measurable success criteria. The document is ready for review and approval before execution begins.