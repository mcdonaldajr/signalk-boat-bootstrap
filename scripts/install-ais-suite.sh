#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SUITE_REPO_OWNER="${SUITE_REPO_OWNER:-${REPO_OWNER:-ajrm-marine-suite}}"
SIGNALK_HOME="${SIGNALK_HOME:-$HOME/.signalk}"
INSTALL_PIPER="${INSTALL_PIPER:-1}"
INSTALL_SYSTEM_PACKAGES="${INSTALL_SYSTEM_PACKAGES:-1}"
INSTALL_LOG2RAM="${INSTALL_LOG2RAM:-1}"
INSTALL_POWERDOWN="${INSTALL_POWERDOWN:-1}"
RESTART_SIGNALK="${RESTART_SIGNALK:-1}"

RESOURCES_PROVIDER_VERSION="${RESOURCES_PROVIDER_VERSION:-1.5.1}"
AJRM_MARINE_TRAFFIC_VERSION="${AJRM_MARINE_TRAFFIC_VERSION:-v0.5.0}"
AJRM_MARINE_DISPLAY_VERSION="${AJRM_MARINE_DISPLAY_VERSION:-v0.5.0}"
AJRM_MARINE_CONSOLE_VERSION="${AJRM_MARINE_CONSOLE_VERSION:-v0.5.1}"
AJRM_MARINE_NOTIFICATIONS_VERSION="${AJRM_MARINE_NOTIFICATIONS_VERSION:-v0.5.0}"
AJRM_MARINE_ALERTS_VERSION="${AJRM_MARINE_ALERTS_VERSION:-v0.5.0}"
AJRM_MARINE_AUDIO_VERSION="${AJRM_MARINE_AUDIO_VERSION:-v0.5.2}"
AJRM_MARINE_INSTRUMENT_ALERTS_VERSION="${AJRM_MARINE_INSTRUMENT_ALERTS_VERSION:-v0.5.0}"
AJRM_MARINE_INSTRUMENTS_VERSION="${AJRM_MARINE_INSTRUMENTS_VERSION:-v0.5.0}"
AJRM_MARINE_SNAPSHOT_VERSION="${AJRM_MARINE_SNAPSHOT_VERSION:-v0.5.0}"
AJRM_MARINE_LOGGER_VERSION="${AJRM_MARINE_LOGGER_VERSION:-v0.5.0}"
AJRM_MARINE_CAPTURE_VERSION="${AJRM_MARINE_CAPTURE_VERSION:-v0.5.0}"
AJRM_MARINE_VOYAGE_VIEWER_VERSION="${AJRM_MARINE_VOYAGE_VIEWER_VERSION:-v0.5.0}"
AJRM_MARINE_VESSEL_DATABASE_VERSION="${AJRM_MARINE_VESSEL_DATABASE_VERSION:-v0.5.0}"
AJRM_MARINE_HARBOUR_EDITOR_VERSION="${AJRM_MARINE_HARBOUR_EDITOR_VERSION:-v0.5.0}"
AJRM_MARINE_PI_CONTROLLER_VERSION="${AJRM_MARINE_PI_CONTROLLER_VERSION:-v0.5.0}"
AJRM_MARINE_GPS_INTEGRITY_VERSION="${AJRM_MARINE_GPS_INTEGRITY_VERSION:-v0.5.0}"
AJRM_MARINE_DR_PLOTTER_VERSION="${AJRM_MARINE_DR_PLOTTER_VERSION:-v0.5.0}"
AJRM_MARINE_SIMULATOR_VERSION="${AJRM_MARINE_SIMULATOR_VERSION:-v0.5.1}"

