# DECISIONS.md

# Wizard Chess - Engineering Decision Log

## Purpose

This document records significant engineering and architectural decisions made during the development of Wizard Chess.

Unlike the Game Design Document (GDD), which describes **what** the game is, or `ARCHITECTURE.md`, which describes **how** the project should be organized, this document explains **why** important implementation decisions were made.

The goal is to preserve architectural intent and prevent future developers from repeating investigations or unintentionally undoing important decisions.

This document should evolve throughout the lifetime of the project.

---

# Decision Template

Each engineering decision should follow this format.

```markdown
## YYYY-MM-DD — Short Title

### Problem

What problem needed to be solved?

### Options Considered

- Option A
- Option B
- Option C

### Decision

What was chosen?

### Rationale

Why was this approach selected?

### Tradeoffs

What are the disadvantages or future considerations?

### Follow-up

Any future work, prototype validation, or items to revisit.
```

---

# Initial Engineering Decisions

## 2026-07-03 — Physical-First Rules

### Problem

The project needed a guiding principle for designing gameplay mechanics.

### Options Considered

* Design exclusively for digital gameplay.
* Design for both digital and physical play.

### Decision

Wizard Chess will be designed as a game that can be fully played using only a chessboard, printed cards, and the rulebook.

The digital version exists to automate gameplay, improve presentation, provide AI opponents, enable online multiplayer, and reduce bookkeeping.

### Rationale

This constraint naturally encourages deterministic rules, simpler interactions, easier balancing, and improved readability.

It also ensures the game remains understandable independently of its implementation.

### Tradeoffs

Some mechanics that would be easy to implement digitally may be rejected if they become impractical for tabletop play.

### Follow-up

Continue evaluating new mechanics against the physical-first philosophy.

---

## 2026-07-03 — Deterministic Gameplay

### Problem

The project required a foundation for multiplayer, replay support, AI, and testing.

### Options Considered

* Non-deterministic simulation.
* Deterministic simulation.

### Decision

All gameplay systems should be deterministic.

Given identical initial conditions and player actions, every simulation should produce the same outcome.

### Rationale

Determinism simplifies:

* Multiplayer
* Replay generation
* AI evaluation
* Automated testing
* Debugging

### Tradeoffs

Some mechanics may require additional design effort to preserve determinism.

### Follow-up

All future gameplay systems should be evaluated against deterministic simulation.

---

## 2026-07-03 — Server-Authoritative Multiplayer

### Problem

A multiplayer architecture was required.

### Options Considered

* Peer-to-peer.
* Lockstep simulation.
* Server-authoritative simulation.

### Decision

Wizard Chess will use a server-authoritative architecture.

Clients submit gameplay actions.

The server validates actions, resolves gameplay, and synchronizes the authoritative game state.

### Rationale

This approach provides strong competitive integrity, simplifies replay generation, and aligns well with deterministic simulation.

### Tradeoffs

Networking implementation is more complex than peer-to-peer approaches.

### Follow-up

Validate the networking architecture through an early Godot prototype before finalizing implementation details.

---

## 2026-07-03 — Prototype Before Optimization

### Problem

Future architectural decisions involve uncertainty, particularly regarding Godot networking.

### Options Considered

* Fully design networking before implementation.
* Prototype high-risk systems first.

### Decision

High-risk architectural assumptions should be validated through working prototypes before becoming permanent implementation.

### Rationale

Godot's multiplayer APIs, SceneTree requirements, RPC behavior, and synchronization constraints are best understood through practical experimentation rather than documentation alone.

### Tradeoffs

Some architectural documentation may need revision after prototyping.

### Follow-up

Networking architecture should remain intentionally conservative until prototype validation is complete.

---

# Decision Guidelines

Add a new entry whenever a significant implementation decision is made.

Examples include:

* Networking architecture changes.
* Resource hierarchy decisions.
* Scene organization.
* Replay implementation.
* Card system architecture.
* Event Queue revisions.
* Performance optimizations.
* Persistence strategy.
* Tooling changes.

Minor refactors, bug fixes, and stylistic changes should not be recorded unless they significantly affect the project's architecture.

---

# Guiding Principle

Documentation should record proven decisions—not speculation.

Whenever possible, decisions should be supported by working code, successful prototypes, profiling, or testing.

If implementation proves a previous decision incorrect, update this document rather than preserving outdated assumptions.
