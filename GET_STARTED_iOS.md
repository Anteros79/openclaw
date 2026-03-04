# 🚀 GET YOUR IPAD UP & RUNNING TODAY

**Everything is ready.** Your OpenClaw iOS app has full device access, and you have everything needed to deploy to your iPad by end of business.

## What's Ready

✅ **Complete iOS App** with all services already implemented:

- 🗣️ Voice wake & talk mode (microphone)
- 📍 Location services (precise GPS + background updates)
- 📸 Camera (snapshots & video clips)
- 📇 Contacts (search & add)
- 📅 Calendar (events & creation)
- ✅ Reminders (list & create)
- 📸 Photos (access & metadata)
- 📹 Screen recording
- 🎙️ Microphone access
- 🔔 Push notifications
- 📱 Device status & info
- 🚶 Motion & activity detection

✅ **Automated Build Script** for your Mac
✅ **Complete Documentation** for setup & API reference
✅ **Code Changes Committed** to branch

## Quick Start (5 minutes on your Mac)

### Prerequisites (one-time setup)

```bash
# Install required tools on macOS
brew install pnpm xcodegen swiftformat swiftlint
```

### Build & Deploy to iPad

**Option A: Build for iPad Simulator (fastest, for testing)**

```bash
cd ~/openclaw  # wherever you cloned the repo
./scripts/ios-build-and-deploy.sh --sim "iPad (11-inch) (7th generation)"
```

**Option B: Build for Physical iPad (what you want)**

```bash
# First, find your iPad's device ID
xcrun xctrace list devices

# Output will show something like:
# iPad (8th generation) (XXXXXXXX-XXXXXXXXXXXXXXXXXXXX)

# Deploy using the UDID:
./scripts/ios-build-and-deploy.sh --udid XXXXXXXX-XXXXXXXXXXXXXXXXXXXX
```

Or just connect your iPad and use the simpler command:

```bash
./scripts/ios-build-and-deploy.sh --device
```

**The script will:**

1. ✓ Check your Mac for Xcode, pnpm, xcodegen
2. ✓ Configure signing automatically
3. ✓ Generate the Xcode project
4. ✓ Build for your device
5. ✓ Deploy and launch on your iPad
6. ✓ Show you next steps

**Total time:** 3-8 minutes depending on if it's your first build

---

## After Deployment (1 minute setup on iPad)

### 1. Grant Permissions

When the app launches, iOS will ask for permissions. Tap **"Allow"** for:

- ✓ Microphone (required for voice)
- ✓ Local Network (required for gateway discovery)
- ✓ Camera (optional)
- ✓ Location (optional, needed for location sharing)
- ✓ Contacts/Calendar/Reminders (optional)

### 2. Connect to Your Gateway

**Option A: Auto-discovery (easiest)**

- In OpenClaw app: Settings → Gateway → Discover
- Select your gateway from the list
- Follow pairing flow
- Approve in Telegram with `/pair approve`

**Option B: Manual connection**

- Settings → Gateway → Advanced → Manual
- Enter your gateway's IP and port
- Enable "Allow untrusted certificates" if needed

### 3. Start Using It!

- **Voice:** Hold home button or say your wake word
- **Text:** Tap chat icon
- **Talk Mode:** Hold microphone button, speak, release

Your agent now has full access to:

- Your current location
- Camera for photos/video
- Contacts and calendar
- Photos and reminders
- Device info and status
- Screen recording

---

## What Your Agent Can Now Do

Ask your agent things like:

```
"Where am I?"                       → Gets GPS location
"Take a photo"                      → Snap photo
"Record a 10 second video"          → Camera clip
"Search for Alice"                  → Search contacts
"Show me my calendar"               → List events
"Create a meeting at 2pm"           → Add calendar event
"What are my reminders?"            → List reminders
"Remind me to call mom at 7pm"      → Create reminder
"Show me my recent photos"          → Photo access
"Record the screen"                 → Screen recording
"How much battery do I have?"       → Device status
"How many steps today?"             → Motion/activity
"I'm at the coffee shop"            → Location context
```

---

## Documentation

For detailed setup, troubleshooting, and API reference:

- **Quick Start:** `docs/ios-ipad-quickstart.md`
- **API Reference:** `docs/ios-api-capabilities.md`
- **All Capabilities:** See API reference for JSON-RPC examples

---

## If Something Doesn't Work

### "Build fails" or "xcodegen not found"

```bash
brew install xcodegen
```

### "Signing error" or "Team ID not found"

```bash
./scripts/ios-configure-signing.sh
# Or set it manually:
export OPENCLAW_IOS_CODE_SIGN_STYLE=Automatic
./scripts/ios-build-and-deploy.sh --device
```

### "App won't connect to gateway"

1. Make sure gateway is running: `pnpm openclaw:dev` or `openclaw`
2. Both iPad and Mac on same network
3. Check gateway address in app Settings → Gateway
4. Try Manual connection with explicit host/port

### "Location not working"

- Grant "Always" permission (not just "While Using")
- Check Settings → Privacy → Location Services

### "Voice not responding"

- Grant Microphone permission
- Ensure Voice Wake enabled in Settings
- Hardware microphone mute button off

### "Push notifications not working"

- Ensure Notifications allowed in iOS Settings
- Check app logs: Settings → Gateway → Debug Logs

---

## Performance Notes

- **Voice wake:** Always-on but minimal battery use
- **Location in background:** Requires "Always" permission
- **Camera:** Only uses battery when activated
- **Background refresh:** Tuned to avoid battery drain
- **Screen recording:** Works in foreground only

---

## What's Under the Hood

**Already Implemented & Ready:**

✓ NodeAppModel (2,681 LOC core model)
✓ LocationService - Full GPS with background support
✓ VoiceWakeManager - Always-on listening
✓ TalkModeManager (79KB) - Complete push-to-talk
✓ CameraController - Snap & video clip capture
✓ ContactsService - Search & add contacts
✓ CalendarService - Events & creation
✓ RemindersService - Reminders management
✓ PhotoLibraryService - Photo access
✓ MotionService - Activity detection
✓ DeviceStatusService - System info
✓ ScreenRecordService - Screen capture
✓ GatewayCoordinator - Connection management
✓ WatchMessagingService - Watch integration

**Documentation Created:**
✓ iOS iPad Quick Start Guide
✓ iOS API Capabilities Reference (with JSON examples)
✓ Build & Deploy Script

---

## Next Steps (By EOB)

1. ⏱️ **~5 min:** Run build script on your Mac
2. ⏱️ **~1 min:** Grant permissions on iPad
3. ⏱️ **~1 min:** Connect to gateway
4. ✨ **NOW:** Start talking to your agent!

---

## Need Help?

Check the documentation in `docs/`:

- `ios-ipad-quickstart.md` - Complete setup guide
- `ios-api-capabilities.md` - All available APIs with examples

Or review the original Phase 0 research:

- `PHASE0_FINDINGS.md` - Architecture analysis
- `PHASE0_BUILD_SYSTEM.md` - Build system details
- `PHASE0_TEST_SUITE.md` - Testing structure

---

## Want to Keep Building?

Once you have your iPad working, you can:

1. **Add custom voice wake words** - Personalize your wake phrase
2. **Create location-based automations** - Trigger actions based on position
3. **Set up custom capabilities** - Extend what your agent can do
4. **Optimize background behavior** - Fine-tune reconnection and wake
5. **Add more integrations** - Connect other services

All the code is structured and documented for easy extension.

---

**Status:** Everything is ready. Your portable AI agent with full device context is minutes away.

Build it. Deploy it. Use it. 🚀
