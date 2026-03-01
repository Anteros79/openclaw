# OpenClaw iOS App Documentation Summary

**Document Version:** 2026-03-01
**Status:** Super-Alpha / Internal Use Only
**Repository:** https://github.com/openclaw/openclaw
**iOS App Version:** 2026.2.21 (build 20260220)

---

## Executive Summary

OpenClaw iOS is a super-alpha, internally-focused iPhone app that connects to an OpenClaw Gateway as a `role: node`. The app enables voice-activated AI assistance with camera, screen, location, and media capabilities on iOS devices. Currently, there is **NO TestFlight distribution available** — builds are deployed locally/manually from source via Xcode.

### Key Facts
- **Deployment Target:** iOS 18.0+
- **Swift Version:** Swift 6.0 with strict concurrency
- **Current Version:** 2026.2.21 (build 20260220)
- **Primary Use Case:** Local device integration with OpenClaw Gateway
- **Architecture:** Multi-platform Swift framework with iOS app, Share Extension, and watchOS companion
- **Foreground-First Design:** Background socket handling is still being hardened

---

## Architecture Overview

### App Structure

The iOS app is organized into functional domains with 57 Swift source files across multiple subsystems:

```
Sources/
├── Camera/                 # Photo/video capture
├── Chat/                   # Chat UI components
├── Contacts/              # Contact access
├── Device/                # Device info & naming
├── EventKit/              # Calendar access
├── Gateway/               # Gateway connection & discovery
├── Location/              # Location services & geofencing
├── Media/                 # Photos library access
├── Motion/                # Motion/accelerometer data
├── Onboarding/            # Initial setup flows
├── Reminders/             # Reminders/calendar tasks
├── Screen/                # Canvas rendering via WebKit
├── Services/              # Background tasks & notifications
├── Settings/              # User preferences & configuration
├── Status/                # App status management
├── Voice/                 # Voice wake detection & speech
├── Calendar/              # Calendar-related features
├── Capabilities/          # Permission checking
├── Model/                 # Data models
├── Assets.xcassets/       # App icons & resources
```

### Targets & Outputs

1. **OpenClaw** (Main App)
   - Type: iOS Application
   - Minimum Deployment: iOS 18.0
   - Bundle ID: `ai.openclaw.ios`
   - Main capabilities: Gateway connection, voice wake, chat, media capture

2. **OpenClawShareExtension** (Share Extension)
   - Type: App Extension
   - Bundle ID: `ai.openclaw.ios.share`
   - Enables deep-link forwarding of shared content into gateway sessions

3. **OpenClawWatchApp & OpenClawWatchExtension** (watchOS Companion)
   - Minimum Deployment: watchOS 11.0
   - WatchConnectivity integration for companion functionality

4. **OpenClawTests** (Unit Tests)
   - Bundle ID: `ai.openclaw.ios.tests`
   - Comprehensive test coverage for all major systems

### Shared Dependencies

- **OpenClawKit** (Local framework at `apps/shared/OpenClawKit`)
  - Swift Tools: 6.2
  - Platforms: iOS 18.0+, macOS 15.0+
  - Products:
    - `OpenClawProtocol` - Protocol definitions & serialization
    - `OpenClawKit` - Core gateway communication & device capabilities
    - `OpenClawChatUI` - Chat UI components
  - External packages:
    - ElevenLabsKit (0.1.0) - Text-to-speech synthesis
    - Textual (0.3.1) - Rich text rendering

- **Swabble** (Local framework at `../../Swabble`)
  - Swift Tools: 6.2
  - Platforms: iOS 17.0+, macOS 15.0+
  - Purpose: Wake-word detection via Speech.framework
  - Products:
    - `SwabbleKit` - Wake-gate utilities for iOS/macOS

---

## Build & Deployment Setup

### Quick Build Steps

```bash
# 1. From repo root, install dependencies
pnpm install

# 2. Configure signing (auto-detects team or uses env vars)
./scripts/ios-configure-signing.sh

# 3. Generate Xcode project
cd apps/ios
xcodegen generate

# 4. Open and build in Xcode
open OpenClaw.xcodeproj
```

### npm Scripts

| Command | Purpose |
|---------|---------|
| `pnpm ios:gen` | Generate Xcode project only |
| `pnpm ios:open` | Generate + open Xcode.xcodeproj |
| `pnpm ios:build` | Generate + build for simulator |
| `pnpm ios:run` | Generate + build + boot simulator + launch app |

**Simulator Destination Default:** `iPhone 17` (customizable via `IOS_DEST` env var)

### Code Signing Configuration

