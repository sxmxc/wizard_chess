## Overview

All cards in Wizard Chess follow a standardized layout.

Each card type contains a common set of information along with additional information specific to that card type.

Cards should be designed to be fully playable in both physical and digital formats. Every card should be understandable without requiring digital assistance.

---

# Common Card Fields

Every card contains the following information.

## Name

The card's unique name.

---

## Card Type

Determines how the card functions within the game.

Current card types are:

- Unit
    
- Spell
    
- Reaction
    
- Trap
    
- Environment
    
- Artifact
    

---

## School

The School of Magic to which the card belongs.

Every card belongs to exactly one School unless explicitly stated otherwise.

---

## Mana Cost

The amount of Mana required to play the card.

---

## Rarity

Determines the card's rarity.

Current rarities are:

- Common
    
- Uncommon
    
- Rare
    
- Legendary
    

---

## Rules Text

Rules text defines both the requirements to play a card and the effects that occur when it resolves.

Whenever possible, the first sentence of a card should describe how or when it may be played. The remaining text should describe its effects.

---

## Flavor Text

Optional narrative text with no gameplay effect.

---

## Artwork

The illustration displayed on the card.

Artwork has no gameplay effect.

---

# Unit Card Template

Unit cards enhance an existing chess piece.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Horse Riding Adept

Unit

School: Nature
Mana Cost: 2
Rarity: Common

Target Pawn.

This Pawn may move as though it were a Knight.

"Every rider begins with a single step."
```

---

# Spell Card Template

Spell cards create an immediate effect before being placed into the Graveyard.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Arcane Reposition

Spell

School: Arcane
Mana Cost: 3
Rarity: Uncommon

Target friendly piece.

Move the target piece to any legal square it could normally occupy.

"The shortest path is the one rewritten."
```

---

# Reaction Card Template

Reaction cards respond to specific game events.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Divine Intervention

Reaction

School: Divine
Mana Cost: 2
Rarity: Rare

Play after a friendly piece would be captured.

That piece gains Ward.

"Faith answers faster than steel."
```

---

# Trap Card Template

Trap cards remain hidden until their trigger condition is satisfied.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Explosive Rune

Trap

School: Pyromancy
Mana Cost: 2
Rarity: Uncommon

Play on an empty square.

Whenever an opposing piece enters this square, apply Burning to that piece.

"One careless step."
```

---

# Environment Card Template

Environment cards create persistent battlefield effects.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Blizzard

Environment

School: Nature
Mana Cost: 5
Rarity: Rare

Play.

Knights, Bishops, Queens, and Kings may move one fewer square than their normal movement allows.

"The storm cares little for strategy."
```

---

# Artifact Card Template

Artifact cards represent persistent magical objects with ongoing effects.

### Required Information

- Name
    
- Card Type
    
- School
    
- Mana Cost
    
- Rarity
    
- Rules Text
    

### Optional Information

- Keywords
    
- Flavor Text
    
- Artwork
    

### Example

```text
Crystal Ball

Artifact

School: Arcane
Mana Cost: 3
Rarity: Rare

Play.

At the beginning of your turn, look at the top card of your deck.
You may place it on the bottom of your deck.

"The future favors the prepared."
```

---

# Rules Writing Standards

Rules text should:

- State play requirements before gameplay effects.
    
- Be concise.
    
- Be deterministic.
    
- Avoid ambiguity.
    
- Use existing game terminology whenever possible.
    
- Avoid unnecessary flavor within gameplay text.
    

Preferred wording:

```text
Target Pawn.

This Pawn may move as though it were a Knight.
```

Instead of:

```text
This Pawn is no longer restricted to normal Pawn movement.
```

Cards should describe exactly what they do without relying on implied behavior.

---

# Naming Conventions

Card names should be unique.

Names should communicate a card's theme or identity rather than describe its mechanics.

Examples include:

- Horse Riding Adept
    
- Queen of the Damned
    
- Devout Holy Man
    
- Arcane Reposition
    
- Crystal Ball
    
- Blizzard
    
- Explosive Rune
    

---

# Card Frame Requirements

Every card should clearly display:

- Name
    
- Artwork
    
- Mana Cost
    
- Card Type
    
- School
    
- Rules Text
    
- Keywords (when applicable)
    
- Flavor Text (optional)
    
- Rarity
    

Gameplay information should always take precedence over visual decoration.

Cards should remain readable and fully understandable when printed for physical play.

---

# Design Principles

Every card should:

- Reinforce the identity of its School.
    
- Encourage meaningful chess decisions.
    
- Be readable at a glance.
    
- Use existing mechanics whenever possible.
    
- Introduce new mechanics only when necessary.
    
- Be fully playable in both physical and digital formats.
    
- Follow the standardized templates defined in this section.