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

Milestone 5 now extends that framework into prototype-complete card-type validation:

* `CardDefinition` carries explicit trigger and effect metadata rather than relying on hardcoded card-specific branches.
* `WizardMatch` tracks reaction priority and the current reaction window so Reaction cards validate against authoritative game events.
* Trap cards remain face-down on the battlefield, trigger from deterministic move outcomes, reveal, resolve, and then leave play.
* Environment cards replace previous Environments through match rules instead of presentation-side assumptions.
* Artifacts, Environments, Units, Traps, and temporary Reaction effects all register into an explicit `active_effects` state slice.
* Attached Unit effects move with their piece and are removed when the source card leaves play.

The prototype still does not implement bespoke card-text execution.

Instead, Milestone 5 proves the architectural boundary needed for future content work:

* Card-type timing and legality are simulation rules.
* Trigger windows are public deterministic state.
* Ongoing effects are represented as data in match state.
* Content can define trigger/effect metadata through Resources without embedding gameplay logic in UI or networking layers.

Milestone 5 is complete enough to treat as finished as of July 4, 2026.

The next architectural step belongs to Milestone 6: using this deterministic chess-plus-cards action surface to support AI evaluation and turn planning.

Milestone 6 now establishes that prototype boundary:

* `WizardMatchAiController` evaluates only the same public match/chess state available to a legal player and submits normal match actions back into `WizardMatch`.
* `WizardMatch` exposes clone/snapshot helpers and legal card-action enumeration so AI and UI do not duplicate authoritative rule validation.
* AI behavior differences live in `WizardMatchAiProfile` Resources, keeping difficulty and personality data-driven rather than hardcoded into scenes.
* The local Wizard Match dev screen exercises the same simulation and AI controller stack used by tests, preserving the simulation/presentation split.

This is intentionally still prototype scope.

The AI does not yet execute bespoke card-text logic beyond the existing framework metadata, but the architectural goal for Milestone 6 is now proven: a deterministic opponent can complete matches without bypassing the simulation.

Milestone 7 UI work now begins by restoring smaller presentation boundaries:

* Hand card fan layout lives in a reusable `HandFanView` presentation component instead of procedural fan math embedded directly in `LocalWizardMatchScreen`.
* The match screen still coordinates overall HUD state, but card positioning and targeting lift presentation are now derived by the hand view from semantic UI state rather than ad hoc per-card pixel edits spread across the screen script.
* The board presentation is moving away from draw-only piece placement toward square and piece nodes in the scene tree, which is a better fit for drag, hover, target preview, and future animation work.
* A dedicated presentation `EffectsLayer` now exists for targeting arcs and future transient UI effects so gameplay overlays do not compete with core board/HUD draw order.
* `CardInteractionController` owns presentation-only selection, drag, and targeting state; it does not validate or mutate gameplay.
* `TargetingOverlay` owns target arc and endpoint rendering, while the board exposes target emphasis as presentation derived from legal simulation actions.
* `WizardMatchInspectorView` owns card and square inspection composition and formatting; the match screen supplies selected simulation data and presentation textures through a small API.
* `WizardMatchHudSidebar` owns history, active-card, graveyard, match-settings, and AI-diagnostic controls. It emits semantic card IDs and settings changes rather than exposing list-index bookkeeping to the match screen. It is an extracted utility surface, not the intended permanent primary match HUD.
* `WizardMatchHudLayout` owns the board-relative opponent strip, local dock, utility drawer, and contextual inspector placement. Static piles and public-zone trays remain authored directly in `local_wizard_match_screen.tscn` so their table locations are visible and adjustable in the editor.
* The target match composition is three editor-visible gameplay regions: a compact opponent strip, an uninterrupted central chessboard, and a local player dock containing the readable hand and dominant phase action.
* The default local match scene now treats `WizardMatchHudSidebar` as a dismissible utility drawer opened from the header rather than a permanently reserved right column, which keeps developer tools available without taxing the primary match composition.
* The inspector is contextual by default: hidden when unused and positioned beside the board only while presenting an active square/card selection.
* Player identity, mana, hand, deck, and graveyard presentation should be spatially grouped by owner. Histories, full pile browsing, settings, and developer diagnostics belong in dismissible secondary surfaces.
* The gameplay board is a fixed authored 736x736 frame. Hand cards intentionally rest partly outside the viewport and reveal roughly half their height; transformed-bounds tests evaluate visible ratios, board exclusion, and readable hover/target states rather than requiring idle cards to be fully visible.
* The playmat is compositional rather than flattened. `table_base.png` owns only the table and board field; reusable hand-tray, card-well, portrait-frame, and utility-tray textures are placed by editor-authored scene nodes. Multiplayer views should reuse these components instead of generating a second monolithic playmat.
* Legal card targets retain their underlying chess-square colors and use compact markers, with stronger color reserved for the hovered target.
* Zero-target card dragging is semantic: releasing outside the local hand submits the existing legal card action, with no gameplay meaning assigned to pixel coordinates or a dedicated drop-zone node.

This keeps the UI moving back toward editor-first composition without changing the simulation boundary.

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