**Default Signing Profile:** Manual Code Signing
- **Default Team ID:** `Y5PE65HELJ` (OpenClaw canonical team)
- **App Bundle ID:** `ai.openclaw.ios`
- **Share Extension Bundle ID:** `ai.openclaw.ios.share`
- **Signing Style:** Manual (uses CODE_SIGN_IDENTITY: "Apple Development")

#### Local Signing Overrides

For personal/local development, copy `LocalSigning.xcconfig.example` → `LocalSigning.xcconfig`:

```bash
OPENCLAW_CODE_SIGN_STYLE = Automatic
OPENCLAW_DEVELOPMENT_TEAM = YOUR_TEAM_ID
OPENCLAW_APP_BUNDLE_ID = ai.openclaw.ios.yourname
OPENCLAW_SHARE_BUNDLE_ID = ai.openclaw.ios.yourname.share
OPENCLAW_WATCH_APP_BUNDLE_ID = ai.openclaw.ios.yourname.watchkitapp
OPENCLAW_WATCH_EXTENSION_BUNDLE_ID = ai.openclaw.ios.yourname.watchkitapp.extension
```

The `ios-configure-signing.sh` script automatically generates `.local-signing.xcconfig` based on detected team IDs and environment variables:
- Prefers canonical OpenClaw team (`Y5PE65HELJ`)
- Falls back to first non-personal team
- Falls back to personal team if needed
- Can be overridden with `OPENCLAW_IOS_BUNDLE_SUFFIX` env var

### Xcode Project Generation

**Tool:** xcodegen (YAML-based project generation)
**Config File:** `apps/ios/project.yml`

Key configuration:
- Deployment Target: iOS 18.0
- Swift Version: 6.0
- Strict Concurrency: Enabled (`SWIFT_STRICT_CONCURRENCY: complete`)
- Pre-build scripts: SwiftFormat (lint) + SwiftLint
- Info.plist: Auto-generated from YAML definitions

---

## Key Dependencies & Requirements

### System Requirements
- **Xcode:** 16.0 or later
- **Swift:** 6.0+ with strict concurrency checking enabled
- **Node Runtime:** pnpm for dependency management
- **macOS Build Host:** Required for iOS development and signing
- **Build Tools:** xcodegen (generates .xcodeproj from project.yml)

### Code Quality Tools
- **swiftformat:** Code formatting (configured in root `.swiftformat`)
- **swiftlint:** Linting rules (configured in `.swiftlint.yml`)
- Both run as pre-build scripts during compilation

### Capabilities & Permissions

The app requests the following permissions via `Info.plist`:

| Permission | Use Case |
|-----------|----------|
| Camera | Photo/video capture when requested via gateway |
| Microphone | Voice wake detection & speech input |
| Speech Recognition | On-device speech recognition for voice wake |
| Location (When in Use) | Share location on-demand |
| Location (Always) | Background location events for automation |
| Local Network | Gateway discovery (Bonjour) |
| Remote Notifications | APNs push for wake/reconnect signals |
| Background Audio | Audio playback & recording in background |

### Entitlements

**APNs Environment:** Development (set in `Sources/OpenClaw.entitlements`)
- Debug builds register as APNs sandbox
- Release builds use production APNs
- Registration token sent to gateway only after connection (`push.apns.register`)
- Requires correct Push Notifications capability + provisioning profile

### Background Modes

- **Audio Mode:** Enabled (for voice input/output)
- **Remote Notifications:** Enabled (APNs)
- **Background Refresh:** Scheduled via `BGTaskSchedulerPermittedIdentifiers` (`ai.openclaw.ios.bgrefresh`)

---

## Gateway Connection & Communication

### Connection Flow

1. **Bonjour Discovery** (default)
   - Searches for `_openclaw-gw._tcp` services
   - Can be debugged via Settings → Gateway → Discovery Debug Logs

2. **Manual Configuration** (fallback)
   - Host + Port + TLS Fingerprint trust prompt
   - Settings → Gateway → Advanced

3. **Authentication**
   - Device pairing via setup code (`/pair` → `/pair approve` in Telegram)
   - Pairing state is stored locally
   - Auth errors intentionally pause reconnect loops (manual recovery required)

### Node Integration

The iOS app presents itself as a `role: node` to the gateway with these capabilities:

**Foreground Commands (Always Available):**
- Camera snap/clip capture
- Canvas present/navigate/eval/snapshot
- Screen record
- Location sharing
- Contacts query
- Calendar events
- Reminders
- Photos library access
- Motion/accelerometer data
- Local notifications

**Background Limitations:**
- `canvas.*`, `camera.*`, `screen.*`, and `talk.*` are **blocked in background**
- Socket suspension in background can cause dead-socket states
- Reconnect recovery is still being tuned
- Foreground-first: iOS can suspend sockets in background

