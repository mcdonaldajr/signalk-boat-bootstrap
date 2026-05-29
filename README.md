# Signal K Boat Bootstrap

Scripts and notes for turning a freshly installed Raspberry Pi OS image into the Signal K/AIS Plus boat setup.

This repository intentionally does **not** install charts. Chart files are large and boat-specific, so copy or install those separately after the base system is working.

## What This Installs

The bootstrap script installs Raspberry Pi OS packages used by the AIS Plus suite, Piper speech support, and the Signal K plugins we use:

- `signalk-ais-plus`
- `signalk-ais-plus-audio`
- `signalk-ais-plus-companion`
- `signalk-ais-plus-apple-watch`
- `signalk-ai-snapshot`
- `signalk-capture-plus`
- `signalk-vessel-database`
- `signalk-harbour-editor`
- `signalk-vessel-simulator`
- `signalk-self-track-simulator`
- `signalk-pi-controller`

The script installs fixed, known-good tags by default. You can override any version with environment variables before running the script.

## Suite Release Tags

The default tags in this repository are kept as a coordinated AIS Plus suite. The current defaults install:

| Component | Default tag |
| --- | --- |
| AIS Plus | `v7.72.13` |
| AIS Plus Audio | `v1.2.0` |
| AIS Plus Companion | `v2.0.7` |
| AIS Plus Apple Watch | `v1.0.1` |
| AI Snapshot | `v0.1.8` |
| CapturePlus | `v1.0.2` |
| Vessel Database | `v1.0.0` |
| Harbour Editor | `v3.0.1` |
| Vessel Simulator | `v2.4.0` |
| Self Track Simulator | `v1.0.0` |
| Pi Controller | `v1.1.0` |

This set is intended to operate together and includes hull-aware CPA with fail-safe unknown-antenna handling, COLREG prompt wording, AIS Plus Audio announcements, Companion active/historical alert panels, Apple Watch compact alert feed support, AI Snapshot compact debug output, CapturePlus replay support, vessel metadata, harbour editing, simulators, and Pi control.

AIS Plus is the source of truth for vessel alert state. Companion shows current vessel risks in Active Alerts, moves cleared vessel alerts into Historical Alerts, and keeps recent spoken/system announcements separate. Apple Watch and other very small clients should read the compact AIS Plus feed rather than trying to recreate the full alert model.

## Suite Diagrams

High-resolution diagrams showing how the AIS Plus suite plugins interact are in [docs/diagrams](docs/diagrams/README.md). The folder includes PNG exports for Pages/documents and the Mermaid source files used to generate them.

## Start With Signal K

Run the official Signal K installation first. Signal K currently documents Raspberry Pi installation as:

1. Install Node.js and npm.
2. Install Signal K Server with npm.
3. Run the Signal K setup script:

   ```bash
   sudo signalk-server-setup
   ```

Follow the official Signal K documentation for the current install steps:

- [Signal K Raspberry Pi installation](https://demo.signalk.org/documentation/installation/raspberry_pi_installation.html)
- [Signal K installation overview](https://signalk.org/installation)

Only run the AIS Plus bootstrap after `signalk-server-setup` has created `~/.signalk`.

## GitHub Token

If all plugin repositories are public, no token is needed. If any plugin repository is private, create a GitHub token with read-only access to the repositories.

Recommended token setup:

1. Open [GitHub's new fine-grained token page](https://github.com/settings/personal-access-tokens/new).
2. Set **Token name** to `Pi AIS Plus updater`.
3. Set **Expiration** to a short expiry, for example 30 or 90 days.
4. Under **Repository access**, choose the AIS Plus plugin repositories, or choose all repositories if that is easier.
5. Under **Permissions > Repository permissions > Contents**, choose **Read-only**.
6. Generate the token and copy it immediately.

On the Pi, paste it into an environment variable for this one install session:

```bash
read -rsp "GitHub token: " GITHUB_TOKEN
echo
export GITHUB_TOKEN
```

The installer writes the token to a temporary `.netrc` file so `npm` and `git` can read private GitHub repositories. It removes the temporary file when the install finishes.

## Run From GitHub

Once this repository is public, the normal install command will be:

```bash
curl -fsSL https://raw.githubusercontent.com/mcdonaldajr/signalk-boat-bootstrap/main/scripts/install-ais-suite.sh -o install-ais-suite.sh
chmod +x install-ais-suite.sh
./install-ais-suite.sh
```

With a GitHub token:

```bash
read -rsp "GitHub token: " GITHUB_TOKEN
echo
export GITHUB_TOKEN
curl -fsSL https://raw.githubusercontent.com/mcdonaldajr/signalk-boat-bootstrap/main/scripts/install-ais-suite.sh -o install-ais-suite.sh
chmod +x install-ais-suite.sh
./install-ais-suite.sh
unset GITHUB_TOKEN
```

## Run From a Local Clone

```bash
git clone https://github.com/mcdonaldajr/signalk-boat-bootstrap.git
cd signalk-boat-bootstrap
./scripts/install-ais-suite.sh
```

## Options

```bash
./scripts/install-ais-suite.sh --help
```

Useful options:

- `--no-system-packages`: skip `apt` package installation.
- `--no-piper`: skip Piper binary and voice installation.
- `--no-restart`: do not restart Signal K at the end.

Useful environment overrides:

```bash
AIS_PLUS_VERSION=v7.72.13 ./scripts/install-ais-suite.sh
AI_SNAPSHOT_VERSION=v0.1.8 ./scripts/install-ais-suite.sh
REPO_OWNER=mcdonaldajr ./scripts/install-ais-suite.sh
SIGNALK_HOME=/home/pi/.signalk ./scripts/install-ais-suite.sh
```

## Updating To Latest GitHub Tags

To update an existing Pi to the latest released tags from GitHub:

```bash
read -rsp "GitHub token: " GITHUB_TOKEN
echo
export GITHUB_TOKEN
curl -fsSL https://raw.githubusercontent.com/mcdonaldajr/signalk-boat-bootstrap/main/scripts/update-ais-suite-latest.sh -o update-ais-suite-latest.sh
chmod +x update-ais-suite-latest.sh
./update-ais-suite-latest.sh
unset GITHUB_TOKEN
```

The updater writes `GITHUB_TOKEN` to a temporary `.netrc` file so `git` and `npm` can authenticate to private GitHub repositories. It restores any existing `.netrc` when the update finishes.

If you need to create the token first, open [GitHub's new fine-grained token page](https://github.com/settings/personal-access-tokens/new), name it `Pi AIS Plus updater`, set an expiry such as 30 or 90 days, grant repository **Contents: Read-only**, generate it, and paste it into the Pi prompt.

Use `./update-ais-suite-latest.sh --main` only when you deliberately want the newest main-branch code rather than the latest release tags.

## After Install

1. Open the Signal K Admin UI.
2. Log in as admin.
3. Enable and configure the installed plugins if Signal K has not enabled them automatically.
4. Open AIS Plus:

   ```text
   https://<your-pi-hostname>:3443/signalk-ais-plus/
   ```

5. Open AIS Plus Companion:

   ```text
   https://<your-pi-hostname>:3443/signalk-ais-plus-companion/
   ```

6. Open AI Snapshot when you need compact state for debugging or ChatGPT:

   ```text
   https://<your-pi-hostname>:3443/signalk-ai-snapshot/
   ```

7. Add charts separately.

## Notes

- The script should be run as the normal Pi user, not with `sudo`.
- The script uses `sudo` internally for operating-system packages, `/opt/piper`, and restarting Signal K.
- Piper is installed automatically on 64-bit Raspberry Pi OS. Other architectures are skipped with a warning.
- The default Piper voice is `en_GB-alan-medium`, installed into `~/piper-voices`.
- CapturePlus log directories are created at `~/CapturePlusLogs/logs` and `~/CapturePlusLogs/clips`.
- AI Snapshot omits the full AIS Plus harbour region list by default. Enable its harbour-list option only when debugging harbour geometry.