PIPER_VERSION="${PIPER_VERSION:-2023.11.14-2}"
PIPER_DIR="${PIPER_DIR:-/opt/piper}"
PIPER_VOICES_DIR="${PIPER_VOICES_DIR:-$HOME/piper-voices}"
PIPER_VOICE="${PIPER_VOICE:-en_GB-alan-medium}"
LOG2RAM_REPO="${LOG2RAM_REPO:-https://github.com/azlux/log2ram.git}"
LOG2RAM_REF="${LOG2RAM_REF:-master}"
POWERDOWN_REPO="${POWERDOWN_REPO:-https://github.com/mcdonaldajr/powerDown.git}"
POWERDOWN_REF="${POWERDOWN_REF:-main}"
POWERDOWN_INSTALL_DIR="${POWERDOWN_INSTALL_DIR:-/home/pi/powerDown}"

NETRC_CREATED=0
NETRC_BACKUP=""

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Installs the AJRM Marine Suite onto a Raspberry Pi that already has Signal K
Server installed and configured with signalk-server-setup.

Options:
  --no-system-packages   Skip apt package installation
  --no-log2ram           Skip log2ram installation for /var/log SD-card wear reduction
  --no-powerdown         Skip powerDown UPS GPIO shutdown service installation
  --no-piper             Skip Piper and voice installation
  --no-restart           Do not restart Signal K at the end
  --help                 Show this help

Environment overrides:
  GITHUB_TOKEN                       GitHub token for private plugin repos
  SUITE_REPO_OWNER                   GitHub owner, default: ajrm-marine-suite
  SIGNALK_HOME                       Signal K config directory, default: ~/.signalk
  LOG2RAM_REPO                       Default: $LOG2RAM_REPO
  LOG2RAM_REF                        Default: $LOG2RAM_REF
  POWERDOWN_REPO                     Default: $POWERDOWN_REPO
  POWERDOWN_REF                      Default: $POWERDOWN_REF
  POWERDOWN_INSTALL_DIR              Default: $POWERDOWN_INSTALL_DIR
  RESOURCES_PROVIDER_VERSION         Default: $RESOURCES_PROVIDER_VERSION
  AJRM_MARINE_TRAFFIC_VERSION        Default: $AJRM_MARINE_TRAFFIC_VERSION
  AJRM_MARINE_DISPLAY_VERSION        Default: $AJRM_MARINE_DISPLAY_VERSION
  AJRM_MARINE_CONSOLE_VERSION        Default: $AJRM_MARINE_CONSOLE_VERSION
  AJRM_MARINE_NOTIFICATIONS_VERSION  Default: $AJRM_MARINE_NOTIFICATIONS_VERSION
  AJRM_MARINE_ALERTS_VERSION         Default: $AJRM_MARINE_ALERTS_VERSION
  AJRM_MARINE_AUDIO_VERSION          Default: $AJRM_MARINE_AUDIO_VERSION
  AJRM_MARINE_INSTRUMENT_ALERTS_VERSION Default: $AJRM_MARINE_INSTRUMENT_ALERTS_VERSION
  AJRM_MARINE_INSTRUMENTS_VERSION    Default: $AJRM_MARINE_INSTRUMENTS_VERSION
  AJRM_MARINE_SNAPSHOT_VERSION       Default: $AJRM_MARINE_SNAPSHOT_VERSION
  AJRM_MARINE_LOGGER_VERSION         Default: $AJRM_MARINE_LOGGER_VERSION
  AJRM_MARINE_CAPTURE_VERSION        Default: $AJRM_MARINE_CAPTURE_VERSION
  AJRM_MARINE_VOYAGE_VIEWER_VERSION  Default: $AJRM_MARINE_VOYAGE_VIEWER_VERSION
  AJRM_MARINE_VESSEL_DATABASE_VERSION Default: $AJRM_MARINE_VESSEL_DATABASE_VERSION
  AJRM_MARINE_HARBOUR_EDITOR_VERSION Default: $AJRM_MARINE_HARBOUR_EDITOR_VERSION
  AJRM_MARINE_PI_CONTROLLER_VERSION  Default: $AJRM_MARINE_PI_CONTROLLER_VERSION
  AJRM_MARINE_GPS_INTEGRITY_VERSION  Default: $AJRM_MARINE_GPS_INTEGRITY_VERSION
  AJRM_MARINE_DR_PLOTTER_VERSION     Default: $AJRM_MARINE_DR_PLOTTER_VERSION
  AJRM_MARINE_SIMULATOR_VERSION      Default: $AJRM_MARINE_SIMULATOR_VERSION