### APNs Push Notifications

- Calls `registerForRemoteNotifications()` at app launch
- Token registration to gateway happens only after gateway connection
- Requires correct Push Notifications capability + provisioning
- Debug builds: APNs sandbox
- Release builds: APNs production
- If push capability or provisioning is wrong, APNs registration fails at runtime

---

## Onboarding & User Interface

### Initial Setup Flow

The iOS app uses a guided onboarding flow:

1. Gateway discovery or manual entry
2. Pairing authentication (requires gateway side `/pair approve`)
3. Permission requests (Camera, Microphone, Location, etc.)
4. Voice wake configuration

### Settings Panel

**Gateway Settings:**
- Connection status (Connected/Disconnected/Pairing/Error)
- Server address & remote address display
- Manual discovery logs inspection
- Advanced options (Manual host/port/TLS)

**Capabilities:**
- Permission verification for each requested feature

**Voice Wake:**
- Wake-word configuration
- Sensitivity tuning

---

## Testing & QA

### Test Organization

**Test Suite:** `apps/ios/Tests/` (Swift XCTest)

Sample test areas:
- Gateway connection & discovery
- Voice wake command extraction
- Keychain/credential storage
- Camera controller error handling
- Deep-link parsing
- Settings persistence
- Share extension integration
- Network helper functions

### Location Automation Testing

For location automation features:

1. Enable `Always` location permission
2. Background app and trigger movement (walk/drive)
3. Validate gateway receives location event
4. Confirm automation executes once (no duplicates)
5. Check thermal state & battery drain remain acceptable

**Pass Criteria:**
- Movement events delivered reliably for automation UX
- No location-driven reconnect spam loops
- App remains stable after repeated background/foreground transitions

### Debugging Workflow

1. **Regenerate project:**
   ```bash
   xcodegen generate
   ```

2. **Verify signing:**
   - Check selected team + bundle IDs in Xcode
   - Run `scripts/ios-configure-signing.sh` to detect team

3. **Check gateway pairing:**
   - Settings → Gateway
   - If pairing required: run `/pair approve` on Telegram

4. **Enable discovery logs:**
   - Settings → Gateway → Discovery Debug Logs

5. **Inspect console output:**
   - Filter Xcode logs for subsystem: `ai.openclaw.ios`
   - Also watch for: `GatewayDiag`, `APNs registration failed`

6. **Network debugging:**
   - Switch to manual host/port + TLS in Gateway Advanced settings

7. **Test background transitions:**
   - Reproduce in foreground first
   - Then background app and confirm reconnect on return

---

## Code Style & Quality Standards

### Swift Formatting & Linting

**SwiftFormat (pre-build):**
- Formats code according to `.swiftformat` (root level)
- Runs on all Swift source files before compilation
- Input file list: `SwiftSources.input.xcfilelist`

**SwiftLint (pre-build):**
- Linting rules in `apps/ios/.swiftlint.yml`
- Also runs before compilation

### Concurrency Standards

- **Strict Concurrency:** Enabled for all targets
- **Sendable Compliance:** Enforced by SWIFT_STRICT_CONCURRENCY flag
- Unsafe bridges use `@unchecked Sendable` where necessary

---

## Known Issues & Limitations

### Super-Alpha Disclaimers

- **Breaking Changes:** Expected during active development
- **UI/UX:** Onboarding flows and UI can change without migration guarantees
- **Stability:** Foreground-first; background reliability is still being hardened
- **Treat as Sensitive:** Permissions and background behavior still being hardened

### Technical Limitations

| Issue | Impact | Status |
|-------|--------|--------|
| Socket suspension in background | Dead-socket states after backgrounding | Being hardened |
| Background command blocking | `canvas.*`, `camera.*`, `screen.*`, `talk.*` disabled | By design |
| Voice Wake + Talk contention | Microphone conflict during active talk | By design (voice wake suppressed during talk) |
| APNs reliability | Depends on local team/provisioning alignment | Verify signing profile supports Push Notifications |
| Location tracking in background | Requires `Always` permission | By design for automation signals |

### In-Progress Workstreams

1. Automatic wake/reconnect hardening
2. Improving scene transition behavior (background → foreground)
3. Reducing dead-socket states
4. Tightening node/operator session reconnect coordination
5. Minimizing manual recovery steps after transient network failures

---

## CI/CD & Release Configuration

### Fastlane Setup (Beta Distribution)

**Tool:** fastlane (automation for App Store Connect)

**Setup Steps:**

1. Create App Store Connect API key:
   - App Store Connect → Users & Access → Keys → App Store Connect API
   - Download `.p8` file, note Issuer ID & Key ID

