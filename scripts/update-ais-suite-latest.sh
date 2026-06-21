#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_OWNER="${REPO_OWNER:-mcdonaldajr}"
SIGNALK_HOME="${SIGNALK_HOME:-$HOME/.signalk}"
RESTART_SIGNALK="${RESTART_SIGNALK:-1}"
INSTALL_REF_MODE="${INSTALL_REF_MODE:-tag}"
NETRC_CREATED=0
NETRC_BACKUP=""

PLUGINS=(
  signalk-notifications-plus
  signalk-watchkeeper-alerts
  signalk-ais-plus-engine
  signalk-ais-plus-display
  signalk-ais-plus-console
  signalk-audible-instruments
  signalk-instruments-plus
  signalk-ais-plus-audio
  signalk-ais-plus-companion
  signalk-ais-plus-apple-watch
  signalk-ai-snapshot
  signalk-capture-plus
  signalk-voyage-debugger
  signalk-vessel-database
  signalk-harbour-editor
  signalk-vessel-simulator
  signalk-self-track-simulator
  signalk-pi-controller
)

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Updates the Watchkeeper suite in ~/.signalk from GitHub.
By default it installs the newest v* semver tag for each plugin repository.

Options:
  --main          Install each plugin from the repository main branch instead of latest tag
  --no-restart    Do not restart Signal K at the end
  --help          Show this help

Environment overrides:
  REPO_OWNER      GitHub owner, default: mcdonaldajr
  SIGNALK_HOME    Signal K config directory, default: ~/.signalk
  GITHUB_TOKEN    Optional GitHub token for private repositories
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
    --main)
      INSTALL_REF_MODE="main"
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

command -v git >/dev/null 2>&1 || die "git is not installed."
command -v npm >/dev/null 2>&1 || die "npm is not installed. Install Signal K Server first."
command -v node >/dev/null 2>&1 || die "node is not installed. Install Signal K Server first."

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
  die "$SIGNALK_HOME does not exist. Run signalk-server-setup first, or set SIGNALK_HOME."
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

latest_tag_for_repo() {
  local repo="$1"
  local url="https://github.com/${REPO_OWNER}/${repo}.git"
  git ls-remote --tags --refs "$url" 'v*' \
    | awk -F/ '{ print $3 }' \
    | sort -V \
    | tail -n 1
}

install_plugin() {
  local repo="$1"
  local ref
  if [[ "$INSTALL_REF_MODE" == "main" ]]; then
    ref="main"
  else
    ref="$(latest_tag_for_repo "$repo")"
    [[ -n "$ref" ]] || die "Could not find a v* tag for ${repo}. Use --main to install from main."
  fi

  local url="git+https://github.com/${REPO_OWNER}/${repo}.git#${ref}"
  log "Installing ${repo} ${ref}"
  npm install "$url" --omit=dev --no-package-lock || {
    warn "Install failed for ${repo}; verifying npm cache and retrying once."
    npm cache verify || true
    npm install "$url" --omit=dev --no-package-lock
  }
}

log "Updating Watchkeeper suite in $SIGNALK_HOME"
setup_github_auth
cd "$SIGNALK_HOME"

for plugin in "${PLUGINS[@]}"; do
  install_plugin "$plugin"
done

if [[ "$RESTART_SIGNALK" == "1" ]]; then
  log "Restarting Signal K"
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart signalk || sudo systemctl restart signalk.service || warn "Could not restart Signal K with systemctl."
  else
    warn "systemctl is not available; restart Signal K manually."
  fi
fi

log "Watchkeeper suite update complete"
