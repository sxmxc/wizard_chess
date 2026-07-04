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
