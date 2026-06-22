# Watchkeeper Architecture Baseline

Date: June 21, 2026

## Working installable suite

The bootstrap installs the proven split Watchkeeper applications:

| Repository | Baseline | Current role |
| --- | --- | --- |
| `signalk-ais-plus-engine` | `v0.8.3` | Watchkeeper Traffic; authoritative AIS decisions and notifications |
| `signalk-ais-plus-display` | `v2.2.10` | Watchkeeper Display; chart, targets, and alert view |
| `signalk-ais-plus-console` | `v0.3.9` | Watchkeeper Console; sailing workspace shell |
| `signalk-notifications-plus` | `v1.0.4` | Watchkeeper Notifications; live cross-provider notification broker and diagnostics webapp |
| `signalk-watchkeeper-alerts` | `v0.1.1` | Watchkeeper Alerts; read-only crew alert viewer with local device audio |
| `signalk-ais-plus-audio` | `v2.3.3` | Watchkeeper Audio; speech rendering, queue, Pi speaker, and stream |
| `signalk-ais-plus-companion` | `v3.3.2` | Watchkeeper Companion; frozen fallback during read-only Alerts migration |
| `signalk-ais-plus-apple-watch` | `v1.0.1` | AIS Plus Apple Watch; frozen fallback during read-only Alerts migration |
| `signalk-audible-instruments` | `v1.0.2` | Watchkeeper Instrument Alerts; instrument threshold and rate-of-change provider |
| `signalk-instruments-plus` | `v1.2.2` | Watchkeeper Instruments; display-only instrument application |
| `signalk-capture-plus` | `v1.2.1` | Signal K Logger; raw capture, replay, and clip extraction |
| `signalk-voyage-debugger` | `v0.1.10` | Watchkeeper Capture; voyage-level capture orchestration and bundles |

Package names and Signal K paths intentionally keep their old compatibility
names until the planned fresh-card package rename.

## Pi support services

The bootstrap also installs two non-Signal-K Pi support services:

| Service | Source | Current role |
| --- | --- | --- |
| `log2ram` | `https://github.com/azlux/log2ram` | Mounts `/var/log` in RAM to reduce SD-card wear from system and Signal K access logs |
| `powerDown` | `https://github.com/mcdonaldajr/powerDown` | Watches the UPS GPIO power-loss signal and shuts the Pi down safely after the configured grace period |

Diagnostic voyage files, Signal K Logger logs, and downloaded bundles remain on the
SD card deliberately; only low-value system logs are moved to RAM.

## Architecture authority

The private
[`ais-plus-architecture`](https://github.com/mcdonaldajr/ais-plus-architecture)
repository owns the suite-level proposal and architecture decisions.

Key principles:

- align with standard Signal K architecture and remain useful to third-party
  applications;
- providers decide domain meaning;
- Watchkeeper Notifications owns generic live notification mechanics;
- Watchkeeper Audio owns the audible playback timeline;
- clients render authoritative projections;
- runtime alert/audio state does not survive Signal K restart;
- use Signal K-native debug logging, raw data logging, normalized capture, and
  history facilities for diagnosis.

## Release policy

- The split Watchkeeper suite is the default for fresh-card installs.
- New work proceeds additively behind versioned contracts.
- Every package/internal rename needs a documented rollback to this baseline.