EOF
}

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\nWARNING: %s\n' "$*" >&2
}

die() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ "$NETRC_CREATED" == "1" ]]; then
    rm -f "$HOME/.netrc"
    if [[ -n "$NETRC_BACKUP" && -f "$NETRC_BACKUP" ]]; then
      mv "$NETRC_BACKUP" "$HOME/.netrc"
      chmod 600 "$HOME/.netrc"
    fi
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-system-packages)
      INSTALL_SYSTEM_PACKAGES=0
      ;;
    --no-log2ram)
      INSTALL_LOG2RAM=0
      ;;
    --no-powerdown)
      INSTALL_POWERDOWN=0
      ;;
    --no-piper)
      INSTALL_PIPER=0
      ;;
    --no-restart)
      RESTART_SIGNALK=0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

if [[ "$(id -u)" == "0" ]]; then
  die "Run this as the normal pi user, not with sudo. The script will use sudo when needed."
fi

command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v npm >/dev/null 2>&1 || die "npm is not installed. Install Signal K Server first, then run this script."

if ! command -v node >/dev/null 2>&1; then
  die "node is not installed. Install Signal K Server first, then run this script."
fi

NODE_VERSION="$(node -p 'process.versions.node')"
NODE_MAJOR="${NODE_VERSION%%.*}"
NPM_VERSION="$(npm -v)"
NPM_MAJOR="${NPM_VERSION%%.*}"

if (( NODE_MAJOR < 22 )); then
  die "Node.js ${NODE_VERSION} is too old for current Signal K Server. Install Node.js 24 recommended, or at least Node.js 22, then rerun this script."
fi

if (( NODE_MAJOR < 24 )); then
  warn "Node.js ${NODE_VERSION} is supported by Signal K, but Node.js 24 is the current recommended fresh-install version."
fi

if (( NPM_MAJOR < 10 )); then
  warn "npm ${NPM_VERSION} is old. Current Signal K Raspberry Pi docs recommend npm 11 or later with Node.js 24."
fi

log "Detected Node.js ${NODE_VERSION} and npm ${NPM_VERSION}"

if [[ ! -d "$SIGNALK_HOME" ]]; then
  die "$SIGNALK_HOME does not exist. Run sudo signalk-server-setup first, then run this script."
fi

if [[ "$INSTALL_SYSTEM_PACKAGES" == "1" ]]; then
  log "Installing Raspberry Pi OS packages"
  sudo apt-get update
  sudo apt-get install -y \
    git curl ca-certificates build-essential python3 python3-pip \
    gh jq unzip tar gzip rsync python3-rpi.gpio avahi-daemon avahi-utils libnss-mdns \
    libavahi-compat-libdnssd-dev alsa-utils ffmpeg sox mpg123
elif ! command -v gh >/dev/null 2>&1; then
  warn "GitHub CLI (gh) is not installed. Install it with 'sudo apt-get install gh' before using private GitHub release download commands."
fi

setup_github_auth() {
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    warn "GITHUB_TOKEN is not set. Public repos will install, but private repos may fail."
    return
  fi

  log "Preparing temporary GitHub token authentication"
  if [[ -f "$HOME/.netrc" ]]; then
    NETRC_BACKUP="$(mktemp "$HOME/.netrc.backup.XXXXXX")"
    cp "$HOME/.netrc" "$NETRC_BACKUP"
  fi

  cat > "$HOME/.netrc" <<EOF
machine github.com
  login x-access-token
  password ${GITHUB_TOKEN}
machine api.github.com
  login x-access-token
  password ${GITHUB_TOKEN}
EOF
  chmod 600 "$HOME/.netrc"
  NETRC_CREATED=1
}

