# Watchkeeper Boat Bootstrap

Scripts and notes for turning a freshly installed Raspberry Pi OS image into the Signal K/Watchkeeper boat setup.

This repository intentionally does **not** install charts. Chart files are large and boat-specific, so copy or install those separately after the base system is working.

## What This Installs

The bootstrap script installs Raspberry Pi OS packages used by the Watchkeeper suite, Pi support services, Piper speech support, and the Signal K plugins we use.

Support services:

- [`log2ram`](https://github.com/azlux/log2ram): mounts `/var/log` in RAM to reduce SD-card wear from chatty system and Signal K access logs. Voyage data remains on disk.
- [`powerDown`](https://github.com/mcdonaldajr/powerDown): UPS GPIO auto-shutdown service. By default it watches BCM GPIO 24 and shuts the Pi down if power is not restored within the configured grace period.

Signal K plugins:

- `signalk-ais-plus-engine` (Watchkeeper Traffic)
- `signalk-ais-plus-display` (Watchkeeper Display)
- `signalk-ais-plus-console` (Watchkeeper Console)
- `signalk-notifications-plus`
- `signalk-ais-plus-audio`
- `signalk-ais-plus-companion`
- `signalk-audible-instruments`
- `signalk-instruments-plus`
- `signalk-ais-plus-apple-watch`
- `signalk-ai-snapshot`
- `signalk-capture-plus` (Signal K Logger)
- `signalk-voyage-debugger` (Watchkeeper Capture)
- `signalk-vessel-database`
- `signalk-harbour-editor`
- `signalk-vessel-simulator`
- `signalk-self-track-simulator`
- `signalk-pi-controller`

The script installs fixed, known-good tags by default. You can override any version with environment variables before running the script.

## Suite Release Tags

The default tags in this repository are kept as a coordinated Watchkeeper suite. The current defaults install:

| Component | Default tag |
| --- | --- |
| Watchkeeper Traffic | `v0.8.3` |
| Watchkeeper Display | `v2.2.5` |
| Watchkeeper Console | `v0.3.7` |
| Watchkeeper Notifications | `v1.0.3` |
| Watchkeeper Audio | `v2.3.3` |
| Watchkeeper Companion | `v3.3.2` |
| Watchkeeper Instrument Alerts | `v1.0.2` |
| Watchkeeper Instruments | `v1.1.2` |
| AIS Plus Apple Watch | `v1.0.1` |
| AI Snapshot | `v0.2.1` |
| Signal K Logger | `v1.2.1` |
| Watchkeeper Capture | `v0.1.10` |
| Vessel Database | `v1.0.0` |
| Harbour Editor | `v3.0.1` |
| Vessel Simulator | `v2.4.0` |
| Self Track Simulator | `v1.2.2` |
| Pi Controller | `v1.2.0` |

This set is the coordinated working baseline for the split Watchkeeper
architecture.

Watchkeeper Traffic owns AIS decisions. Watchkeeper Notifications brokers live
cross-provider notifications. Watchkeeper Audio renders speech. Watchkeeper
Companion presents active alerts plus recent activity. Watchkeeper Display owns
the chart view, and Watchkeeper Console provides the sailing workspace.

## Architecture Transition

The simulator migration to the split architecture is complete. Bootstrap now
installs the split Watchkeeper components only. During the naming migration, npm
package names, plugin ids, and Signal K paths intentionally keep their existing
`signalk-*` / `aisPlus*` compatibility names; the full package rename is planned
for the fresh SD-card install window.

Suite architecture, Signal K integration rules, and observability requirements
are maintained in the private
[`ais-plus-architecture`](https://github.com/mcdonaldajr/ais-plus-architecture)
repository.

See [Architecture Baseline](docs/architecture-baseline.md) for the repository
roles and release policy.

## Suite Diagrams

High-resolution diagrams showing how the Watchkeeper suite plugins interact are in [docs/diagrams](docs/diagrams/README.md). The folder includes PNG exports for Pages/documents and the Mermaid source files used to generate them.

## Start With Signal K

Run the official Signal K installation first. Watchkeeper Bootstrap does not
install Node.js, npm, or Signal K Server; it checks the already-installed
runtime before installing the Watchkeeper apps.

For a fresh Raspberry Pi card, use the current Signal K recommendation:
Node.js 24.x with npm 11 or later. Current Signal K Server releases require
Node.js 22 or later, but Node.js 24 is the better clean-install target.

Signal K currently documents Raspberry Pi installation as:

1. Install Node.js and npm.
2. Install Signal K Server with npm.
3. Run the Signal K setup script:

   ```bash
   sudo signalk-server-setup
   ```

Follow the official Signal K documentation for the current install steps:

- [Signal K Raspberry Pi installation](https://demo.signalk.org/documentation/installation/raspberry_pi_installation.html)
- [Signal K installation overview](https://signalk.org/installation)

Only run the Watchkeeper bootstrap after `signalk-server-setup` has created `~/.signalk`.
The Bootstrap installer fails fast on Node.js older than 22, warns on Node.js
22/23, and prints the detected Node.js/npm versions at startup.

## GitHub Token

If all plugin repositories are public, no token is needed. If any plugin repository is private, create a GitHub token with read-only access to the repositories.

Recommended token setup:

1. Open [GitHub's new fine-grained token page](https://github.com/settings/personal-access-tokens/new).
2. Set **Token name** to `Pi Watchkeeper updater`.
3. Set **Expiration** to a short expiry, for example 30 or 90 days.
4. Under **Repository access**, choose the Watchkeeper plugin repositories, or choose all repositories if that is easier.
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
- `--no-log2ram`: skip `/var/log` RAM logging support.
- `--no-powerdown`: skip the UPS GPIO shutdown service.
- `--no-piper`: skip Piper binary and voice installation.
- `--no-restart`: do not restart Signal K at the end.

Useful environment overrides:

```bash
WATCHKEEPER_TRAFFIC_VERSION=v0.8.3 ./scripts/install-ais-suite.sh
AI_SNAPSHOT_VERSION=v0.2.1 ./scripts/install-ais-suite.sh
REPO_OWNER=mcdonaldajr ./scripts/install-ais-suite.sh
SIGNALK_HOME=/home/pi/.signalk ./scripts/install-ais-suite.sh
POWERDOWN_INSTALL_DIR=/opt/powerDown ./scripts/install-ais-suite.sh
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

If you need to create the token first, open [GitHub's new fine-grained token page](https://github.com/settings/personal-access-tokens/new), name it `Pi Watchkeeper updater`, set an expiry such as 30 or 90 days, grant repository **Contents: Read-only**, generate it, and paste it into the Pi prompt.

Use `./update-ais-suite-latest.sh --main` only when you deliberately want the newest main-branch code rather than the latest release tags.

## After Install

1. Open the Signal K Admin UI.
2. Log in as admin.
3. Enable and configure the installed plugins if Signal K has not enabled them automatically.
4. Open Watchkeeper Console:

   ```text
   https://<your-pi-hostname>:3443/signalk-ais-plus-console/
   ```

5. Open Watchkeeper Companion:

   ```text
   https://<your-pi-hostname>:3443/signalk-ais-plus-companion/
   ```

6. Open AI Snapshot when you need compact state for debugging or ChatGPT:

   ```text
   https://<your-pi-hostname>:3443/signalk-ai-snapshot/
   ```

7. Add charts separately.
8. Verify the Pi support services:

   ```bash
   systemctl status log2ram --no-pager
   df -h /var/log
   sudo systemctl status powerDown.service --no-pager
   ```

## Notes

- The script should be run as the normal Pi user, not with `sudo`.
- The script uses `sudo` internally for operating-system packages, log2ram, powerDown, `/opt/piper`, and restarting Signal K.
- log2ram keeps normal system logs in RAM and syncs them back according to its own defaults. Signal K Logger and Watchkeeper Capture files are intentionally kept on disk under `~/CapturePlusLogs`.
- powerDown defaults to BCM GPIO 24, matching the `mcdonaldajr/powerDown` repository. Use `--no-powerdown` if the UPS shutdown signal is not fitted.
- Piper is installed automatically on 64-bit Raspberry Pi OS. Other architectures are skipped with a warning.
- The default Piper voice is `en_GB-alan-medium`, installed into `~/piper-voices`.
- Signal K Logger directories are created at `~/CapturePlusLogs/buffer`, `~/CapturePlusLogs/captures`, `~/CapturePlusLogs/clips`, and `~/CapturePlusLogs/voyages`.
- AI Snapshot omits the full AIS Plus harbour region list by default. Enable its harbour-list option only when debugging harbour geometry.
