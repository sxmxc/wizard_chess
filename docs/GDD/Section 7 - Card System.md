## Overview

Cards represent the magical abilities available to each player during a match.

Each player brings a preconstructed deck of cards into the match. Cards are drawn, played, discarded, and resolved according to the rules defined in previous sections.

Every card belongs to exactly one card type.

Each card type follows its own gameplay rules.

---

# Card Anatomy

Every card contains the following information.

## Name

The unique name of the card.

---

## Card Type

Determines the card's behavior and when it may be played.

Examples include:

- Unit
    
- Spell
    
- Reaction
    
- Trap
    
- Environment
    
- Artifact
    

---

## School

Every card belongs to one School of Magic.

Schools define a card's magical identity and are used for deckbuilding, synergies, and future mechanics.

Schools are defined in Section 8.

---

## Academy

A card may optionally belong to an Academy.

Academies represent magical organizations, traditions, or institutions and may be referenced by card effects.

Not every card is required to belong to an Academy.

---

## Rarity

Defines the rarity of the card.

Rarity primarily controls collection, complexity, and frequency rather than power level.

Initial rarities are:

- Common
    
- Uncommon
    
- Rare
    
- Legendary
    

Additional rarities may be introduced in future expansions.

---

## Mana Cost

The amount of Mana required to play the card.

A card cannot be played unless its Mana Cost can be paid.

---

## Target Requirements

Cards define their own targeting requirements.

Examples include:

- Target Pawn
    
- Target Knight
    
- Target Queen
    
- Target Queen OR Pawn beyond Rank 5
    
- Target Bishop adjacent to your King
    
- Target threatened Rook
    

If a card's targeting requirements cannot be satisfied, it cannot be played.

---

## Rules Text

Rules Text defines the behavior of the card.

Rules Text overrides the core rules where explicitly stated.

---

## Keywords

Cards may contain one or more keywords.

Keywords represent reusable game mechanics defined in Section 9.

---

## Flavor Text

Flavor Text has no gameplay effect.

---

# Card Types

Wizard Chess currently supports six primary card types.

---

## Unit

Unit cards target chess pieces.

A Unit grants additional rules, movement modifications, keywords, passive abilities, activated abilities, triggered abilities, or other effects to the targeted chess piece.

Unless explicitly stated otherwise:

- A Unit does not change the underlying identity of the chess piece.
    
- Standard chess rules continue to apply.
    
- A chess piece may have only one Unit attached at a time.
    

Examples:

- Horse Riding Adept
    
- Devout Holy Man
    
- Queen of the Damned
    

---

## Spell

Spell cards produce an immediate effect before being placed into the Graveyard unless otherwise specified.

Spells may:

- Modify pieces
    
- Remove effects
    
- Create temporary effects
    
- Manipulate the board
    
- Draw cards
    
- Generate mana
    
- Interact with other cards
    

Spells do not remain in play unless explicitly stated.

---

## Reaction

Reaction cards may only be played during the Reaction Phase unless explicitly stated otherwise.

Reaction cards respond to specific game events.

Every Reaction card defines the condition that allows it to be played.

---

## Trap

Trap cards are placed face-down onto the battlefield.

Trap cards remain hidden until their trigger condition is satisfied.

Once triggered, the Trap resolves its effect.

Unless otherwise specified, Traps are then placed into their owner's Graveyard.

---

## Environment

Environment cards create persistent effects that influence portions of the battlefield or the entire match.

Environment cards remain in play until removed or replaced according to their card text.

Examples include:

- Blizzard
    
- Holy Ground
    
- Arcane Storm
    

---

## Artifact

Artifact cards represent magical objects with persistent effects.

Artifacts remain in play until removed by card effects or game rules.

Artifacts may provide passive abilities, activated abilities, or triggered abilities.

Artifacts are not attached to chess pieces unless explicitly stated.

---

# Playing Cards

To play a card:

1. The player must have priority.
    
2. The card must be legal to play during the current phase.
    
3. The player must pay all required costs.
    
4. All targeting requirements must be satisfied.
    
5. The card is played.
    
6. Any generated Game Events are processed according to Section 6.
    

---

# Card Ownership

Cards always belong to the player who included them in their deck.

Ownership never changes during a match unless explicitly modified by game rules.

---

# Card Control

A player normally controls every card they play.

Card effects may change control of cards or chess pieces.

Changing control does not change ownership.

---

# Card Zones

Cards may exist in the following zones:

- Deck
    
- Hand
    
- Battlefield
    
- Graveyard
    
- Exile (reserved for future mechanics)
    

Cards move between zones according to game rules and card effects.

---

# Card Identity

A card's identity consists of its printed characteristics.

This includes:

- Name
    
- Card Type
    
- School
    
- Academy
    
- Mana Cost
    
- Rules Text
    
- Keywords
    
- Rarity
    

Unless explicitly modified by card text, a card's identity never changes.

---

# Card Design Principles

All cards in Wizard Chess should adhere to the following principles.

- Preserve the strategic identity of chess.
    
- Create meaningful decisions rather than numerical advantages.
    
- Be deterministic.
    
- Use existing keywords whenever possible.
    
- Minimize ambiguity.
    
- Encourage interaction.
    
- Reward planning and positioning.
    
- Avoid introducing unnecessary global rules.
    

New mechanics should be introduced through cards whenever possible rather than modifications to the core rules.