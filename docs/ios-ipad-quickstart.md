# OpenClaw iOS iPad Quick Start Guide

Deploy OpenClaw to your iPad and start using it as a portable AI agent interface with full access to device capabilities.

## What You'll Get

An iPad app that can:

- 🗣️ **Voice Wake & Talk Mode** - Wake the app with your voice, speak to interact
- 📍 **Location Services** - Share your precise or approximate location
- 📸 **Camera** - Take snapshots and record video clips
- 🗂️ **File Access** - Access photos and media from your device
- 📇 **Contacts** - Search and add contacts
- 📅 **Calendar** - View events and create new ones
- ✅ **Reminders** - Create and manage reminders
- 📹 **Screen Recording** - Share your screen content
- 🎙️ **Microphone** - Full voice interaction
- 🔔 **Push Notifications** - Wake background app from gateway
- 📡 **Local Network Discovery** - Auto-find your OpenClaw Gateway

## Prerequisites

On macOS:

- Xcode 16+ installed
- pnpm installed (`brew install pnpm`)
- xcodegen installed (`brew install xcodegen`)
- (Optional) ios-deploy for direct physical device deployment

On your iPad:

- iOS 18.0 or later
- Connected to the same network as your OpenClaw Gateway
- Developer mode enabled (Settings > Privacy > Developer Mode)

## Step 1: Prepare Your Mac

If this is your first time:

```bash
# Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install pnpm xcodegen swiftformat swiftlint
```

## Step 2: Build the App

Clone and build:

```bash
cd ~/openclaw  # or wherever you have the repo
pnpm install

# For iPad simulator (fastest for initial testing):
./scripts/ios-build-and-deploy.sh --sim "iPad (11-inch) (7th generation)"

# OR for physical iPad device:
./scripts/ios-build-and-deploy.sh --device
```

The script will:

1. Configure signing
2. Generate the Xcode project
3. Build the app
4. Deploy to your target
5. Launch automatically

### Finding Your iPad's Device ID

If deploying to physical device:

```bash
# List all connected devices with their UDIDs
xcrun xctrace list devices

# Output will show something like:
# iPad (8th generation) (XXXXXXXX-XXXXXXXXXXXXXXXXXXXX)

# Then deploy using the UDID:
./scripts/ios-build-and-deploy.sh --udid XXXXXXXX-XXXXXXXXXXXXXXXXXXXX
```

## Step 3: Grant Permissions

When you first launch OpenClaw, iOS will ask for permissions. Tap **"Allow"** for:

- Microphone (required for voice wake and talk mode)
- Local Network (required for gateway discovery)
- Camera (optional, for camera capabilities)
- Location (optional, for location sharing)
- Photos (optional, for photo access)
- Contacts (optional, for contact search)
- Calendar & Reminders (optional)

**Important:** For location to work in the background, select "Always" in location permission, and it must be enabled in your build profile.

## Step 4: Connect to Your Gateway

### Using Local Network Discovery (Easiest)

