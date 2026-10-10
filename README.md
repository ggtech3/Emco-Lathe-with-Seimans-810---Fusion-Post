# Emco / Siemens 810T Fusion post processor

## Current baseline

The owner confirmed on October 10, 2026 that **v9**, `siemens-810t-turning-emco342-ggtech-v9.cps`, is currently in use. Preserve this file as the starting baseline. Machine-tested operations and controller configuration have not yet been documented. This organization change does not alter post code or establish additional machine validation.

Existing CPS filenames remain in place. Historical versions, where present, are retained. Fusion installation/library location must be confirmed before deploying future updates.

## Development

Read AGENTS.md, docs/machine-configuration.md and tests/README.md. Develop on a separate branch, record changes in CHANGELOG.md, compare posted NC output, and review before merging. Use GitHub releases/tags to identify future reviewed versions. Do not call a revision machine-proven without recorded owner validation.
