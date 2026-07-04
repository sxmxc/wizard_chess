## Overview

Development of Wizard Chess should proceed through a series of well-defined milestones.

Each milestone should produce a stable, playable build that validates the systems introduced during that stage.

Features should be implemented incrementally, with emphasis placed on architecture, testing, and maintainability before content creation.

The project should remain in a playable state throughout development.

---

# Milestone 1 - Project Foundation

## Goals

Establish the core project architecture and development workflow.

## Deliverables

- Godot project initialized.
    
- Repository structure established.
    
- Coding conventions documented.
    
- Automated testing framework configured.
    
- Logging framework.
    
- Basic debugging tools.
    
- CI/CD pipeline.
    
- Build pipeline.
    
- Basic configuration system.
    

## Exit Criteria

The project can be built, tested, and executed consistently by all developers.

---

# Milestone 2 - Core Chess

## Goals

Implement a complete game of traditional chess.

## Deliverables

- Chessboard.
    
- Piece movement.
    
- Capturing.
    
- Check.
    
- Checkmate.
    
- Stalemate.
    
- Pawn promotion.
    
- Legal move validation.
    
- Move history.
    

## Exit Criteria

Two players can complete an entire game of standard chess.

---

# Milestone 3 - Multiplayer Foundation

## Goals

Validate the networking architecture.

## Deliverables

- Dedicated server.
    
- Client connection.
    
- Server-authoritative gameplay.
    
- Basic synchronization.
    
- Disconnect handling.
    
- Initial reconnect support.
    
- Networking diagnostics.
    

## Exit Criteria

Two players can reliably complete a networked game of chess.

---

# Milestone 4 - Gameplay Framework

## Goals

Introduce the systems required to support Wizard Chess.

## Deliverables

- Match state.
    
- Turn phases.
    
- Mana system.
    
- Decks.
    
- Hands.
    
- Graveyards.
    
- Event Queue.
    
- Card framework.
    
- Resource loading.
    

## Exit Criteria

The game framework is capable of supporting cards.

---

# Milestone 5 - Core Card System

Status: Complete as of July 4, 2026.

## Goals

Validate every card type.

## Deliverables

- Unit cards.
    
- Spell cards.
    
- Reaction cards.
    
- Trap cards.
    
- Environment cards.
    
- Artifact cards.
    
- Card validation.
    
- Card resolution.
    
- Attached Units.
    
- Active effects.
    

## Exit Criteria

Every supported card type functions correctly within a multiplayer match.

## Completion Notes

- Unit, Spell, Reaction, Trap, Environment, and Artifact card flows are validated in the authoritative simulation.
- Card timing, targeting, reaction priority, trap triggering, Environment replacement, and active-effect tracking are implemented in `WizardMatch`.
- Automated regression coverage for the Milestone 5 framework passes in headless test runs.
- Production gameplay UI for exercising these systems interactively remains Milestone 7 work.

---

# Milestone 6 - Artificial Intelligence

Status: Complete as of July 4, 2026.

## Goals

Implement the first playable AI opponent.

## Deliverables

- Chess evaluation.
    
- Card evaluation.
    
- Turn planning.
    
- Difficulty levels.
    
- AI personalities.
    

## Exit Criteria

Players can complete full matches against AI opponents.

## Completion Notes

- `WizardMatchAiController` now drives setup, preparation, move, reaction, and end-phase decisions entirely through the authoritative `WizardMatch` action API.
- Chess move choice uses deterministic evaluation with material, mobility, center control, king safety, and check/checkmate pressure, with search depth varying by AI profile.
- Card play evaluation and turn planning are implemented for the prototype card framework, including legal target enumeration, reaction timing, trap placement, and hand-limit discards.
- Difficulty and personality are represented through data-driven `WizardMatchAiProfile` Resources, with starter aggressive and positional profiles under `content/ai/`.
- A local Wizard Match development screen now supports human-vs-AI and AI-vs-AI testing with board interaction, card-play controls, summaries, and event logs.

---

# Milestone 7 - User Interface

## Goals

Replace prototype interfaces with production-quality gameplay UI.

## Deliverables

- Match HUD.
    
- Piece inspection.
    
- Card inspection.
    
- Graveyard interface.
    
- Move history.
    
- Notifications.
    
- Threat overlay.
    
- Settings.
    

## Exit Criteria

The interface is suitable for extended play.

---

# Milestone 8 - Replay & Persistence

## Goals

Implement long-term gameplay support.

## Deliverables

- Replay system.
    
- Match recording.
    
- Replay playback.
    
- Save system.
    
- Settings persistence.
    
- Statistics.
    

## Exit Criteria

Matches can be replayed and player progress persists correctly.

---

# Milestone 9 - Content Pipeline

## Goals

Complete the production workflow for gameplay content.

## Deliverables

- Card authoring workflow.
    
- Wizard authoring workflow.
    
- Validation tools.
    
- Balance configuration.
    
- Content import/export.
    
- Editor tooling.
    

## Exit Criteria

New gameplay content can be created efficiently without modifying gameplay systems.

---

# Milestone 10 - Core Set

## Goals

Develop the first playable card set.

## Deliverables

- Core Wizards.
    
- Core Schools.
    
- Initial card pool.
    
- Starter decks.
    
- AI deck support.
    
- Initial balancing.
    

## Exit Criteria

Wizard Chess is fully playable using the Core Set.

---

# Milestone 11 - Game Modes

## Goals

Expand gameplay beyond standard matches.

## Deliverables

- Casual play.
    
- Ranked play.
    
- Practice mode.
    
- Spectator mode.
    
- Replay viewer.
    
- Additional game options.
    

## Exit Criteria

Players can enjoy multiple styles of play.

---

# Milestone 12 - Polish

## Goals

Prepare the game for public testing.

## Deliverables

- Visual polish.
    
- Animations.
    
- Audio.
    
- Performance optimization.
    
- Accessibility improvements.
    
- Bug fixing.
    
- Balance tuning.
    
- Final UI improvements.
    

## Exit Criteria

The game is suitable for closed alpha testing.

---

# Milestone 13 - Release Preparation

## Goals

Prepare Wizard Chess for public release.

## Deliverables

- Final balancing.
    
- Documentation.
    
- Deployment pipeline.
    
- Dedicated server deployment.
    
- Release candidate.
    
- Marketing assets.
    

## Exit Criteria

The game is ready for public launch.

---

# Development Principles

Development should prioritize:

- Working software over speculative architecture.
    
- Small, testable iterations.
    
- Stable builds.
    
- Automated testing.
    
- Deterministic gameplay.
    
- Data-driven systems.
    
- Continuous refactoring when appropriate.
    
- Documentation alongside implementation.
    

Large systems should be validated through working prototypes before becoming permanent architecture.

---

# Project Philosophy

Wizard Chess should be developed as a long-term, maintainable project.

Architecture should always precede content.

Systems should be proven before they are expanded.

Content should be created only after the underlying systems are stable, tested, and capable of supporting future growth.

Every milestone should leave the project in a healthier, more complete state than the milestone before it.
