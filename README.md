# Wizard Chess

[![CI](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml/badge.svg)](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml)
[![Godot](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine)](https://godotengine.org/)

Wizard Chess is a deterministic, turn-based strategy game that combines traditional chess with a customizable trading card game.

Chess is always the foundation. Cards create exceptions to chess, but do not replace it.

## Current Status

- Milestone 3 is complete enough to treat as finished
- Milestone 4 is complete enough to treat as finished
- Standard chess simulation implemented and playable through the default local hotseat scene
- GUT coverage added for legal moves, castling, en passant, promotion, checkmate, stalemate, and draw handling
- CI workflow still runs tests and exports for Linux and Windows
- Dedicated multiplayer bridge validates server-authoritative chess with reconnect-oriented session handling
- `WizardMatch` now owns match state, mulligan flow, turn phases, mana, deck/hand/graveyard state, basic target validation, and explicit hand-limit discard flow
- `ChessEngine` and `ChessState` now separate chess rules from chess-owned data, while `ChessMatch` remains as a compatibility wrapper
- Non-headless development runs now open a launcher screen for local, host, or connect flows
- Next major focus is Milestone 5: core card system

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

For local headless Godot commands in this environment, always pass an explicit `--log-file` path. Without it, Godot may try to write under `user://` and fail before validation completes.

Examples:

```powershell
godot --headless --path . --log-file .godot/check-only.log --check-only
godot --headless --path . --log-file .godot/local-scene.log --scene res://scenes/chess/local_chess_screen.tscn --quit-after 2
godot --headless --path . --log-file .godot/server.log --server --port=7000
godot --path . --host --port=7000 --profile=host_a
godot --path . --connect=127.0.0.1 --port=7000 --profile=client_a
godot --path . --connect=127.0.0.1 --port=7000 --profile=client_b
```

Running the project normally in the editor or with `godot --path .` now opens a development launcher instead of dropping straight into local hotseat. Use that screen to:

- Play local hotseat
- Host a network match
- Connect to a running server by IP and port

For local multiplayer testing on one machine:

- Run the dedicated server with `--server`
- Run each player client with a different `--profile`
- If using the editor launcher, the `Client Profile` field should also be different for each local client
- Dedicated servers do not use client profiles

Examples:

- Host machine client profile: `host_a`
- First standalone client profile: `client_a`
- Second standalone client profile: `client_b`

Reconnect behavior in the prototype:

- A client reconnects by reusing the same `address:port:profile`
- The reconnect token is stored under `user://network_session.cfg`
- Two live clients must never share the same profile for the same server endpoint

The multiplayer bridge now also emits explicit lifecycle logs for:

- Server startup
- Client startup
- Peer connect and disconnect
- Seat assignment
- Action submission, acceptance, and rejection
- Snapshot broadcast and apply

Log prefixes:

- Dedicated server and host-side authority logs: `[Server][NetworkMatchBridge]`
- Remote client logs: `[Client][NetworkMatchBridge]`
- Startup flow logs: `[Bootstrap][Server]`, `[Bootstrap][Host]`, `[Bootstrap][Client]`, `[Bootstrap][Launcher]`

## Milestone 2

Milestone 2 delivers a playable game of standard chess on top of the Milestone 1 foundation:

- Chessboard
- Legal movement and capture resolution
- Check, checkmate, and stalemate detection
- Castling, en passant, and promotion
- Move history and draw handling for insufficient material, threefold repetition, and the fifty-move rule

Milestone 2 exit status:

- Two local players can complete an entire game of standard chess
- The rules engine is covered by automated tests
- Further work on chess should now be driven by Milestone 3 networking needs rather than standalone feature polish

## Milestone 4 Status

Milestone 4 is now complete enough to treat as finished. `WizardMatch` owns the authoritative match framework above the chess layer, while `ChessEngine` owns chess rules and `ChessState` carries the embedded chess-state slice.

Validated framework areas:

- Match state and phase ownership
- Setup flow and mulligans
- Mana, deck, hand, and graveyard state
- FIFO game event processing
- Data-driven card and deck resources
- Phase-aware card and chess action flow
- Basic deck and target validation
- Explicit end-phase hand-limit discard choice

Current prototype shape:

- `ChessEngine` now owns deterministic standard chess rules, while `WizardMatch` owns the embedded chess-state slice used during full Wizard Chess matches.
- `ChessMatch` remains as a compatibility wrapper for the existing chess-only scenes, tests, and multiplayer bridge.
- `WizardMatch` owns setup, phases, mana refresh, card zones, mulligans, target validation, and hand-limit discard flow.
- Card and deck definitions are now represented as Resources under `content/`.
- `NetworkMatchBridge` still synchronizes chess-only play; networking integration with `WizardMatch` has not started yet.

## Milestone 3 Validation

Use the checklist in [docs/MILESTONE_3_VALIDATION.md](/D:/Projects/Godot/4/wizard-chess/docs/MILESTONE_3_VALIDATION.md:1) when doing final milestone-3 multiplayer validation.

## Milestone 4 Validation

Use the checklist in [docs/MILESTONE_4_VALIDATION.md](/D:/Projects/Godot/4/wizard-chess/docs/MILESTONE_4_VALIDATION.md:1) when doing final milestone-4 gameplay-framework validation.

## Notes

- The project is being built for both digital and physical playability.
- Documentation should follow proven implementation details, not speculation.
- The simulation will remain the authoritative source of truth as gameplay systems are added.
