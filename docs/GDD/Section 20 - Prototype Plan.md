## Overview

The purpose of the initial prototype is to validate the core architecture of Wizard Chess.

The prototype is not intended to be a polished game.

Instead, it should answer the highest-risk technical questions before additional gameplay systems and content are developed.

The prototype should remain as small as possible while proving the project's foundational architecture.

---

# Prototype Goals

The prototype should validate:

- Server-authoritative multiplayer.
    
- Deterministic gameplay simulation.
    
- Godot networking architecture.
    
- Event Queue implementation.
    
- Data-driven card architecture.
    
- Separation of simulation and presentation.
    
- Replay compatibility.
    
- Development workflow.
    

The prototype should prioritize correctness over completeness.

---

# Scope

The prototype should intentionally omit non-essential systems.

The focus should be proving the foundation rather than implementing features.

Out of scope for the initial prototype includes:

- Campaign
    
- Collection management
    
- Deck builder
    
- Progression
    
- Audio
    
- Visual effects
    
- Advanced UI polish
    
- Large card pool
    
- Multiple Wizards
    
- Accessibility features
    
- Matchmaking
    

---

# Prototype Features

The prototype should implement only the minimum systems necessary to validate the architecture.

## Multiplayer

- Dedicated server
    
- One client vs one client
    
- One client vs AI
    
- Client connection
    
- Match creation
    
- Match synchronization
    
- Disconnect handling
    
- Basic reconnect support
    

---

## Chess

- Standard chess setup
    
- Legal movement
    
- Capturing
    
- Check
    
- Checkmate
    
- Stalemate
    
- Pawn promotion
    

No card mechanics should replace or simplify standard chess behavior.

---

## Cards

Implement only enough cards to validate the card architecture.

Recommended examples:

### Unit

Horse Riding Adept

Target Pawn.

This Pawn may move as though it were a Knight.

---

### Spell

Arcane Reposition

Target friendly piece.

Move the target piece to any legal square it could normally occupy.

---

### Reaction

Divine Intervention

Play after a friendly piece would be captured.

That piece gains Ward.

---

### Trap

Explosive Rune

Play on an empty square.

Whenever an opposing piece enters this square, apply Burning.

---

### Environment

Blizzard

Play.

Knights, Bishops, Queens, and Kings may move one fewer square than their normal movement allows.

---

### Artifact

Crystal Ball

Play.

At the beginning of your turn, look at the top card of your deck.  
You may place it on the bottom.

These cards are intended to validate each card type rather than establish game balance.

---

# Event Queue

The prototype should fully implement the Event Queue.

The Event Queue should support:

- Triggered abilities
    
- Reactions
    
- Ordered resolution
    
- Chained events
    

The prototype should demonstrate that the Event Queue can resolve complex interactions deterministically.

---

# User Interface

The prototype UI should remain intentionally simple.

Required features include:

- Chessboard
    
- Piece movement
    
- Hand display
    
- Card inspection
    
- Piece inspection
    
- Graveyard inspection
    
- Move history
    
- Current phase
    
- Current mana
    
- Active Environment display
    

The prototype should emphasize functionality over visual polish.

---

# Networking Validation

The prototype should answer the following questions:

- Does the server-authoritative model function correctly?
    
- Does Godot's high-level multiplayer API meet the project's needs?
    
- Is the proposed RPC architecture maintainable?
    
- Are SceneTree and NodePath constraints manageable?
    
- Can gameplay remain deterministic across clients?
    
- Can reconnect be implemented cleanly?
    

If significant issues are discovered, the architecture should be revised before additional systems are built.

---

# Replay Validation

The prototype should demonstrate that a completed match can be replayed using deterministic simulation.

The replay should reproduce:

- Board state
    
- Card plays
    
- Event Queue resolution
    
- Victory condition
    

Replay implementation should not rely on video recording.

---

# Artificial Intelligence

The prototype AI should be intentionally simple.

The objective is to validate architecture rather than gameplay strength.

The AI should:

- Play legal chess moves.
    
- Play legal cards.
    
- Follow turn structure.
    
- Use the same action interface as human players.
    

Difficulty tuning is outside the scope of the prototype.

---

# Data Validation

The prototype should demonstrate that gameplay content can be authored using Godot Resources.

The prototype should validate:

- Card definitions
    
- Wizard definitions
    
- School definitions
    
- Keywords
    
- Configuration values
    

Adding a new card should require little or no gameplay engine code whenever practical.

---

# Testing

The prototype should include automated tests where practical.

Tests should verify:

- Legal move generation
    
- Card validation
    
- Event Queue resolution
    
- Replay determinism
    
- Multiplayer synchronization
    

Testing infrastructure is considered part of the prototype.

---

# Success Criteria

The prototype is considered successful if it demonstrates:

- Stable dedicated server operation.
    
- Deterministic gameplay.
    
- Reliable multiplayer synchronization.
    
- Functional Event Queue.
    
- Data-driven card definitions.
    
- Replay capability.
    
- Shared gameplay systems across AI and multiplayer.
    
- Clean separation between gameplay and presentation.
    

If these goals are achieved, the project may proceed to full production.

---

# Failure Criteria

The prototype should be reconsidered if it reveals fundamental issues with:

- Godot networking.
    
- Deterministic simulation.
    
- Data-driven card architecture.
    
- Event Queue design.
    
- Multiplayer synchronization.
    
- Maintainability.
    

Architectural changes should occur during the prototype rather than after large amounts of gameplay content have been created.

---

# Design Principles

The prototype exists to answer technical questions—not to create content.

Every feature implemented during the prototype should reduce uncertainty about the final architecture.

Features that do not contribute to validating the architecture should be postponed until production.