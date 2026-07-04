## Overview

Wizard Chess uses a server-authoritative multiplayer architecture implemented using Godot's multiplayer systems.

This section defines the architectural goals and constraints for networking. It intentionally avoids prescribing implementation details that should first be validated through working prototypes.

The networking architecture should embrace Godot's strengths while remaining deterministic, maintainable, and scalable.

---

# Design Goals

The networking architecture should support:

- Server-authoritative gameplay
    
- Dedicated server deployment
    
- Online multiplayer
    
- AI opponents
    
- Spectator mode
    
- Replay generation
    
- Future horizontal scalability
    

The networking layer should remain as simple as practical while exposing only the functionality required by the simulation.

---

# Server Authority

The server owns the authoritative game state.

Clients never directly modify gameplay state.

Clients submit gameplay actions.

The server:

- Validates actions.
    
- Executes gameplay rules.
    
- Resolves the Event Queue.
    
- Updates the authoritative match state.
    
- Synchronizes the results with connected clients.
    

Every gameplay decision originates from the server.

---

# Client Responsibilities

Clients are responsible for:

- Rendering the board.
    
- Rendering cards.
    
- User interface.
    
- Player input.
    
- Animations.
    
- Audio.
    
- Visual effects.
    
- Local previews.
    

Clients may locally preview possible actions for responsiveness, but all gameplay remains subject to server validation.

---

# Shared Simulation

The same gameplay systems should be used for:

- Single-player
    
- AI
    
- Multiplayer
    
- Replay playback
    
- Automated testing
    

Gameplay rules should exist only once.

Networking should communicate with the simulation rather than replace it.

---

# Godot Multiplayer

Wizard Chess should initially target Godot's high-level multiplayer APIs.

Lower-level networking should only be considered if profiling or prototyping demonstrates a clear requirement.

Networking decisions should remain flexible until validated by working prototypes.

---

# RPC Design

Godot RPCs require matching declarations and stable node paths across peers.

RPC-enabled nodes should therefore remain:

- Few in number.
    
- Stable in hierarchy.
    
- Shared between client and server.
    

The preferred architecture is to use a small number of dedicated networking nodes with identical scripts, identical RPC declarations, and identical SceneTree paths on both client and server.

Behavior should differ based on runtime role rather than different RPC interfaces.

The current prototype follows this by keeping a single multiplayer bridge node at `/root/Bootstrap/NetworkRoot/MatchBridge` for both dedicated-server and client flows.

Gameplay objects such as:

- Chess pieces
    
- Cards
    
- Effects
    
- UI controls
    
- Animations
    

should not expose RPC methods directly.

---

# Minimal RPC Surface

Networking should expose as few RPC methods as practical.

Examples include:

- Submit player action
    
- Receive action result
    
- Receive state update
    
- Receive state snapshot
    
- Receive match event
    
- Request reconnect
    

Gameplay details should be communicated through structured data payloads rather than a large number of gameplay-specific RPC functions.

---

# Action-Based Networking

Clients communicate intent rather than state.

Examples include:

- Move Piece
    
- Play Card
    
- Activate Ability
    
- Select Mulligan
    
- Concede
    

The server determines whether the requested action is legal.

If legal:

- The simulation updates.
    
- Events resolve.
    
- Clients receive the resulting state.
    

If illegal:

- The action is rejected.
    
- No gameplay state changes.
    

---

# State Synchronization

The exact synchronization strategy should be determined through prototyping.

Possible synchronization methods include:

- Player actions
    
- Event notifications
    
- State deltas
    
- Full state snapshots
    

The implementation should prioritize correctness and maintainability over premature optimization.

---

# Dedicated Servers

Dedicated servers should run as headless Godot applications.

Server scenes should include only systems required for:

- Networking
    
- Match management
    
- Simulation
    
- AI
    
- Replay generation
    
- Logging
    

Server scenes should not depend upon:

- Rendering
    
- UI
    
- Audio
    
- Cameras
    
- Visual effects
    

---

# Reconnection

Online matches should support reconnecting after temporary disconnection.

The server should be capable of restoring sufficient information for the client to reconstruct the current match.

Reconnect implementation should be validated during multiplayer prototyping.

---

# Spectators

Spectator support is a future goal.

Spectators should receive only public information.

Hidden information, including:

- Player hands
    
- Deck order
    
- Face-down Trap identities
    

must never be transmitted to spectators.

---

# Security

All client messages are considered untrusted.

The server validates:

- Player identity
    
- Turn ownership
    
- Current phase
    
- Legal chess moves
    
- Mana availability
    
- Card ownership
    
- Play requirements
    
- Timing restrictions
    
- Targets
    
- Victory conditions
    

Invalid actions must never modify the authoritative game state.

---

# Prototype Requirements

Before networking architecture is finalized, a prototype must demonstrate:

- Client connection
    
- Dedicated server operation
    
- Authoritative chess movement
    
- Authoritative card play
    
- Event Queue synchronization
    
- Animation driven by server-approved state
    
- Reconnection
    
- Stable RPC behavior
    
- Headless server execution
    

No production networking architecture should be finalized until these goals are successfully demonstrated.

---

# Design Principles

The networking architecture should prioritize:

- Server authority
    
- Deterministic gameplay
    
- Shared gameplay systems
    
- Stable RPC interfaces
    
- Small RPC surface
    
- Maintainability
    
- Replay compatibility
    
- Reconnection support
    
- Future scalability
    

Implementation details should remain flexible until validated through working prototypes.
