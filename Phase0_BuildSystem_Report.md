# OpenClaw iOS -- Build System Validation Report (Phase 0.2)

## 1. XCGen Configuration

**File:** `/home/user/openclaw/apps/ios/project.yml`

**Project-Level Settings:**

| Setting | Value |
|---|---|
| Project Name | `OpenClaw` |
| Bundle ID Prefix | `ai.openclaw` |
| iOS Deployment Target | `18.0` |
| Xcode Version | `16.0` |
| Swift Version (base) | `6.0` |

### 1.1 Target Configuration Table

| Target | Type | Platform | Deploy Target | Swift Version | Strict Concurrency | Sources Path |
|---|---|---|---|---|---|---|
| `OpenClaw` | `application` | iOS | 18.0 (inherited) | 6.0 | `complete` | `Sources` |
| `OpenClawShareExtension` | `app-extension` | iOS | 18.0 (inherited) | 6.0 | `complete` | `ShareExtension` |
| `OpenClawWatchApp` | `application.watchapp2` | watchOS | **11.0** | inherited (6.0) | inherited | `WatchApp` |
| `OpenClawWatchExtension` | `watchkit2-extension` | watchOS | **11.0** | inherited (6.0) | inherited | `WatchExtension/Sources` |
| `OpenClawTests` | `bundle.unit-test` | iOS | 18.0 (inherited) | 6.0 | `complete` | `Tests` |

### 1.2 Target Dependencies

**OpenClaw (main app):**
- `OpenClawShareExtension` (embedded)
- `OpenClawWatchApp`
- `OpenClawKit` (SPM package -- default library)
- `OpenClawChatUI` (SPM package -- product of OpenClawKit)
- `OpenClawProtocol` (SPM package -- product of OpenClawKit)
- `SwabbleKit` (SPM package -- product of Swabble)
- `AppIntents.framework` (system SDK)

**OpenClawShareExtension:**
- `OpenClawKit` (SPM package)

**OpenClawWatchApp:**
- `OpenClawWatchExtension` (target)

**OpenClawWatchExtension:**
- `WatchConnectivity.framework` (system SDK)
- `UserNotifications.framework` (system SDK)

**OpenClawTests:**
- `OpenClaw` (host app target)
- `SwabbleKit` (SPM package)
- `AppIntents.framework` (system SDK)
- Test host: `$(BUILT_PRODUCTS_DIR)/OpenClaw.app/OpenClaw`
- Bundle loader: `$(TEST_HOST)`

### 1.3 Scheme Configuration

**Scheme `OpenClaw`** (shared: true):
- Build targets: `OpenClaw` (all actions)
- Test targets: `OpenClawTests`

### 1.4 Version Information

| Field | Value |
|---|---|
| `CFBundleShortVersionString` | `2026.2.21` |
| `CFBundleVersion` | `20260220` |

---

## 2. Signing Configuration

### 2.1 Signing Flow Diagram

```
                        +---------------------------+
                        |   npm script / manual     |
                        | (pnpm ios:build/gen/open)  |
                        +------------+--------------+
                                     |
                                     v
                    +--------------------------------+
                    | scripts/ios-configure-signing.sh|
                    +--------+-----------------------+
                             |
                             v
                +----------------------------+
                | scripts/ios-team-id.sh     |
                |                            |
                | Priority order:            |
                | 1. $IOS_DEVELOPMENT_TEAM   |
                |    (env var, immediate)     |
                | 2. Preferred team ID        |
                |    (default: Y5PE65HELJ)   |
                | 3. Preferred team name      |
                |    ($IOS_PREFERRED_TEAM_    |
                |     NAME)                  |
                | 4. Non-free team (first)    |
                | 5. First team found         |
                +--------+-------------------+
                         |
                         | team_id
                         v
           +-----------------------------------+
           | Compute bundle IDs:               |
           | suffix = $OPENCLAW_IOS_BUNDLE_     |
           |          SUFFIX || $USER-team_seg  |
           | app  = $OPENCLAW_IOS_APP_BUNDLE_ID |
           |     || ai.openclaw.ios.test.$suffix|
           | share = $app.share                 |
           | watch = $app.watchkitapp           |
           | ext   = $watch.extension           |
           +--------+--------------------------+
                    |
                    v
        +-----------------------------------+
        | Write .local-signing.xcconfig     |
        | (apps/ios/.local-signing.xcconfig) |
        | -- git-ignored                    |
        +-----------------------------------+
```

### 2.2 Signing Files

