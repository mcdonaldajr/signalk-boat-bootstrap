# AIS Plus Suite Diagrams

This folder contains Pages-friendly high-resolution PNG exports and the Mermaid sources used to generate them.

## Diagrams

- [Full suite interaction diagram](ais-suite-full@4x.png)
- [Responsibility summary diagram](ais-suite-summary@4x.png)
- [Simplified core view](ais-suite-core-view@4x.png)

## Sources

- [Full suite interaction Mermaid source](ais-suite-full.mmd)
- [Responsibility summary Mermaid source](ais-suite-summary.mmd)
- [Simplified core view Mermaid source](ais-suite-core-view.mmd)

To regenerate a PNG from one of the Mermaid sources:

```bash
npx -y @mermaid-js/mermaid-cli -i docs/diagrams/ais-suite-full.mmd -o docs/diagrams/ais-suite-full@4x.png -b white -s 4
```
