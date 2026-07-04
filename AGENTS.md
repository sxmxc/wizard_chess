# AGENTS.md

## Wizard Chess Development Agent Guide

### Project Overview

Wizard Chess is a deterministic, server-authoritative multiplayer strategy game that combines traditional chess with a customizable trading card game.

The game is being developed in **Godot**.

The project is intended to be playable both digitally and physically. Every gameplay mechanic should be understandable and executable using only a chessboard, printed cards, and the rulebook.

---

# Core Philosophy

When making implementation decisions, always prioritize the following:

1. Chess is the foundation.
2. Cards create exceptions to chess.
3. Every mechanic must be deterministic.
4. Every rule must pass the "AI Test."
5. Complexity should emerge from interactions, not core rules.
6. Physical playability is a design constraint.
7. Maintainability is more important than cleverness.

---

# Development Philosophy

The project values:

* Small focused systems.
* Composition over inheritance.
* Data-driven content.
* Editor-first workflows.
* Readability over optimization.
* Simplicity over abstraction.
* Refactoring over accumulating technical debt.

Avoid implementing systems that solve hypothetical future problems.

---

# General Rules

Always:

* Build the smallest solution that satisfies the current requirement.
* Prefer reusable systems over one-off implementations.
* Prefer deterministic behavior.
* Write code that is easy to debug.
* Keep systems loosely coupled.
* Keep responsibilities clearly separated.

Never:

* Embed gameplay logic inside UI.
* Hardcode individual cards where a reusable system is appropriate.
* Duplicate gameplay rules.
* Introduce hidden state.
* Optimize without profiling.

---

# Architecture Principles

The simulation is the authoritative source of truth.

Presentation exists only to visualize the simulation.

Networking exists only to synchronize the simulation.

AI interacts with the simulation exactly as a player does.

Replay playback uses the same simulation.

---

# Gameplay Principles

Every gameplay feature should answer:

* Is it deterministic?
* Is it physically playable?
* Does it reinforce chess?
* Does it increase strategic depth?
* Does it remain readable?

If the answer is "No," reconsider the design.

---

# Content Principles

Gameplay content should be data-driven whenever practical.

Cards, Wizards, Schools, Keywords, and configuration values should be editable without modifying gameplay systems whenever possible.

Avoid card-specific code.

Prefer reusable gameplay effects.

---

# Networking Principles

Wizard Chess uses a server-authoritative model.

Clients submit actions.

Servers validate actions.

Servers resolve gameplay.

Clients present results.

Networking architecture should remain minimal until validated through prototypes.

Do not over-engineer networking before proving the architecture.

---

# Testing

Every gameplay system should be testable.

Core systems should support automated testing.

Bug fixes should include regression tests whenever practical.

---

# Refactoring

Continuously improve:

* Naming
* Folder organization
* Code clarity
* Separation of responsibilities

Avoid allowing technical debt to accumulate.

---

# Documentation

Whenever a significant architectural decision is made:

* Update the GDD if gameplay changes.
* Update ARCHITECTURE.md if implementation changes.
* Update the Rulebook if player-facing rules change.

Documentation is part of the implementation.

---

# AI Agent Expectations

When implementing features:

1. Read the relevant documentation.
2. Identify affected systems.
3. Produce a short implementation plan.
4. Implement incrementally.
5. Test immediately.
6. Refactor if necessary.
7. Update documentation.
8. Commit logical, self-contained changes.

Never make large architectural changes without first explaining why they are necessary.

---

# Project Goal

Build a maintainable, expandable, deterministic strategy game that could realistically support years of additional content without requiring major architectural rewrites.