2. Configure `apps/ios/fastlane/.env` (git-ignored):
   ```bash
   ASC_KEY_ID=YOUR_KEY_ID
   ASC_ISSUER_ID=YOUR_ISSUER_ID
   ASC_KEY_PATH=/absolute/path/to/AuthKey_XXXXXXXXXX.p8
   IOS_DEVELOPMENT_TEAM=YOUR_TEAM_ID
   ```

3. Run beta lane:
   ```bash
   cd apps/ios
   fastlane beta
   ```

**Helper Script:** `scripts/ios-team-id.sh`
- Prints Apple Team ID
- Prefers canonical OpenClaw team (`Y5PE65HELJ`)
- Falls back to first non-personal team, then personal team

### CI/CD Integration

The GitHub Actions CI includes iOS in its conditional build matrix:
- Triggered by changes to `apps/ios/`, `apps/shared/`, or `Swabble/` directories
- Separate jobs maintain native app separation
- Conditional execution based on changed files

---

## Configuration Files Reference

### Key Files

| File | Purpose |
|------|---------|
| `project.yml` | xcodegen project definition (YAML) |
| `Signing.xcconfig` | Default signing configuration (canonical team) |
| `LocalSigning.xcconfig` | Personal local signing overrides (git-ignored) |
| `.local-signing.xcconfig` | Auto-generated signing config (git-ignored) |
| `Sources/Info.plist` | App metadata & capabilities |
| `Sources/OpenClaw.entitlements` | APNs & app entitlements |
| `SwiftSources.input.xcfilelist` | File list for pre-build scripts |
| `.swiftlint.yml` | Linting rules |
| `fastlane/SETUP.md` | Beta distribution automation guide |

### Important Paths

- **Main App:** `/home/user/openclaw/apps/ios/`
- **Shared Kit:** `/home/user/openclaw/apps/shared/OpenClawKit/`
- **Swabble:** `/home/user/openclaw/Swabble/`
- **Build Scripts:** `/home/user/openclaw/scripts/ios-*.sh`

---

## Development Workflow Summary

### Initial Setup

```bash
# 1. Clone and install
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install

# 2. Generate and open project
pnpm ios:open

# 3. In Xcode:
#    - Select scheme: "OpenClaw"
#    - Select destination: Connected iPhone or simulator
#    - Build & Run (Cmd+R)
```

### Daily Development

```bash
# Build for simulator
pnpm ios:build

# Or open in Xcode for interactive development
pnpm ios:open

# Run unit tests
xcodebuild test -project apps/ios/OpenClaw.xcodeproj -scheme OpenClaw

# Manual format check
swiftformat --lint --config .swiftformat apps/ios/Sources
swiftlint lint --config apps/ios/.swiftlint.yml
```

### Code Changes

- Swift code is automatically formatted/linted before build
- Pre-build scripts enforce swiftformat + swiftlint
- No changes required to trigger formatting

---

## Recent Updates & Changes

### Version: 2026.2.21 (Build 20260220)

**Active Development Focus:**
- Automatic wake/reconnect hardening
- Improving scene transition behavior (background → foreground)
- Reducing dead-socket states
- Tightening node/operator session reconnect coordination
- Minimizing manual recovery steps after transient network failures

**Recent Fixes (Feb 2026):**
- Swift protocol generation stabilization
- Test flakiness reduction for device integration
- Telegram integration improvements (streaming preview per assistant block)

---

## Useful Resources

- **Main README:** https://github.com/openclaw/openclaw/blob/main/README.md
- **iOS README:** https://github.com/openclaw/openclaw/blob/main/apps/ios/README.md
- **Fastlane Setup:** https://github.com/openclaw/openclaw/blob/main/apps/ios/fastlane/SETUP.md
- **OpenClaw Docs:** https://docs.openclaw.ai
- **Discord Community:** https://discord.gg/clawd

---

## Summary Table: Build Environment

| Component | Version/Requirement | Notes |
|-----------|-------------------|-------|
| Xcode | 16.0+ | Code signing required |
| Swift | 6.0 | Strict concurrency enabled |
| iOS Target | 18.0+ | Deployment minimum |
| watchOS Target | 11.0+ | Companion app |
| pnpm | Latest | Package manager |
| xcodegen | Latest | Project generation |
| swiftformat | Latest | Code formatting |
| swiftlint | Latest | Code linting |

---

**Document Created:** 2026-03-01
**Last Verified:** Main branch (2026-02-26+)

Disclaimer: This documentation reflects the super-alpha state of the iOS app as of February 2026. Features, APIs, and configurations are subject to rapid change. Always refer to the latest source code and official documentation at https://docs.openclaw.ai for current information.