install_piper() {
  if [[ "$INSTALL_PIPER" != "1" ]]; then
    return
  fi

  log "Installing Piper speech engine and $PIPER_VOICE voice"
  local arch
  arch="$(uname -m)"

  local piper_assets=()
  case "$arch" in
    aarch64|arm64)
      piper_assets=("piper_linux_aarch64.tar.gz" "piper_arm64.tar.gz")
      ;;
    armv7l)
      piper_assets=("piper_linux_armv7l.tar.gz" "piper_armv7.tar.gz")
      ;;
    x86_64|amd64)
      piper_assets=("piper_linux_x86_64.tar.gz" "piper_amd64.tar.gz")
      ;;
    *)
      warn "Automatic Piper binary install is not configured for architecture: $arch"
      return
      ;;
  esac

  local tmp
  tmp="$(mktemp -d)"
  local piper_url=""
  for piper_asset in "${piper_assets[@]}"; do
    piper_url="https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/${piper_asset}"
    if curl -fsSL "$piper_url" -o "$tmp/piper.tar.gz"; then
      break
    fi
    piper_url=""
  done
  if [[ -z "$piper_url" ]]; then
    rm -rf "$tmp"
    die "Could not download a Piper binary for $arch from release $PIPER_VERSION"
  fi
  sudo mkdir -p "$PIPER_DIR"
  sudo tar -xzf "$tmp/piper.tar.gz" -C "$PIPER_DIR" --strip-components=1
  sudo ln -sf "$PIPER_DIR/piper" /usr/local/bin/piper

  mkdir -p "$PIPER_VOICES_DIR"
  curl -fsSL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/${PIPER_VOICE}.onnx" \
    -o "$PIPER_VOICES_DIR/${PIPER_VOICE}.onnx"
  curl -fsSL "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/${PIPER_VOICE}.onnx.json" \
    -o "$PIPER_VOICES_DIR/${PIPER_VOICE}.onnx.json"

  rm -rf "$tmp"
}

install_log2ram() {
  if [[ "$INSTALL_LOG2RAM" != "1" ]]; then
    return
  fi
  if systemctl list-unit-files log2ram.service 2>/dev/null | grep -q '^log2ram\.service'; then
    log "log2ram is already installed"
    sudo systemctl enable log2ram.service >/dev/null 2>&1 || true
    return
  fi

  log "Installing log2ram for /var/log SD-card wear reduction"
  local tmp
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch "$LOG2RAM_REF" "$LOG2RAM_REPO" "$tmp/log2ram"
  (cd "$tmp/log2ram" && sudo ./install.sh)
  rm -rf "$tmp"
  log "log2ram installed. Reboot after bootstrap so /var/log is mounted from RAM."
}

install_powerdown() {
  if [[ "$INSTALL_POWERDOWN" != "1" ]]; then
    return
  fi

  log "Installing powerDown UPS GPIO shutdown service"
  local tmp
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch "$POWERDOWN_REF" "$POWERDOWN_REPO" "$tmp/powerDown"
  (cd "$tmp/powerDown" && sudo INSTALL_DIR="$POWERDOWN_INSTALL_DIR" ./install.sh)
  rm -rf "$tmp"
}

install_plugin() {
  local repo="$1"
  local version="$2"
  local url="git+https://github.com/${SUITE_REPO_OWNER}/${repo}.git#${version}"

  log "Installing ${repo} ${version}"
  npm install "$url" --omit=dev --no-package-lock || {
    warn "Install failed for ${repo}; verifying npm cache and retrying once."
    npm cache verify || true
    npm install "$url" --omit=dev --no-package-lock
  }
}

