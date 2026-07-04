# Wizard Chess

[![CI](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml/badge.svg)](https://github.com/sxmxc/wizard_chess/actions/workflows/ci.yml)
[![Godot](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine)](https://godotengine.org/)

Wizard Chess is a deterministic, turn-based strategy game that combines traditional chess with a customizable trading card game.

Chess is always the foundation. Cards create exceptions to chess, but do not replace it.

## Current Status

- Milestone 2 is complete enough to treat as finished
- Standard chess simulation implemented and playable through the default local hotseat scene
- GUT coverage added for legal moves, castling, en passant, promotion, checkmate, stalemate, and draw handling
- CI workflow still runs tests and exports for Linux and Windows
- Milestone 3 foundation started with a dedicated multiplayer bridge node, action payloads, and full-state snapshot sync
- Next major focus is Milestone 3: multiplayer foundation

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
godot --path . --host --port=7000
godot --path . --connect=127.0.0.1 --port=7000
```

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

## Milestone 3 Direction

The current chess implementation is intentionally still prototype-shaped. The `ChessMatch` script is functional, but it should not be treated as the final long-term multiplayer architecture.

Milestone 3 should focus on splitting responsibilities needed for server-authoritative play, including:

- Match state
- Move validation
- Move application and resolution
- Serialization for synchronization and replay
- Player action submission and server validation

Current prototype shape:

- `ChessMatch` now exposes action payload and snapshot methods that are safe to reuse for networking and replay work.
- `NetworkMatchBridge` centralizes all current RPC declarations under a stable `/root/Bootstrap/NetworkRoot/MatchBridge` path on both peers.
- Bootstrap keeps the RPC node alive while loading either local hotseat content or the first network chess screen.

## Notes

- The project is being built for both digital and physical playability.
- Documentation should follow proven implementation details, not speculation.
- The simulation will remain the authoritative source of truth as gameplay systems are added.
