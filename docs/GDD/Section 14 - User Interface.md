## Overview

The Wizard Chess user interface should prioritize gameplay clarity while minimizing unnecessary visual clutter.

The chessboard is always the primary focus of the interface. All supporting information should remain easily accessible without distracting from the board state.

The interface should be equally suitable for desktop, tablet, and mobile platforms while maintaining the same gameplay experience.

---

# Design Principles

The user interface should adhere to the following principles:

- The chessboard is the primary focus.
    
- Gameplay information should always take precedence over visual effects.
    
- Frequently accessed information should require minimal interaction.
    
- Important game events should be clearly communicated.
    
- The interface should remain responsive and readable at all times.
    
- Every gameplay mechanic should be understandable without relying on hidden interface elements.
    

---

# Board Presentation

The chessboard occupies the majority of the available screen space.

The board should always be presented from the active local player's perspective.

- White views the board with White at the bottom.
    
- Black views the board with Black at the bottom.
    

Board coordinates should remain visible and consistent.

---

# Piece Selection

Selecting a chess piece should display all relevant information for that piece.

The player should be able to inspect:

- Chess piece type
    
- Attached Unit card
    
- Active keywords
    
- Active effects
    
- Current movement capabilities
    
- Cards currently affecting the piece
    

Inspecting a piece should never interrupt gameplay.

---

# Attached Units

Chess pieces with attached Unit cards should display a visual indicator on the board.

The indicator should remain unobtrusive while allowing players to quickly identify modified pieces.

Selecting the piece should display the complete attached Unit card.

Players should never be required to remember which Unit is attached to a piece.

---

# Card Hand

The player's hand should be displayed along the bottom of the screen.

Cards should remain readable while allowing the chessboard to occupy the majority of the display.

Hovering a card with a mouse or selecting it with touch controls should enlarge the card for inspection.

Cards should clearly indicate when they are playable.

Cards that cannot currently be played should remain visible but visually distinguished from playable cards.

---

# Board Interaction

Selecting a chess piece should display all currently legal movement destinations.

Legal moves should be clearly highlighted.

Illegal moves should never be presented as selectable.

Card effects that modify movement should be reflected immediately in the displayed legal moves.

---

# Threat Visualization

Players should be able to optionally display threatened squares on the board.

Threat visualization is intended as a learning and accessibility aid.

This overlay should be disabled by default and may be enabled or disabled through the game settings.

---

# Active Cards

Players should always be able to inspect active persistent cards.

This includes:

- Attached Unit cards
    
- Environment cards
    
- Artifact cards
    
- Face-up Traps
    
- Other persistent effects
    

The interface should clearly distinguish active cards from cards in the Graveyard.

---

# Graveyard

Each player's Graveyard should be inspectable at any time.

Players should be able to view:

- All cards currently in the Graveyard
    
- Card details
    
- Card order, when relevant
    

Graveyard inspection should not interrupt gameplay.

---

# Move History

The interface should maintain a complete match history.

The history should include:

- Chess moves
    
- Cards played
    
- Reactions
    
- Captures
    
- Promotions
    
- Significant game events
    

The move history should support replay and post-match review.

---

# Event Presentation

Game events should be presented sequentially as they resolve.

Piece movement should be animated.

Cards should be visually highlighted as they are played or resolved.

When multiple cards or effects resolve in sequence, each should be presented individually in resolution order.

Reaction cards should appear visually layered above the effect to which they are responding, making the chain of interactions easy to follow.

Players should always be able to understand why the current game state exists.

---

# Environment Presentation

Active Environment cards should remain visible throughout the match.

The interface should clearly indicate which Environment is currently affecting the battlefield.

Environmental visual effects should enhance gameplay without obscuring the board.

---

# Mana Display

The player's current Mana and Maximum Mana should remain visible at all times.

Changes to Mana should be clearly animated.

---

# Turn Information

The interface should always display:

- Current player
    
- Current turn number
    
- Current phase
    
- Priority indicator
    
- Timer (when applicable)
    

Players should never be uncertain whose turn it is or which phase is currently active.

---

# Notifications

Important gameplay events should be clearly communicated.

Examples include:

- Check
    
- Checkmate
    
- Stalemate
    
- Promotion
    
- Burning triggered
    
- Ward consumed
    
- Environment changed
    

Notifications should be brief, informative, and non-intrusive.

---

# Accessibility

The interface should support a wide range of accessibility features, including:

- Adjustable UI scaling
    
- Colorblind-friendly palettes
    
- High contrast mode
    
- Keyboard navigation
    
- Full controller support
    
- Screen reader compatibility where practical
    

Accessibility features should not alter gameplay.

---

# Physical Compatibility

The digital interface should present information that is available in a physical game without introducing gameplay advantages.

The digital version may automate rule enforcement, calculations, and event resolution, but should not reveal hidden information or provide strategic insight beyond what is available through the game rules.

---

# Design Principles

The Wizard Chess interface should:

- Keep the chessboard as the primary focus.
    
- Clearly communicate game state.
    
- Reduce bookkeeping through automation.
    
- Present information consistently.
    
- Support both new and experienced players.
    
- Preserve the feel of a physical tabletop game while leveraging digital quality-of-life improvements.