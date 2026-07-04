# Wizard Chess

[![CI](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml/badge.svg)](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml)
[![Godot](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine)](https://godotengine.org/)

Wizard Chess is a deterministic, turn-based strategy game that combines traditional chess with a customizable trading card game.

Chess is always the foundation. Cards create exceptions to chess, but do not replace it.

## Current Status

- Godot project initialized
- GUT testing configured
- Log.gd enabled
- CI workflow added for tests and exports
- Linux and Windows export presets configured

## Project Structure

- `addons/` third-party and custom editor plugins
- `assets/` art, audio, and other source assets
- `content/` gameplay data stored as Resources
- `docs/` design and technical documentation
- `scenes/` presentation and application flow
- `scripts/` gameplay systems and application logic
- `tests/` automated tests
- `tools/` project-specific utilities and scripts

## Local Testing

Run the current GUT test suite with:

```powershell
godot --headless --path . --log-file .godot/gut.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests -ginclude_subdirs -gexit -gexit_on_success
```

The same command is used by the CI workflow.

## Milestone 1

Milestone 1 established the project foundation:

- Repository structure
- Coding conventions
- Automated testing
- Logging
- Basic configuration
- CI/CD pipeline
- Build pipeline

## Notes

- The project is being built for both digital and physical playability.
- Documentation should follow proven implementation details, not speculation.
- The simulation will remain the authoritative source of truth as gameplay systems are added.
