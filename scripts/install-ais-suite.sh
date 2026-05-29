#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_OWNER="${REPO_OWNER:-mcdonaldajr}"
SIGNALK_HOME="${SIGNALK_HOME:-$HOME/.signalk}"
INSTALL_PIPER="${INSTALL_PIPER:-1}"
INSTALL_SYSTEM_PACKAGES="${INSTALL_SYSTEM_PACKAGES:-1}"
RESTART_SIGNALK="${RESTART_SIGNALK:-1}"

AIS_PLUS_VERSION="${AIS_PLUS_VERSION:-v7.72.11}"
AIS_PLUS_AUDIO_VERSION="${AIS_PLUS_AUDIO_VERSION:-v1.2.0}"
AIS_PLUS_COMPANION_VERSION="${AIS_PLUS_COMPANION_VERSION:-v2.0.7}"
AIS_PLUS_APPLE_WATCH_VERSION="${AIS_PLUS_APPLE_WATCH_VERSION:-v1.0.1}"
AI_SNAPSHOT_VERSION="${AI_SNAPSHOT_VERSION:-v0.1.8}"
CAPTURE_PLUS_VERSION="${CAPTURE_PLUS_VERSION:-v1.0.2}"
VESSEL_DATABASE_VERSION="${VESSEL_DATABASE_VERSION:-v1.0.0}"
HARBOUR_EDITOR_VERSION="${HARBOUR_EDITOR_VERSION:-v3.0.1}"
VESSEL_SIMULATOR_VERSION="${VESSEL_SIMULATOR_VERSION:-v2.4.0}"
SELF_TRACK_SIMULATOR_VERSION="${SELF_TRACK_SIMULATOR_VERSION:-v1.0.0}"
PI_CONTROLLER_VERSION="${PI_CONTROLLER_VERSION:-v1.1.0}"

PIPER_VERSION="${PIPER_VERSION:-v1.2.0}"
PIPER_DIR="${PIPER_DIR:-/opt/piper}"
PIPER_VOICES_DIR="${PIPER_VOICES_DIR:-$HOME/piper-voices}"
PIPER_VOICE="${PIPER_VOICE:-en_GB-alan-medium}"

NETRC_CREATED=0
NETRC_BACKUP=""

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Installs the AIS Plus suite onto a Raspberry Pi that already has Signal K
Server installed and configured with signalk-server-setup.

Options:
  --no-system-packages   Skip apt package installation
  --no-piper             Skip Piper and voice installation
  --no-restart           Do not restart Signal K at the end
  --help                 Show this help

Environment overrides:
  GITHUB_TOKEN                       GitHub token for private plugin repos
  REPO_OWNER                         GitHub owner, default: mcdonaldajr
  SIGNALK_HOME                       Signal K config directory, default: ~/.signalk
  AIS_PLUS_VERSION                   Default: $AIS_PLUS_VERSION
  AIS_PLUS_AUDIO_VERSION             Default: $AIS_PLUS_AUDIO_VERSION
  AIS_PLUS_COMPANION_VERSION         Default: $AIS_PLUS_COMPANION_VERSION
  AIS_PLUS_APPLE_WATCH_VERSION       Default: $AIS_PLUS_APPLE_WATCH_VERSION
  AI_SNAPSHOT_VERSION                Default: $AI_SNAPSHOT_VERSION
  CAPTURE_PLUS_VERSION               Default: $CAPTURE_PLUS_VERSION
  VESSEL_DATABASE_VERSION            Default: $VESSEL_DATABASE_VERSION
  HARBOUR_EDITOR_VERSION             Default: $HARBOUR_EDITOR_VERSION
  VESSEL_SIMULATOR_VERSION           Default: $VESSEL_SIMULATOR_VERSION
  SELF_TRACK_SIMULATOR_VERSION       Default: $SELF_TRACK_SIMULATOR_VERSION
  PI_CONTROLLER_VERSION              Default: $PI_CONTROLLER_VERSION
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

if [[ ! -d "$SIGNALK_HOME" ]]; then
  die "$SIGNALK_HOME does not exist. Run sudo signalk-server-setup first, then run this script."
fi

if [[ "$INSTALL_SYSTEM_PACKAGES" == "1" ]]; then
  log "Installing Raspberry Pi OS packages"
  sudo apt-get update
  sudo apt-get install -y \
    git curl ca-certificates build-essential python3 python3-pip \
    jq unzip tar gzip avahi-daemon avahi-utils libnss-mdns \
    libavahi-compat-libdnssd-dev alsa-utils ffmpeg sox mpg123
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

  case "$arch" in
    aarch64|arm64)
      local piper_asset="piper_linux_aarch64.tar.gz"
      ;;
    *)
      warn "Automatic Piper binary install is only configured for 64-bit Raspberry Pi OS. Skipping Piper for architecture: $arch"
      return
      ;;
  esac

  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/${piper_asset}" -o "$tmp/piper.tar.gz"
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

install_plugin() {
  local repo="$1"
  local version="$2"
  local url="git+https://github.com/${REPO_OWNER}/${repo}.git#${version}"

  log "Installing ${repo} ${version}"
  npm install "$url" --omit=dev --no-package-lock
}

setup_github_auth
install_piper

log "Installing Signal K plugins into $SIGNALK_HOME"
cd "$SIGNALK_HOME"

install_plugin "signalk-ais-plus" "$AIS_PLUS_VERSION"
install_plugin "signalk-ais-plus-audio" "$AIS_PLUS_AUDIO_VERSION"
install_plugin "signalk-ais-plus-companion" "$AIS_PLUS_COMPANION_VERSION"
install_plugin "signalk-ais-plus-apple-watch" "$AIS_PLUS_APPLE_WATCH_VERSION"
install_plugin "signalk-ai-snapshot" "$AI_SNAPSHOT_VERSION"
install_plugin "signalk-capture-plus" "$CAPTURE_PLUS_VERSION"
install_plugin "signalk-vessel-database" "$VESSEL_DATABASE_VERSION"
install_plugin "signalk-harbour-editor" "$HARBOUR_EDITOR_VERSION"
install_plugin "signalk-vessel-simulator" "$VESSEL_SIMULATOR_VERSION"
install_plugin "signalk-self-track-simulator" "$SELF_TRACK_SIMULATOR_VERSION"
install_plugin "signalk-pi-controller" "$PI_CONTROLLER_VERSION"

mkdir -p "$HOME/CapturePlusLogs/logs" "$HOME/CapturePlusLogs/clips"

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
4. Open AIS Plus at:
   https://<your-pi-hostname>:3443/signalk-ais-plus/

If browser behaviour looks stale after an update, hard refresh or clear site
data for the Signal K hostname.
EOF
