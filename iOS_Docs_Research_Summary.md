# OpenClaw iOS App Documentation Summary

**Research Date:** March 1, 2026
**Source:** Official OpenClaw GitHub Repository (https://github.com/openclaw/openclaw)
**Current Version:** v2026.2.27 (Build 20260227)
**Status:** Internal super-alpha app - local deployment only

---

## Overview

The OpenClaw iOS app is an optional companion application that pairs iPhones as a **node** with an OpenClaw Gateway. The app extends the OpenClaw ecosystem by providing voice activation, canvas surface interaction, and direct device control capabilities on iOS devices.

**Key Purpose:**
- Act as a device node within the OpenClaw network
- Enable voice trigger forwarding and canvas surface rendering
- Provide direct device control (camera, location, notifications, etc.)
- Maintain persistent connection to an OpenClaw Gateway for orchestration

**Current Status:** This is an internal-use only, super-alpha application with no TestFlight distribution. Manual local deployment from source via Xcode is the only current distribution method.

---

## Key Requirements

### Development Environment
- **Xcode:** 16.0 or higher (required)
- **Swift:** Version 6.0
- **iOS Deployment Target:** iOS 18.0 minimum
- **watchOS Support:** watchOS 11.0+ (watch companion app included)
- **Build Tool:** xcodegen (for Xcode project generation)
- **Package Manager:** pnpm (Node.js package management for root-level scripts)

### System Requirements
- **Apple Developer Account:** Required for code signing
- **Signing Support:** Push Notifications capability must be enabled for selected team/bundle ID
- **Device Preference:** Real iPhone device recommended (simulator supported but behavior differs)

### Required Tools
1. **pnpm** - Node.js monorepo package manager
2. **xcodegen** - Generates Xcode project from YAML configuration
3. **Xcode Command Line Tools** - For build scripts and compilation

### Signing & Team Configuration
- **Code Signing Style:** Automatic
- **Bundle ID Prefix:** `ai.openclaw`
- **Development Team:** Required (example: P5Z8X89DJL)
- **Push Notifications:** Must be enabled for the selected team and bundle ID
- **Local Bundle IDs:** Can be customized via `LocalSigning.xcconfig` for personal teams

---

## Project Structure

```
apps/ios/
├── Sources/                          # Main Swift source code
│   ├── Views/                        # SwiftUI view components
│   ├── Models/                       # Data models and structures
│   ├── Services/                     # Gateway connection, pairing, etc.
│   └── [Additional Swift modules]
├── Tests/                            # Unit and integration test suite
├── ShareExtension/                   # iOS Share sheet extension implementation
├── WatchApp/                         # watchOS companion app
├── WatchExtension/                   # watchOS app extension code
├── Config/                           # Configuration resources and assets
├── project.yml                       # XCGenerate project definition (YAML)
├── Signing.xcconfig                  # Standard signing configuration
├── LocalSigning.xcconfig.example     # Template for local signing overrides
├── .swiftlint.yml                    # SwiftLint code style rules
├── SwiftSources.input.xcfilelist     # Build system file list
├── fastlane/                         # Automation scripts for build/release
└── README.md                         # Setup and development documentation
```

### Primary Build Targets
1. **OpenClaw** - Main iOS application target
2. **OpenClawShareExtension** - Share extension for device integration
3. **OpenClawWatchApp** - watchOS companion application
4. **OpenClawWatchExtension** - watchOS app extension
5. **OpenClawTests** - Unit test bundle

---

## Build & Setup

### Quick Start (Single Command)
```bash
pnpm ios:open
```

### Step-by-Step Setup Process

1. **Install Root Dependencies**
   ```bash
   pnpm install
   ```

2. **Configure Code Signing**
   ```bash
   ./scripts/ios-configure-signing.sh
   ```
   This script handles all signing configuration, including Push Notifications setup.

3. **Generate Xcode Project**
   ```bash
   cd apps/ios
   xcodegen generate
   ```
   Generates `OpenClaw.xcodeproj` from `project.yml`.

4. **Open in Xcode**
   ```bash
   open OpenClaw.xcodeproj
   ```

5. **Build and Run in Xcode**
   - Select Scheme: **OpenClaw**
   - Select Destination: **Connected iPhone** (recommended) or simulator
   - Build Configuration: **Debug** (for development)
   - Click Product → Run (⌘R)

### Running from Command Line
```bash
# Full build and run on simulator
pnpm ios:run

# Detailed breakdown:
bash -lc './scripts/ios-configure-signing.sh && \
cd apps/ios && \
xcodegen generate && \
xcodebuild -project OpenClaw.xcodeproj \
  -scheme OpenClaw \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -configuration Debug build && \
xcrun simctl boot "iPhone 17" || true && \
xcrun simctl launch booted ai.openclaw.ios'
```

### For Local Testing (Personal Team)
If signing fails with a personal team, customize the bundle ID:
```bash
cp apps/ios/LocalSigning.xcconfig.example apps/ios/LocalSigning.xcconfig
# Edit LocalSigning.xcconfig with your team ID and custom bundle ID
# Then run xcodegen generate again
```

---

## Important Configuration

### Entitlements & Permissions
The app declares the following permissions in `OpenClaw.entitlements`:

**Development:**
- `aps-environment`: development (APNs for push notifications)

**Hardware & Device Access:**
- **Camera:** Image and video capture for device control
- **Location:** GPS and significant motion detection for geofence triggers
- **Microphone:** Voice activation and voice-based interaction (Talk feature)
- **Motion & Fitness:** Accelerometer data for motion detection
- **Contacts:** Contact access for device commands
- **Calendar & Reminders:** Calendar and task list integration
- **Photos Library:** Photo and video access
- **Notifications:** Local notification delivery

**Network:**
- **Local Network Discovery:** Bonjour pairing and local gateway discovery

### Push Notifications (APNs) Setup
- Token registration to gateway occurs **only after successful gateway connection**
- This requires the development team to have Push Notifications enabled
- APNs tokens are registered via: `push.apns.register`
- **Note:** The aps-environment is set to "development" in the project

### Bundle ID Configuration
- **Main App:** `ai.openclaw`
- **Share Extension:** `ai.openclaw.shareextension`
- **WatchKit App:** `ai.openclaw.watchkit` (app + extension variants)

---

## Architecture Notes

### Connection Architecture
- **Gateway Connection:** Connects to OpenClaw Gateway via discovery or manual host/port entry
- **TLS Security:** Uses TLS fingerprint trust prompts for secure connection
- **Pairing Flow:** Uses setup code flow pattern (gateway generates code, approved via Telegram `/pair approve`)

### Node Capabilities
The iOS app exposes the following command capabilities to the gateway:

**Foreground Commands (Fully Supported):**
- Camera snap/clip capture
- Canvas present/navigate/evaluate/snapshot
- Screen recording
- Location query and geofencing
- Contacts query
- Calendar access
- Reminders access
- Photos library access
- Motion detection
- Local notifications
- Chat and Talk (voice) through operator sessions

**Background Limitations:**
- Background socket behavior is still being hardened
- Canvas, camera, screen, and talk commands are **blocked in background**
- Background use is **NOT reliably supported**
- Voice Wake and Talk compete for microphone access

### Session Integration
- Chat and Talk surfaces are provided through operator gateway sessions
- Device-local actions execute on the iPhone itself (not gateway)
- Maintains separation between cloud processing and device-specific operations

### Known Limitations
- **Foreground-only:** Foreground use is the only reliably supported mode currently
- **Background Sockets:** Dead-socket states can occur after background activity
- **Wake/Reconnect:** Stability issues during scene transitions and reconnection
- **Voice Interaction:** Voice Wake and Talk features compete for microphone
- **Location Polling:** Continuous polling not recommended; geofence-based triggers preferred for battery life

---

## Recent Updates (February 2026)

### Version 2026.2.27 (Latest)
- **Build Date:** February 27, 2026
- **Branding Updates:** Replaced remaining bot.molt references with ai.openclaw across:
  - iOS app surfaces
  - Bundle IDs and logging subsystems
  - Documentation and CLI fixtures
- **Ongoing Improvements:**
  - Wake/reconnect stability hardening
  - Scene transition handling improvements
  - Reducing dead-socket states after background activity
  - Background mode reliability (in progress)

### Recent Activity (February 2026)
- Repository has 240,279 stars and 46,382 forks
- Last update: February 28, 2026
- Active development with dozens of contributors
- Focused on iOS app reliability and permission hardening

---

## Critical Setup Notes & Gotchas

### 1. xcodegen is Required
The Xcode project file (`OpenClaw.xcodeproj`) is **NOT checked into git**. You must always run `xcodegen generate` from `apps/ios/` before opening the project. Without it, Xcode won't find the project file.

### 2. Push Notifications & Team Selection
- You **must select an Apple Developer team** that has Push Notifications enabled for the bundle ID
- If you don't select a proper team, the app will fail to sign
- For personal testing, use `LocalSigning.xcconfig` with a custom bundle ID

### 3. Real Device vs. Simulator
- **Recommended:** Test on a real iPhone device for accurate behavior
- **Simulator:** Supported but some features (location, motion) behave differently
- **Notable:** Background socket behavior differs significantly between simulator and device

### 4. Foreground-Only Design
- **Critical Limitation:** Fully rely on foreground use; background features are alpha
- Commands like camera, canvas, screen, and talk are **blocked when app is backgrounded**
- Voice Wake and Talk compete for the microphone - don't run both simultaneously

### 5. Code Signing Script Must Run First
Always run `./scripts/ios-configure-signing.sh` from the repo root **before** attempting to build. This sets up all signing credentials and Push Notifications certificates.

### 6. Swift 6.0 Requirement
The project uses Swift 6.0 and requires Xcode 16.0+. Older versions will not compile. Ensure your Xcode installation is up to date.

### 7. Gateway Connection Required
The iOS app requires an OpenClaw Gateway to function. You cannot pair or operate the app without a running gateway. The pairing process involves:
1. Starting gateway in Telegram
2. Running `/pair` command in Telegram
3. Entering the setup code in the iOS app
4. Approving the pairing in Telegram with `/pair approve`

### 8. Bonjour Pairing
The app supports Bonjour discovery for local network pairing alongside standard host/port manual entry. "Local Network" permission is required for this to work.

### 9. SwiftLint & Format Checks
The project includes SwiftLint checks in the build phase. Code must pass SwiftFormat linting before the build succeeds. Non-compliant code will cause build failures.

### 10. No TestFlight Distribution
This is strictly a local-build-and-deploy situation. There is no TestFlight beta program. Distribution only happens through manual Xcode deployment to your own devices.

---

## Dependencies & Frameworks

### External Swift Packages
- **OpenClawKit** - Core SDK for gateway communication
- **Swabble** - UI framework (likely for multi-platform UI components)

### Built-in Frameworks
- **AppIntents** - Siri shortcuts integration
- **WatchConnectivity** - Communication with watchOS companion app
- **UserNotifications** - Local notification handling
- **CoreLocation** - Location and geofencing
- **AVFoundation** - Camera and screen recording
- **Speech** - Voice recognition (for Talk/voice commands)

### Build Tools
- **xcodegen** - Project generation from YAML
- **SwiftLint** - Code quality checks
- **SwiftFormat** - Code formatting enforcement
- **fastlane** - Build automation (deployment scripts)

---

## Development Workflow

### Standard Development Loop
1. Make changes to Swift source files in `Sources/`
2. Run `xcodegen generate` (only if project structure changes)
3. Build and run from Xcode (⌘B then ⌘R)
4. Ensure SwiftLint checks pass

### Testing
- Unit tests are in the `Tests/` directory
- Run tests from Xcode (⌘U) or:
  ```bash
  xcodebuild -project OpenClaw.xcodeproj -scheme OpenClaw -configuration Debug test
  ```

### Before Submitting Changes
1. Run SwiftFormat to fix formatting
2. Ensure SwiftLint checks pass (run build)
3. Test on a real device if possible
4. Test gateway pairing and connection
5. Verify no background regression (if touching background code)

---

## Troubleshooting

### Build Fails with "Project Not Found"
- **Cause:** xcodegen hasn't been run or failed
- **Solution:** Run `cd apps/ios && xcodegen generate`

### Code Signing Errors
- **Cause:** Signing configuration not set up or team doesn't support Push Notifications
- **Solution:** Run `./scripts/ios-configure-signing.sh` or use `LocalSigning.xcconfig` with custom bundle ID

### SwiftLint Build Failures
- **Cause:** Code doesn't meet formatting standards
- **Solution:** Run SwiftFormat to auto-fix formatting issues

### Can't Pair with Gateway
- **Cause:** Gateway not running or network unreachable
- **Solution:** Ensure gateway is running and reachable; check Bonjour/local network settings; verify gateway IP/port if using manual entry

### App Crashes on Launch
- **Cause:** Usually signing/entitlements issues or missing push certificates
- **Solution:** Check Console logs in Xcode; verify signing in Build Settings; re-run `ios-configure-signing.sh`

### Background Features Not Working
- **Note:** This is expected - background support is not yet complete
- **Workaround:** Keep app in foreground for full functionality

---

## Additional Resources

- **Official Repository:** https://github.com/openclaw/openclaw
- **iOS App README:** https://github.com/openclaw/openclaw/blob/main/apps/ios/README.md
- **Official Docs (iOS):** https://docs.openclaw.ai/platforms/ios
- **Installation Guide:** https://docs.openclaw.ai/install
- **Release Notes:** https://github.com/openclaw/openclaw/releases

---

## Summary for New Developers

To get started developing the OpenClaw iOS app:

1. Clone the repository
2. Run `pnpm install` from root
3. Run `./scripts/ios-configure-signing.sh`
4. Run `cd apps/ios && xcodegen generate`
5. Open `apps/ios/OpenClaw.xcodeproj` in Xcode
6. Select scheme "OpenClaw" and run on a real device
7. Pair with your OpenClaw Gateway using the setup code flow
8. Test in foreground (background support is still alpha)

The project is actively maintained and improving. Focus development efforts on foreground functionality while background support is hardened. Report any issues with gateway pairing, voice features, or device control commands to the main repository.
