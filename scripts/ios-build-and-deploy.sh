#!/usr/bin/env bash
# OpenClaw iOS: Quick Build & Deploy for macOS
# Run this on your Mac to build and deploy the app to your iPad

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}➜${NC} $*"
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $*"
}

# Detect repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
iOS_DIR="${REPO_ROOT}/apps/ios"

# Configuration
SIMULATOR_NAME="${iOS_SIMULATOR_NAME:-iPhone 17}"
DEVICE_UDID="${iOS_DEVICE_UDID:-}"
CONFIG="${iOS_CONFIG:-Debug}"
BUILD_ONLY="${iOS_BUILD_ONLY:-0}"
USE_DEVICE="${USE_DEVICE:-0}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --device)
      USE_DEVICE=1
      shift
      ;;
    --udid)
      DEVICE_UDID="$2"
      USE_DEVICE=1
      shift 2
      ;;
    --sim)
      SIMULATOR_NAME="$2"
      USE_DEVICE=0
      shift 2
      ;;
    --config)
      CONFIG="$2"
      shift 2
      ;;
    --build-only)
      BUILD_ONLY=1
      shift
      ;;
    --help)
      cat << 'EOF'
OpenClaw iOS Build & Deploy Script

Usage: ./scripts/ios-build-and-deploy.sh [OPTIONS]

Options:
  --device              Deploy to connected physical iOS device (default: simulator)
  --udid <UDID>         Deploy to specific device by UDID
  --sim <NAME>          Use specific simulator (default: iPhone 17)
  --config <CONFIG>     Build configuration: Debug or Release (default: Debug)
  --build-only          Build without deploying
  --help                Show this help message

Examples:
  # Build for iPhone 17 simulator (default)
  ./scripts/ios-build-and-deploy.sh

  # Build for physical device
  ./scripts/ios-build-and-deploy.sh --device

  # Find your device UDID and deploy
  xcrun xctrace list devices
  ./scripts/ios-build-and-deploy.sh --udid <YOUR_UDID>

  # Build for iPad Pro
  ./scripts/ios-build-and-deploy.sh --sim "iPad Pro (12.9-inch)"

Environment Variables:
  iOS_SIMULATOR_NAME    Override simulator name (default: iPhone 17)
  iOS_DEVICE_UDID       Device UDID to deploy to
  iOS_CONFIG            Build configuration (default: Debug)
  iOS_BUILD_ONLY        Set to 1 to skip deployment
  USE_DEVICE            Set to 1 to use physical device

EOF
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo ""
log_info "═══════════════════════════════════════════════════════════════════"
log_info "OpenClaw iOS Build & Deploy"
log_info "═══════════════════════════════════════════════════════════════════"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v xcode-select &> /dev/null; then
  log_error "Xcode not found. Please install Xcode from App Store."
  exit 1
fi
log_success "Xcode found"

if ! command -v pnpm &> /dev/null; then
  log_error "pnpm not found. Install with: brew install pnpm"
  exit 1
fi
log_success "pnpm found"

if ! command -v xcodegen &> /dev/null; then
  log_error "xcodegen not found. Install with: brew install xcodegen"
  exit 1
fi
log_success "xcodegen found"

if ! command -v swiftformat &> /dev/null; then
  log_warn "swiftformat not found. Install with: brew install swiftformat"
fi

if ! command -v swiftlint &> /dev/null; then
  log_warn "swiftlint not found. Install with: brew install swiftlint"
fi

echo ""
log_info "Setting up iOS environment..."

# Run signing configuration
cd "${REPO_ROOT}"
log_info "Configuring signing..."
bash -lc "${REPO_ROOT}/scripts/ios-configure-signing.sh" || true
log_success "Signing configured"

# Install dependencies if needed
if [ ! -d "${REPO_ROOT}/node_modules" ]; then
  log_info "Installing pnpm dependencies..."
  pnpm install
  log_success "Dependencies installed"
else
  log_success "Dependencies already installed"
fi

