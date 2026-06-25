# AJRM Marine Architecture Baseline

Date: June 25, 2026

## Working installable suite

The bootstrap installs the public-beta AJRM Marine Suite applications:

| Repository | Baseline | Current role |
| --- | --- | --- |
| `@signalk/resources-provider` | `1.5.1` | Standard Signal K resources API provider; required for `Harbour:` regions used by AJRM Marine Auto Profile |
| `signalk-ajrm-marine-traffic` | `v0.5.0` | AJRM Marine Traffic; authoritative AIS decisions and notifications |
| `signalk-ajrm-marine-display` | `v0.5.0` | AJRM Marine Display; chart, targets, and alert view |
| `signalk-ajrm-marine-console` | `v0.5.1` | AJRM Marine Console; sailing workspace shell |
| `signalk-ajrm-marine-notifications` | `v0.5.0` | AJRM Marine Notifications; live cross-provider notification broker and diagnostics webapp |
| `signalk-ajrm-marine-alerts` | `v0.5.0` | AJRM Marine Alerts; read-only crew alert viewer |
| `signalk-ajrm-marine-audio` | `v0.5.2` | AJRM Marine Audio; speech rendering, queue, Pi speaker, and stream |
| `signalk-ajrm-marine-instrument-alerts` | `v0.5.0` | AJRM Marine Instrument Alerts; instrument threshold and rate-of-change provider |
| `signalk-ajrm-marine-instruments` | `v0.5.0` | AJRM Marine Instruments; display-only instrument application |
| `signalk-ajrm-marine-logger` | `v0.5.0` | AJRM Marine Logger; raw capture, replay, and clip extraction |
| `signalk-ajrm-marine-capture` | `v0.5.0` | AJRM Marine Capture; voyage-level capture orchestration and bundles |
| `signalk-ajrm-marine-voyage-viewer` | `v0.5.0` | AJRM Marine Voyage Viewer; voyage plotting and GPX export |
| `signalk-ajrm-marine-vessel-database` | `v0.5.0` | AJRM Marine Vessel Database; persistent vessel identity notes |
| `signalk-ajrm-marine-harbour-editor` | `v0.5.0` | AJRM Marine Harbour Editor; local harbour regions and default seed data |
| `signalk-ajrm-marine-pi-controller` | `v0.5.0` | AJRM Marine Pi Controller; Pi control and shutdown intent handling |
| `signalk-ajrm-marine-gps-integrity` | `v0.5.0` | AJRM Marine GPS Integrity; GNSS health and DR projections |
| `signalk-ajrm-marine-dr-plotter` | `v0.5.0` | AJRM Marine DR Plotter; dead-reckoning chart plotter |
| `signalk-ajrm-marine-simulator` | `v0.5.1` | AJRM Marine Simulator; own-vessel, environment, and AIS target simulator |

`@signalk/resources-provider` must remain enabled on the boat profile. Harbour
Editor writes `Harbour:` region resources through it, and AJRM Marine Traffic
reads the same Signal K regions collection for Auto Profile. If the provider is
disabled or unavailable, Auto Profile cannot see harbour limits after a reboot
and falls back to the configured outside profile, normally Coastal.

## Pi support services

The bootstrap also installs two non-Signal-K Pi support services:

| Service | Source | Current role |
| --- | --- | --- |
| `log2ram` | `https://github.com/azlux/log2ram` | Mounts `/var/log` in RAM to reduce SD-card wear from system and Signal K access logs |
| `powerDown` | `https://github.com/mcdonaldajr/powerDown` | Watches the UPS GPIO power-loss signal and shuts the Pi down safely after the configured grace period |

Diagnostic voyage files, Signal K Logger logs, and downloaded bundles remain on the
SD card deliberately; only low-value system logs are moved to RAM.

Key principles:

- align with standard Signal K architecture and remain useful to third-party
  applications;
- providers decide domain meaning;
- AJRM Marine Notifications owns generic live notification mechanics;
- AJRM Marine Audio owns the audible playback timeline;
- clients render authoritative projections;
- runtime alert/audio state does not survive Signal K restart;
- use Signal K-native debug logging, raw data logging, normalized capture, and
  history facilities for diagnosis.

## Release policy

- The AJRM Marine Suite is the default for fresh-card installs.
- New work proceeds additively behind versioned contracts.
- Old personal repositories remain historical references; fresh-card installs use the public `ajrm-marine-suite` repositories.