install_npm_package() {
  local package="$1"
  local version="$2"
  local spec="${package}@${version}"

  log "Installing ${spec}"
  npm install "$spec" --omit=dev --no-package-lock || {
    warn "Install failed for ${spec}; verifying npm cache and retrying once."
    npm cache verify || true
    npm install "$spec" --omit=dev --no-package-lock
  }
}

setup_github_auth
install_log2ram
install_powerdown
install_piper

log "Installing Signal K plugins into $SIGNALK_HOME"
cd "$SIGNALK_HOME"

install_npm_package "@signalk/resources-provider" "$RESOURCES_PROVIDER_VERSION"
install_plugin "signalk-ajrm-marine-notifications" "$AJRM_MARINE_NOTIFICATIONS_VERSION"
install_plugin "signalk-ajrm-marine-alerts" "$AJRM_MARINE_ALERTS_VERSION"
install_plugin "signalk-ajrm-marine-traffic" "$AJRM_MARINE_TRAFFIC_VERSION"
install_plugin "signalk-ajrm-marine-display" "$AJRM_MARINE_DISPLAY_VERSION"
install_plugin "signalk-ajrm-marine-console" "$AJRM_MARINE_CONSOLE_VERSION"
install_plugin "signalk-ajrm-marine-instrument-alerts" "$AJRM_MARINE_INSTRUMENT_ALERTS_VERSION"
install_plugin "signalk-ajrm-marine-instruments" "$AJRM_MARINE_INSTRUMENTS_VERSION"
install_plugin "signalk-ajrm-marine-audio" "$AJRM_MARINE_AUDIO_VERSION"
install_plugin "signalk-ajrm-marine-snapshot" "$AJRM_MARINE_SNAPSHOT_VERSION"
install_plugin "signalk-ajrm-marine-logger" "$AJRM_MARINE_LOGGER_VERSION"
install_plugin "signalk-ajrm-marine-capture" "$AJRM_MARINE_CAPTURE_VERSION"
install_plugin "signalk-ajrm-marine-voyage-viewer" "$AJRM_MARINE_VOYAGE_VIEWER_VERSION"
install_plugin "signalk-ajrm-marine-vessel-database" "$AJRM_MARINE_VESSEL_DATABASE_VERSION"
install_plugin "signalk-ajrm-marine-harbour-editor" "$AJRM_MARINE_HARBOUR_EDITOR_VERSION"
install_plugin "signalk-ajrm-marine-pi-controller" "$AJRM_MARINE_PI_CONTROLLER_VERSION"
install_plugin "signalk-ajrm-marine-gps-integrity" "$AJRM_MARINE_GPS_INTEGRITY_VERSION"
install_plugin "signalk-ajrm-marine-dr-plotter" "$AJRM_MARINE_DR_PLOTTER_VERSION"
install_plugin "signalk-ajrm-marine-simulator" "$AJRM_MARINE_SIMULATOR_VERSION"

mkdir -p \
  "$HOME/CapturePlusLogs/buffer" \
  "$HOME/CapturePlusLogs/captures" \
  "$HOME/CapturePlusLogs/clips" \
  "$HOME/CapturePlusLogs/voyages"

if [[ "$RESTART_SIGNALK" == "1" ]]; then
  log "Restarting Signal K"
  sudo systemctl restart signalk || sudo systemctl restart signalk.service || warn "Could not restart Signal K automatically."
fi

log "Install complete"
cat <<EOF

Next steps:
1. Open the Signal K Admin UI.
2. Log in as admin.
3. Enable/configure the installed plugins if they are not already enabled.
4. Enable AJRM Marine Traffic when you are ready for it to publish AIS collision notifications.
5. Open AJRM Marine Console at:
   https://<your-pi-hostname>:3443/signalk-ajrm-marine-console/

If browser behaviour looks stale after an update, hard refresh or clear site
data for the Signal K hostname.
EOF