# Generate Xcode project
cd "${iOS_DIR}"
log_info "Generating Xcode project with xcodegen..."
xcodegen generate --quiet
log_success "Xcode project generated"

echo ""
log_info "Building OpenClaw (${CONFIG})..."
echo ""

# Determine destination
if [ "$USE_DEVICE" == "1" ]; then
  if [ -n "$DEVICE_UDID" ]; then
    DESTINATION="generic/platform=iOS,id=${DEVICE_UDID}"
    log_info "Target: Connected device (${DEVICE_UDID})"
  else
    DESTINATION="generic/platform=iOS"
    log_info "Target: Any connected device"
  fi
else
  DESTINATION="platform=iOS Simulator,name=${SIMULATOR_NAME}"
  log_info "Target: ${SIMULATOR_NAME} simulator"

  # Ensure simulator is booted
  log_info "Ensuring simulator is booted..."
  xcrun simctl boot "${SIMULATOR_NAME}" 2>/dev/null || true
fi

# Build
DERIVED_DATA="/tmp/openclaw-ios-build"
xcodebuild \
  -project OpenClaw.xcodeproj \
  -scheme OpenClaw \
  -destination "${DESTINATION}" \
  -configuration "${CONFIG}" \
  -derivedDataPath "${DERIVED_DATA}" \
  build

log_success "Build succeeded!"

if [ "$BUILD_ONLY" == "1" ]; then
  echo ""
  log_success "Build-only complete. App is ready to deploy."
  exit 0
fi

# Find the built app
APP_PATH=$(find "${DERIVED_DATA}/Build/Products/${CONFIG}-iphonesimulator" -name "OpenClaw.app" -o -name "OpenClaw.app" 2>/dev/null | head -1)
if [ -z "$APP_PATH" ] && [ "$USE_DEVICE" == "0" ]; then
  # For simulator
  APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIG}-iphonesimulator/OpenClaw.app"
fi

if [ ! -d "$APP_PATH" ]; then
  log_error "Could not find built app at: $APP_PATH"
  exit 1
fi

if [ "$USE_DEVICE" == "0" ]; then
  echo ""
  log_info "Deploying to simulator..."
  xcrun simctl uninstall "${SIMULATOR_NAME}" ai.openclaw.ios 2>/dev/null || true
  xcrun simctl install "${SIMULATOR_NAME}" "$APP_PATH"
  log_success "App installed"

  log_info "Launching app in simulator..."
  xcrun simctl launch "${SIMULATOR_NAME}" ai.openclaw.ios
  log_success "App launched!"
else
  echo ""
  log_info "Deploying to physical device..."

  if command -v ios-deploy &> /dev/null; then
    ios-deploy --bundle "$APP_PATH" --justlaunch
    log_success "App deployed and launched!"
  else
    log_warn "ios-deploy not found. Install with: npm install -g ios-deploy"
    log_info "Alternatively, use Xcode to deploy:"
    log_info "  1. Connect your device"
    log_info "  2. Select your device in Xcode"
    log_info "  3. Press Cmd+R to build and run"
  fi
fi

echo ""
log_success "═══════════════════════════════════════════════════════════════════"
log_success "OpenClaw iOS deployment complete!"
log_success "═══════════════════════════════════════════════════════════════════"
echo ""
log_info "Next steps:"
echo "  1. Ensure your OpenClaw Gateway is running"
echo "  2. On the app, go to Settings > Gateway"
echo "  3. Use 'Discover' to find your gateway on the local network"
echo "  4. Or use 'Manual' to enter host/port directly"
echo "  5. Follow the pairing flow when prompted"
echo ""
log_info "Available capabilities:"
echo "  • Location services (with permission)"
echo "  • Camera snapshots and video clips"
echo "  • Screen recording"
echo "  • Contacts search and add"
echo "  • Calendar events and creation"
echo "  • Reminders list and creation"
echo "  • Photos access"
echo "  • Motion and activity data"
echo "  • Voice wake and talk mode"
echo ""