1. Ensure your OpenClaw Gateway is running on the same network
2. In the app, tap **Settings** → **Gateway**
3. Tap **Discover**
4. Select your gateway from the list
5. Follow the pairing flow (you'll see a pairing code in Telegram)
6. Approve the pairing in Telegram with `/pair approve`

### Manual Connection

If discovery doesn't work:

1. **Settings** → **Gateway** → **Advanced** → **Manual**
2. Enter your gateway's:
   - Host: (IP address or hostname)
   - Port: (default 8000)
3. Enable "Allow untrusted certificates" if using self-signed TLS
4. Tap "Connect"

## Step 5: Start Talking to Your Agent

Once connected:

1. **Voice Wake:** Hold down the home button or use "Hey Siri" (if configured)
2. **Text Chat:** Tap the chat bubble icon
3. **Talk Mode:** Hold the microphone button and speak, release to send

Your agent now has access to:

- Your current location
- Camera for photos/video
- Your contacts and calendar
- Reminders and photos
- Device info and status
- Screen recording
- All voice interaction

## Capabilities Available to Your Agent

Your connected agent can request:

```json
{
  "location.get": "Get current GPS location",
  "location.watch": "Stream continuous location updates",

  "camera.snap": "Take a photo",
  "camera.clip": "Record a video clip",

  "contacts.search": "Search your contacts",
  "contacts.add": "Add a new contact",

  "calendar.events": "List upcoming events",
  "calendar.add": "Create a new calendar event",

  "reminders.list": "Get your reminders",
  "reminders.add": "Create a new reminder",

  "photos.latest": "Get your recent photos",

  "screen.record": "Record your screen",

  "device.status": "Get battery, network, device info",
  "device.info": "Get device model, OS version, etc.",

  "motion.activities": "Get activity classification (walking, running, etc.)",
  "motion.pedometer": "Get step count and distance"
}
```

## Troubleshooting

### Build fails with "xcodegen not found"

```bash
brew install xcodegen
```

### Build fails with signing errors

```bash
# Regenerate signing config
./scripts/ios-configure-signing.sh

# Or manually set your Apple Team ID
export OPENCLAW_IOS_CODE_SIGN_STYLE=Automatic
./scripts/ios-build-and-deploy.sh
```

### App won't connect to gateway

1. Check that gateway is running: `openclaw` or `pnpm openclaw:dev`
2. Verify network connectivity: both iPad and Mac on same network
3. Check gateway address in app Settings → Gateway
4. Try manual connection with explicit host/port
5. Check gateway logs for incoming connection attempts

### Location not working

- Grant "Always" permission (not just "While Using App")
- Ensure background location is enabled in build profile
- Verify location services are enabled in iOS Settings
- Check Privacy > Location Services in Settings

### Voice wake not responding

- Grant Microphone permission
- Ensure "Voice Wake" is enabled in app Settings
- Check microphone isn't muted (hardware switch on iPad)
- Try Talk Mode (tap microphone icon) - it doesn't require wake

### Push notifications not working

- Check "Notifications" are allowed in iOS Settings
- Verify APNs is configured in your developer account
- Check app logs: Settings → Gateway → Debug Logs

## Performance & Battery

- Voice wake runs continuously but uses minimal battery
- Location updates in background require "Always" permission
- Camera operations happen only on request
- Background refresh is tuned to avoid battery drain
- Screen recording pauses when app goes to background

## Security & Privacy

- All communication to gateway is encrypted (TLS)
- Sensitive data (contacts, photos) requires app permission
- iOS sandboxes all access - app can't access system files
- Pairing is required before gateway can invoke capabilities
- Permissions can be revoked anytime in iOS Settings

## What's Next

Once connected, you can:

1. **Ask your agent to check your location:** "Where am I?"
2. **Automate based on location:** Set up geofence-triggered reminders
3. **Take photos remotely:** "Snap a photo"
4. **Quick reminders:** "Remind me to ..."
5. **Calendar integration:** "Schedule a meeting for ..."

## Tips & Tricks

- **Always-on listening:** Keep Voice Wake enabled while iPad is in use
- **Faster responses:** Keep the app in foreground for real-time chat
- **Background tasks:** Configure your gateway for silent push wake
- **Location automation:** Use Significant Location Updates for efficiency
- **Screen sharing:** Enable screen recording for visual context

## Known Limitations

- Background command execution is limited by iOS (foreground preferred)
- Voice wake pauses while Talk Mode is active (they share microphone)
- Camera operations may fail if camera is locked by another app
- Location accuracy depends on iOS location service settings
- Some capabilities require explicit developer mode on iOS 18+

## Getting Help

1. Check app logs: **Settings** → **Gateway** → **Discovery Logs** / **Debug Logs**
2. Test in Xcode with console output
3. Verify gateway is responding with `openclaw status`
4. Check iOS Settings for permission issues

## For Advanced Users

### Building from Xcode

Skip the build script and use Xcode directly:

```bash
cd apps/ios
xcodegen generate
open OpenClaw.xcodeproj
```

Then select your device/simulator in Xcode and press **Cmd+R** to build & run.

### Custom App Bundle ID

```bash
export OPENCLAW_IOS_BUNDLE_ID_BASE="com.yourcompany.openclaw"
./scripts/ios-build-and-deploy.sh
```

### Release Build

```bash
./scripts/ios-build-and-deploy.sh --config Release
```

---

**Status:** OpenClaw iOS is in active development. Expect features and APIs to evolve. Report issues or feedback via your normal channels.