| File | Path | Purpose | Committed? |
|---|---|---|---|
| `Signing.xcconfig` | `apps/ios/Signing.xcconfig` | Default signing for main app + share ext | Yes |
| `Config/Signing.xcconfig` | `apps/ios/Config/Signing.xcconfig` | Default signing for Watch targets | Yes |
| `.local-signing.xcconfig` | `apps/ios/.local-signing.xcconfig` | Auto-generated local overrides | No (gitignored) |
| `LocalSigning.xcconfig` | `apps/ios/LocalSigning.xcconfig` | Manual local overrides | No (gitignored) |
| `LocalSigning.xcconfig.example` | `apps/ios/LocalSigning.xcconfig.example` | Template for manual overrides | Yes |

### 2.3 Environment Variables for Signing Overrides

| Variable | Purpose | Default |
|---|---|---|
| `IOS_DEVELOPMENT_TEAM` | Direct team ID override (skips all detection) | (none) |
| `IOS_PREFERRED_TEAM_ID` | Preferred team when multiple found | `Y5PE65HELJ` |
| `IOS_PREFERRED_TEAM_NAME` | Match team by name | (none) |
| `IOS_ALLOW_KEYCHAIN_TEAM_FALLBACK` | Allow keychain cert-based team detection | `0` |
| `IOS_PREFER_NON_FREE_TEAM` | Prefer paid over free team | `1` |
| `IOS_SIGNING_REQUIRED` | Fail hard if no team detected | `0` |
| `OPENCLAW_IOS_BUNDLE_SUFFIX` | Override bundle ID suffix | (none) |
| `OPENCLAW_IOS_APP_BUNDLE_ID` | Full override for app bundle ID | (none) |
| `OPENCLAW_IOS_CODE_SIGN_STYLE` | `Automatic` or `Manual` | `Automatic` |

---

## 3. Build Scripts and Pre-build Steps

### 3.1 Pre-build Script Execution Order

**Step 1: SwiftFormat (lint)**
- Input file list: `$(SRCROOT)/SwiftSources.input.xcfilelist`
- Config: `$SRCROOT/../../.swiftformat` (repo root)
- Command: `swiftformat --lint --config "$SRCROOT/../../.swiftformat" --filelist "$SRCROOT/SwiftSources.input.xcfilelist"`
- Behavior: Lint-only (no auto-fix). Fails build if formatting violations exist.

**Step 2: SwiftLint**
- Input file list: `$(SRCROOT)/SwiftSources.input.xcfilelist`
- Config: `$SRCROOT/.swiftlint.yml` (iOS-specific, inherits from root)
- Command: `swiftlint lint --config "$SRCROOT/.swiftlint.yml" --use-script-input-file-lists`

### 3.2 Input File List

**File:** `apps/ios/SwiftSources.input.xcfilelist` -- Contains 61 Swift source files spanning:
- `Sources/` -- 27 files (iOS app sources)
- `../shared/OpenClawKit/Sources/` -- 28 files (shared kit sources)
- `../../Swabble/Sources/SwabbleKit/` -- 1 file (`WakeWordGate.swift`)

---

## 4. NPM Integration

### 4.1 iOS-related npm Scripts

| Script | Command | Description |
|---|---|---|
| `ios:gen` | `./scripts/ios-configure-signing.sh && cd apps/ios && xcodegen generate` | Configure signing + generate Xcode project |
| `ios:build` | Full signing + gen + xcodebuild | Full build to simulator |
| `ios:open` | Signing + gen + `open OpenClaw.xcodeproj` | Generate + open in Xcode |
| `ios:run` | Full build + boot sim + launch app | Build, boot simulator, launch app |

### 4.2 Environment Variables

| Variable | Used By | Default |
|---|---|---|
| `IOS_DEST` | `ios:build`, `ios:run` | `platform=iOS Simulator,name=iPhone 17` |
| `IOS_SIM` | `ios:run` | `iPhone 17` |

---

## 5. Entitlements and Permissions

### 5.1 Entitlements (`OpenClaw.entitlements`)

| Entitlement | Value |
|---|---|
| `aps-environment` | `development` |

**Notable absence:** No App Groups entitlement for Share Extension data sharing.

### 5.2 Info.plist Permissions

| Key | Description |
|---|---|
| `NSCameraUsageDescription` | Camera capture for gateway |
| `NSMicrophoneUsageDescription` | Voice wake microphone access |
| `NSSpeechRecognitionUsageDescription` | On-device speech recognition |
| `NSLocationWhenInUseUsageDescription` | Location sharing when in use |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Background location sharing |
| `NSLocalNetworkUsageDescription` | Local gateway discovery |

