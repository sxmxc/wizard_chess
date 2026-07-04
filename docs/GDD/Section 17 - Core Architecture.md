## Overview

Wizard Chess should be built around a deterministic, server-authoritative architecture.

The project should leverage Godot's strengths while maintaining a clear separation between gameplay simulation and presentation.

The same core gameplay systems should support:

- Single-player versus AI
    
- Online multiplayer
    
- Replay playback
    
- Automated testing
    
- Spectator mode
    
- Future dedicated servers
    

---

# Server-Authoritative Architecture

Online matches are controlled by an authoritative server.

Clients never directly modify the game state.

Instead, clients submit gameplay actions to the server.

Examples include:

- Move a chess piece
    
- Play a card
    
- Activate an ability
    
- Select a mulligan
    
- Concede the match
    

The server validates every action, applies the game rules, updates the match state, and synchronizes the results with connected clients.

This architecture provides:

- Competitive integrity
    
- Cheat prevention
    
- Consistent gameplay
    
- Deterministic simulation
    
- Reliable replay generation
    

---

# Godot Architecture

Both clients and dedicated servers should be implemented as Godot applications.

Both execute a SceneTree.

The dedicated server should execute gameplay scenes and systems without rendering graphics or user interface elements.

Gameplay systems should not depend on:

- Sprites
    
- Cameras
    
- UI controls
    
- Particle effects
    
- Animations
    
- Audio
    

This allows the same gameplay code to execute on both clients and servers.

---

# Separation of Responsibilities

Gameplay systems should be divided into clearly defined responsibilities.

## Simulation

Responsible for:

- Match state
    
- Board state
    
- Chess rules
    
- Card rules
    
- Turn progression
    
- Event resolution
    
- Mana
    
- Decks
    
- Hands
    
- Graveyards
    
- Victory conditions
    

The simulation is the authoritative source of truth.

---

## Presentation

Responsible for:

- Board rendering
    
- Piece visuals
    
- Card visuals
    
- User interface
    
- Animations
    
- Visual effects
    
- Audio
    
- Input feedback
    

Presentation should never determine gameplay outcomes.

It exists only to visualize the authoritative game state.

---

# Shared Gameplay Systems

Single-player, AI, multiplayer, replay playback, and automated tests should use the same gameplay systems whenever practical.

Different game modes should not maintain separate implementations of the rules.

A gameplay rule should only need to be implemented once.

---

# Board Representation

The board should be represented internally as an 8×8 grid.

Each square contains either:

- No piece
    
- Exactly one chess piece
    

Board coordinates should remain consistent across:

- Simulation
    
- Networking
    
- AI
    
- Replay system
    
- User interface
    

---

# Match State

The simulation maintains the complete match state.

This includes:

- Board position
    
- Piece state
    
- Attached Units
    
- Active effects
    
- Active Environment
    
- Active Artifacts
    
- Decks
    
- Hands
    
- Graveyards
    
- Mana
    
- Turn information
    
- Event Queue
    
- Match outcome
    

The server is the authoritative owner of this state.

---

# Event Processing

Gameplay is processed through player actions and the Event Queue.

The typical flow is:

1. Client submits a gameplay action.
    
2. Server validates the action.
    
3. The simulation updates the match state.
    
4. Generated Game Events are added to the Event Queue.
    
5. The Event Queue resolves.
    
6. The updated game state is synchronized.
    
7. Clients present the results through animations and visual effects.
    

Gameplay should never depend upon animation timing.

Animations visualize completed gameplay events rather than controlling them.

---

# Randomness

All randomness originates from a single match-owned random number generator.

Examples include:

- Deck shuffling
    
- Future random card effects
    

Using a single match seed guarantees deterministic gameplay, testing, and replay generation.

---

# Data-Driven Content

Gameplay content should be data-driven wherever practical.

Examples include:

- Cards
    
- Wizards
    
- Schools
    
- Keywords
    
- AI personalities
    
- Game modes
    
- Balance values
    

Adding or modifying gameplay content should require little or no engine code whenever practical.

---

# Godot Resources

Gameplay data should primarily be represented using Godot Resources.

Examples include:

- Card definitions
    
- Wizard definitions
    
- School definitions
    
- Keyword definitions
    
- AI profiles
    
- Game configuration
    

Resources should describe gameplay data rather than contain complex gameplay logic.

---

# Composition

Composition should be preferred over inheritance.

Gameplay systems should be composed from small, focused, reusable components.

Avoid:

- Monolithic scripts
    
- Deep inheritance hierarchies
    
- Hardcoded card implementations
    
- Special-case systems where generalized rules are appropriate
    

---

# Networking

Networking should synchronize gameplay actions and authoritative state between the server and connected clients.

Clients may perform local prediction or visual previews to improve responsiveness, but all gameplay decisions remain subject to server validation.

The networking architecture should support:

- Dedicated servers
    
- Reconnection
    
- Spectators
    
- Future horizontal scalability
    

Peer-to-peer networking is not a project goal.

Local multiplayer is not a project goal.

---

# Saving

Single-player matches against AI may support save and resume.

Online multiplayer should prioritize:

- Reconnection
    
- Server persistence
    
- Match recovery
    
- Replay generation
    

Rather than arbitrary save states.

---

# Replay System

Replays should be generated from deterministic gameplay data.

A replay should be reproducible from:

- Initial match state
    
- Deck lists
    
- Match seed
    
- Player action history
    

The replay system should execute the same gameplay systems used during a live match.

---

# Artificial Intelligence

The AI should interact with the simulation using the same gameplay interfaces as a human player.

The AI submits gameplay actions.

The simulation validates and resolves those actions.

The AI should never directly manipulate the authoritative game state.

---

# Runtime Dependencies

Runtime dependencies should be kept to a minimum.

Core gameplay should rely primarily on:

- Godot
    
- Project-owned code
    
- Standard Godot systems
    

Third-party editor tools may be used to improve workflow but should not become hard dependencies for gameplay.

---

# Design Principles

The architecture of Wizard Chess should prioritize:

- Server-authoritative gameplay
    
- Deterministic simulation
    
- Shared gameplay systems
    
- Data-driven content
    
- Editor-first workflows
    
- Composition over inheritance
    
- Clear separation between gameplay and presentation
    
- Long-term maintainability
    
- Ease of testing
    
- Ease of expansion
    

The server is the authoritative source of truth.

The client exists to present that truth to the player.