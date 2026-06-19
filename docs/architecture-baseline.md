# AIS Plus Architecture Baseline

Date: June 19, 2026

## Working installable suite

The bootstrap continues to install the proven applications:

| Repository | Baseline | Current role |
| --- | --- | --- |
| `signalk-ais-plus` | `v8.0.0` | Combined AIS decision engine and rich chart app |
| `signalk-notifications-plus` | `v1.0.0` | Live cross-provider notification broker |
| `signalk-ais-plus-audio` | `v2.0.0` | Speech rendering, queue, Pi speaker, and stream |
| `signalk-ais-plus-companion` | `v3.0.0` | Phone-oriented alerts, activity, controls, and audio |
| `signalk-audible-instruments` | `v1.0.0` | Instrument threshold and rate-of-change provider |
| `signalk-instruments-plus` | `v1.0.0` | Display-only instrument application |

These major releases are baseline markers rather than rewrites. They preserve
the immediately preceding tested behavior.

## Future repositories

| Repository | Baseline | Status |
| --- | --- | --- |
| `signalk-ais-plus-engine` | `v0.1.0` | Private architecture scaffold; non-installable |
| `signalk-ais-plus-display` | `v0.1.0` | Private architecture scaffold; non-installable |

The future repositories are intentionally absent from both bootstrap scripts.
Adding them requires an explicit future decision, installable packages, tests,
Signal K contracts, and a migration/rollback procedure.

## Architecture authority

The private
[`ais-plus-architecture`](https://github.com/mcdonaldajr/ais-plus-architecture)
repository owns the suite-level proposal and architecture decisions.

Key principles:

- align with standard Signal K architecture and remain useful to third-party
  applications;
- providers decide domain meaning;
- Notifications Plus owns generic live notification mechanics;
- AIS Plus Audio owns the audible playback timeline;
- clients render authoritative projections;
- runtime alert/audio state does not survive Signal K restart;
- use Signal K-native debug logging, raw data logging, normalized capture, and
  history facilities for diagnosis.

## Release policy

- The current combined suite remains the default until the new Engine and
  Display are demonstrably better and operationally safe.
- New architecture work proceeds additively behind versioned contracts.
- Do not remove existing packages from bootstrap during experiments.
- Every migration stage needs a documented rollback to this baseline.