### 5.3 Background Modes

| Mode | Purpose |
|---|---|
| `audio` | Voice wake / Talk mode |
| `remote-notification` | APNs silent/content push handling |

### 5.4 Other Configuration

- **URL Scheme:** `openclaw`
- **Bonjour Services:** `_openclaw-gw._tcp`
- **Background Task:** `ai.openclaw.ios.bgrefresh`
- **ATS:** `NSAllowsArbitraryLoadsInWebContent: true`

---

## 6. Package Dependencies

### 6.1 Full Dependency Tree

```
OpenClaw (app)
 +-- OpenClawKit (local: apps/shared/OpenClawKit)
 |    +-- OpenClawProtocol (no deps)
 |    +-- OpenClawKit
 |    |    +-- OpenClawProtocol
 |    |    +-- ElevenLabsKit (remote: github.com/steipete/ElevenLabsKit @ 0.1.0)
 |    +-- OpenClawChatUI
 |         +-- OpenClawKit
 |         +-- Textual (remote: github.com/gonzalezreal/textual @ 0.3.1)
 +-- Swabble (local: Swabble/)
 |    +-- SwabbleKit (no external deps)
 +-- AppIntents.framework (system)
```

### 6.2 Remote SPM Dependencies

| Package | URL | Version | Used By |
|---|---|---|---|
| `ElevenLabsKit` | `github.com/steipete/ElevenLabsKit` | exact `0.1.0` | `OpenClawKit` |
| `Textual` | `github.com/gonzalezreal/textual` | exact `0.3.1` | `OpenClawChatUI` |

---

## 7. Build Script Execution Order

```
1. bash -lc (login shell for PATH setup)
2. ./scripts/ios-configure-signing.sh
   2a. scripts/ios-team-id.sh  -->  detect Apple Team ID
   2b. Compute bundle IDs (user/team derived or env override)
   2c. Write .local-signing.xcconfig (if changed)
3. cd apps/ios
4. xcodegen generate
   4a. Reads project.yml
   4b. Generates OpenClaw.xcodeproj
5. xcodebuild -project OpenClaw.xcodeproj -scheme OpenClaw ...
   5a. Pre-build: SwiftFormat --lint (61 files from xcfilelist)
   5b. Pre-build: SwiftLint (iOS config, parent from root)
   5c. Resolve SPM packages (OpenClawKit, Swabble + transitive)
   5d. Compile targets in dependency order
```

---

## 8. Known Gotchas and Issues

### Critical

1. **Stale Appfile bundle ID** -- `fastlane/Appfile` references `bot.molt.ios` instead of `ai.openclaw.ios`. Affects fastlane metadata/deliver operations.

2. **SwiftLint iOS path mismatch** -- `.swiftlint.yml` includes `../shared/ClawdisNodeKit/Sources` but the actual path is `../shared/OpenClawKit/Sources`. SwiftLint silently skips shared sources.

3. **No App Groups entitlement** -- Share Extension and main app lack shared App Group container for data passing.

### Important

4. **Push Notifications on personal teams** -- `aps-environment` entitlement requires push capability. Free/personal teams cannot provision push, causing runtime APNs registration failures.

5. **SwiftFormat version mismatch** -- `.swiftformat` config declares `--swiftversion 6.2` while `project.yml` declares `SWIFT_VERSION: "6.0"`.

6. **ENABLE_APPINTENTS_METADATA: NO** -- AppIntents metadata generation disabled despite AppIntents.framework dependency.

### Minor

7. **`basedOnDependencyAnalysis: false`** on both pre-build scripts means SwiftFormat/SwiftLint run on every build, adding overhead.

8. **Default simulator is `iPhone 17`** -- Requires Xcode 16+ with iOS 18 simulator runtime.

---

## 9. Required Environment Setup Checklist

### Mandatory Prerequisites

- [ ] macOS with Xcode 16+ installed
- [ ] `pnpm` installed (version 10.23.0+)
- [ ] `xcodegen` installed (`brew install xcodegen`)
- [ ] `swiftformat` installed (`brew install swiftformat`)
- [ ] `swiftlint` installed (`brew install swiftlint`)
- [ ] Apple Developer account signed in to Xcode
- [ ] Valid signing certificates in keychain

### For Local Development

- [ ] Run `pnpm install` from repo root
- [ ] Run `./scripts/ios-configure-signing.sh` (or `pnpm ios:gen`)
- [ ] If using personal team: create `LocalSigning.xcconfig` from `.example`
- [ ] Push Notifications capability enabled for signed bundle ID
