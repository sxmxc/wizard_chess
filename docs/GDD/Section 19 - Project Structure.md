## Overview

The Wizard Chess project should be organized to encourage modularity, readability, maintainability, and scalability.

The project structure should clearly separate gameplay systems, presentation, networking, content, and development tools.

Folder organization should reflect responsibilities rather than implementation details.

---

# Organizational Principles

The project should adhere to the following principles:

- One responsibility per system.
    
- Favor composition over inheritance.
    
- Data-driven where practical.
    
- Editor-first workflow.
    
- Avoid circular dependencies.
    
- Minimize coupling between systems.
    
- Keep runtime and editor tooling separate.
    

---

# Top-Level Project Structure

The project should be organized into clearly defined areas.

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

---

# Addons

The `addons/` directory contains third-party and custom Godot editor plugins.

Examples include:

- Third-party editor plugins
    
- Custom editor tools
    
- Development utilities
    

Gameplay systems should not depend upon editor-only addons.

---

# Assets

The `assets/` directory contains source assets used by the game.

Examples include:

- Artwork
    
- Audio
    
- Music
    
- Fonts
    
- Icons
    
- Particle textures
    
- UI graphics
    

Assets should be organized by asset type.

---

# Content

The `content/` directory contains gameplay data.

Examples include:

- Cards
    
- Wizards
    
- Schools
    
- Keywords
    
- AI profiles
    
- Game modes
    
- Configuration data
    

Content should primarily be represented using Godot Resources.

Gameplay content should not require engine code changes whenever practical.

---

# Documentation

The `docs/` directory contains project documentation.

Examples include:

- Game Design Document
    
- Rulebook
    
- Technical documentation
    
- Architecture notes
    
- Design decisions
    
- Milestone plans
    

Documentation should remain synchronized with the implementation.

---

# Scenes

The `scenes/` directory contains Godot scenes responsible for presentation and application flow.

Examples include:

- Main menu
    
- Match scene
    
- Board scene
    
- UI scenes
    
- Settings
    
- Collection manager
    
- Deck builder
    

Scenes should focus on presentation rather than gameplay rules.

---

# Scripts

The `scripts/` directory contains gameplay systems and application logic.

Examples include:

- Simulation
    
- Match management
    
- Rules engine
    
- AI
    
- Networking
    
- Persistence
    
- Utility classes
    

Scripts should be organized by responsibility rather than object type.

---

# Tests

The `tests/` directory contains automated tests.

Examples include:

- Unit tests
    
- Integration tests
    
- Simulation tests
    
- Replay validation
    
- Networking tests
    

Gameplay systems should be designed to support automated testing.

---

# Tools

The `tools/` directory contains project-specific development tools.

Examples include:

- Import utilities
    
- Data validation
    
- Card generation
    
- Build scripts
    
- Development utilities
    

These tools should improve workflow without becoming runtime dependencies.

---

# Content Organization

Gameplay content should be organized by system rather than by expansion.

Example:

```text
content/
    cards/
    wizards/
    schools/
    keywords/
    ai/
    config/
```

As the game grows, additional organization such as card sets or expansions may be introduced without changing the overall structure.

---

# Script Organization

Gameplay code should be organized into independent systems.

Examples include:

```text
scripts/
    ai/
    cards/
    match/
    networking/
    persistence/
    replay/
    rules/
    simulation/
    ui/
    utilities/
```

Each system should expose a clear public interface while minimizing dependencies on other systems.

---

# Scene Organization

Scenes should remain focused and modular.

Large scenes should be composed from smaller reusable scenes whenever practical.

Examples include:

- Board
    
- Chess Piece
    
- Card
    
- Hand
    
- Graveyard
    
- Match HUD
    
- Inspector Panel
    
- Notification
    
- Dialogs
    

Avoid monolithic scenes containing unrelated responsibilities.

---

# Resource Organization

Reusable gameplay data should be represented as Resources whenever practical.

Examples include:

- Card definitions
    
- Wizard definitions
    
- School definitions
    
- Keyword definitions
    
- AI personalities
    
- Configuration assets
    

Resources should describe gameplay data rather than implement gameplay behavior.

---

# Naming Conventions

Project naming should remain consistent.

Recommendations include:

- PascalCase for scene names.
    
- PascalCase for Resource types.
    
- snake_case for file names where appropriate.
    
- Clear, descriptive class names.
    
- Avoid abbreviations unless universally understood.
    

Consistency is more important than any particular naming convention.

---

# Dependency Direction

High-level gameplay systems should not depend upon presentation systems.

Preferred dependency flow:

```text
Simulation
        ↓
Match
        ↓
Networking
        ↓
Presentation
```

Presentation may observe gameplay state, but gameplay systems should not depend on UI components.

---

# Development Workflow

When implementing new features:

1. Update or review the relevant documentation.
    
2. Design the gameplay behavior.
    
3. Implement the simulation.
    
4. Write automated tests where practical.
    
5. Implement presentation.
    
6. Verify multiplayer compatibility.
    
7. Verify replay compatibility.
    
8. Refactor if necessary.
    

Gameplay correctness should always take precedence over visual polish.

---

# Future Expansion

The project structure should support future additions without requiring large-scale reorganization.

Examples include:

- New card sets
    
- Additional Wizards
    
- Campaign content
    
- New game modes
    
- Mod support
    
- Additional AI personalities
    

Expansion should occur by adding new content rather than restructuring existing systems.

---

# Design Principles

The project structure should prioritize:

- Readability
    
- Maintainability
    
- Modularity
    
- Data-driven content
    
- Editor-first workflows
    
- Ease of testing
    
- Ease of expansion
    
- Clear separation of responsibilities
    

The organization of the project should make it immediately clear where a new feature, asset, or gameplay system belongs.