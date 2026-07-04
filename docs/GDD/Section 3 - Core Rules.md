## Overview

The following rules define the core behavior of Wizard Chess. These rules apply to every match unless explicitly overridden by card text.

These rules are intended to remain stable throughout the lifetime of the game. Balance should primarily be achieved through cards and configurable gameplay values rather than modifications to the core rules.

---

## Rule 1 - Chess is Canon

Wizard Chess uses the standard rules of chess as its foundation.

Unless explicitly overridden by card text, all official chess rules remain in effect.

This includes, but is not limited to:

- Legal piece movement
    
- Capturing
    
- Check
    
- Checkmate
    
- Castling
    
- En passant
    
- Pawn promotion
    
- Stalemate
    
- Draw by insufficient material
    
- Draw by repetition
    
- Draw by the fifty-move rule
    

If a card contradicts a standard chess rule, the card takes precedence for that interaction only.

---

## Rule 2 - Card Text Overrides Rules

When card text directly contradicts a game rule, the card text takes precedence.

This precedence applies only for the specific effect described by the card.

Once the effect ends, normal game rules immediately resume.

---

## Rule 3 - Mandatory Move

Every player must make exactly one legal chess move during their turn.

A player may not voluntarily end their turn without making a legal move.

A card may explicitly modify or replace this requirement.

---

## Rule 4 - Legal Card Play

A card may only be played if all of its play requirements are satisfied.

This includes, but is not limited to:

- Sufficient mana
    
- Valid timing window
    
- Valid target(s)
    
- Any additional play restrictions defined by the card
    

If all required conditions are not met, the card cannot be played.

---

## Rule 5 - Targeting

Every card defines its own targeting requirements.

Target requirements are specified entirely by the card's text.

Examples include:

- Target Pawn
    
- Target Knight
    
- Target Queen
    
- Target Queen OR Pawn beyond Rank 5
    
- Target Bishop adjacent to your King
    
- Target threatened Rook
    

If no legal target exists, the card cannot be played.

---

## Rule 6 - Units

A Unit is a card type that targets a chess piece.

A Unit grants additional rules, abilities, keywords, movement modifications, passive effects, activated abilities, or triggered abilities to the targeted chess piece.

Attaching a Unit does not change the underlying identity of the chess piece unless explicitly stated by the card.

Example:

A Pawn with Horse Riding Adept attached remains a Pawn.

It is still affected by effects that target Pawns.

It still promotes according to standard chess rules.

---

## Rule 7 - One Unit Per Piece

Each chess piece may have only one Unit attached at any time.

If a Unit is played on a piece that already has a Unit attached, the existing Unit is discarded before the new Unit is attached.

Unless explicitly stated otherwise, a Unit is discarded when its attached piece leaves the board.

---

## Rule 8 - Card Ownership

Cards always belong to the player who included them in their deck.

Unless explicitly stated otherwise, changing control of a chess piece does not change ownership of attached cards.

---

## Rule 9 - Public Information

The following information is public at all times:

- Board state
    
- Piece positions
    
- Captured pieces
    
- Attached Units
    
- Active effects
    
- Mana totals
    
- Graveyards
    
- Deck counts
    
- Hand counts
    
- Current turn
    
- Active player
    

---

## Rule 10 - Hidden Information

Only the following information is hidden:

- Cards in players' hands
    
- Face-down Trap cards
    
- Deck order
    

All other game information is public.

---

## Rule 11 - Deterministic Gameplay

Wizard Chess is a deterministic game.

Once decks have been shuffled and opening hands drawn, every future game state is determined solely by player actions and the established game rules.

No card may introduce random outcomes during gameplay unless a future rules update explicitly allows it.

Randomness is limited to:

- Deck shuffle before the match
    
- Card draw order
    

---

## Rule 12 - Rule Precedence

When multiple rules apply simultaneously, precedence is resolved in the following order:

1. Card text
    
2. Core Rules
    
3. Standard chess rules
    

If two card effects directly conflict, resolution follows the game's effect resolution rules defined later in this document.

---

## Rule 13 - Future Compatibility

Cards and future expansions should build upon these core rules rather than replacing them.

Whenever possible, new mechanics should be implemented through card effects instead of introducing additional global rules.