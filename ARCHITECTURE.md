# ARCHITECTURE.md

# Wizard Chess Architecture

## Purpose

This document describes the architectural philosophy of Wizard Chess.

It complements the Game Design Document by describing how gameplay systems should be organized and interact.

This document is expected to evolve throughout development as architectural decisions are validated through prototypes.

---

# Guiding Principles

* Deterministic simulation.
* Server-authoritative multiplayer.
* Data-driven gameplay.
* Composition over inheritance.
* Editor-first workflows.
* Physical-first game rules.
* Modular systems.
* Clear separation of responsibilities.

---

# High-Level Architecture

```text
                    Client
        ------------------------------
        UI
        Animation
        Audio
        Input
        Rendering
               │
               ▼
        Networking Layer
               │
=============== Network ===============
               │
               ▼
        Networking Layer
               │
        Match Controller
               │
        Gameplay Simulation
        ├── Rules Engine
        ├── Event Queue
        ├── Match State
        ├── Chess
        ├── Cards
        ├── Turn Manager
        ├── Mana
        ├── Victory Detection
        └── Replay Recording
```

The Gameplay Simulation is the authoritative source of truth.

Everything else exists to support or visualize it.

---

# Core Systems

The project is divided into independent systems.

Examples include:

* Match
* Simulation
* Rules
* Chess
* Cards
* Event Queue
* AI
* Networking
* Replay
* Persistence
* UI
* Audio

Each system should expose a small, well-defined public interface.

---

# Simulation

The simulation owns gameplay.

Responsibilities include:

* Board state
* Piece state
* Card resolution
* Turn progression
* Mana
* Victory conditions
* Effect resolution
* Event generation

The simulation should not depend on presentation systems.

---

# Presentation

Presentation is responsible only for displaying gameplay.

Examples include:

* Board visuals
* Piece visuals
* Cards
* Animations
* UI
* Effects
* Audio

Presentation must never determine gameplay outcomes.

---

# Event Queue

All gameplay interactions resolve through the Event Queue.

Player actions generate game events.

Game events may generate additional game events.

The Event Queue resolves events deterministically until empty.

The queue is responsible for gameplay resolution.

Presentation observes the results.

---

# Data-Driven Content

Gameplay content should primarily be represented as Godot Resources.

Examples:

* Cards
* Wizards
* Schools
* Keywords
* AI Profiles
* Configuration

Resources should describe gameplay data.

Reusable gameplay systems execute that data.

---

# Networking

Networking is server-authoritative.

Clients submit gameplay actions.

The server validates actions.

The server executes gameplay.

The server synchronizes results.

RPC usage should remain centralized and minimal.

Networking implementation details should be validated through prototypes before becoming permanent architecture.

---

# Replay

Replays should reproduce gameplay using:

* Initial state
* Match seed
* Player actions

The replay system should execute the same gameplay systems used during live matches.

---

# Current Prototype Boundary

Milestone 2 introduces a deterministic chess simulation as the first authoritative gameplay system.

The current playable stack is intentionally small:

* `ChessMatch` currently exposes the playable chess API, but the underlying rules/data split now lives in `ChessEngine` and `ChessState`.
* The local chess screen only reads from `ChessMatch` and submits move intents back into it.
* Automated tests exercise the same `ChessMatch` API used by the playable scene.

This keeps the simulation reusable for future multiplayer, AI, and replay work.

This boundary is intentionally provisional.

`ChessMatch` originally centralized several responsibilities so Milestone 2 could validate complete standard chess quickly. That was acceptable for the prototype, but it is not the desired final multiplayer architecture.

Milestone 3 should use the working rules implementation as a baseline while splitting responsibilities into smaller simulation-facing systems, especially around:

* Match state ownership
* Action validation
* Deterministic move resolution
* State serialization and synchronization
* Replay-safe and network-safe public interfaces

The first Milestone 3 networking prototype now adds:

* Action payload submission into `ChessMatch` rather than direct state mutation across the network boundary.
* Full-state snapshot serialization for authoritative synchronization.
* A single dedicated RPC bridge node kept at a stable `/root/Bootstrap/NetworkRoot/MatchBridge` path on both client and server.

This keeps RPC behavior centralized and aligned with Godot's high-level multiplayer constraints while the broader multiplayer architecture is still being validated.

Milestone 4 completes the initial split of match-level responsibilities above the chess core:

* `WizardMatch` now owns match-level state, including the chess-state slice used for full Wizard Chess matches.
* `ChessEngine` owns chess rules evaluation and mutation against a supplied `ChessState`.
* `ChessMatch` remains as a compatibility wrapper while older chess-only systems are migrated.
* Match phases, setup flow, mana, decks, hands, graveyards, and a FIFO event queue now live outside the chess rules engine.
* Card and deck data are represented as Resources, keeping content loading separate from simulation logic.

This keeps chess deterministic and reusable while creating a clear place for future card resolution work.

Milestone 4 is therefore complete enough to treat as finished.

The next architectural step belongs to Milestone 5: extending the framework into full card-type resolution and richer effect handling.

---

# Artificial Intelligence

The AI should interact with gameplay through the same interfaces as a human player.

The AI should never directly modify simulation state.

---

# Godot Philosophy

The project embraces Godot rather than abstracting away from it.

Preferred patterns include:

* Resources
* Composition
* Small focused scenes
* Small focused scripts
* Signals where appropriate
* Editor tooling

Avoid unnecessary abstraction or architecture imported from other engines.

---

# Folder Organization

The project should remain organized by responsibility.

Top-level structure:

```text
addons/
assets/
content/
docs/
scenes/
scripts/
tests/
tools/
```

As the project grows, folders may be subdivided while preserving clear ownership and responsibilities.

---

# Prototype First

Architectural assumptions should be proven through working prototypes.

If a prototype contradicts this document, update the architecture rather than forcing the implementation to match outdated assumptions.

Working code should inform future architectural decisions.

---

# Long-Term Vision

Wizard Chess should remain maintainable for many years.

The architecture should support:

* Hundreds of cards
* Additional Wizards
* Multiple expansions
* New game modes
* Dedicated servers
* Replay analysis
* AI improvements
* Community-created content

Every architectural decision should be evaluated against that long-term vision while remaining as simple as practical today.
