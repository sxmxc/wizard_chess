## Overview

This section defines the rules governing the lifecycle of a Wizard Chess match, from deck selection through victory.

Unless otherwise specified by game mode, all matches follow these rules.

---

## Match Initialization

Before a match begins:

1. Each player selects a legal deck.
    
2. The starting player is determined.
    
3. Both players shuffle their decks.
    
4. Both players draw their opening hand.
    
5. Mulligans are resolved.
    
6. The first turn begins.
    

---

## Starting Player

The starting player is determined before the match begins.

The method for determining the starting player is dependent on the game mode.

Examples include:

- Random selection
    
- Tournament rules
    
- Challenge rules
    
- Campaign scenarios
    

The starting player takes the first turn.

---

## Deck

Each player begins the match with a shuffled deck.

Deck construction rules are defined later in this document.

A player's deck remains hidden throughout the match except for cards that become publicly revealed through gameplay.

---

## Opening Hand

Each player draws an opening hand before the first turn.

The number of cards drawn is a configurable gameplay value.

---

## Mulligan

After drawing their opening hand, each player may perform one mulligan.

During a mulligan:

1. The player selects any number of cards from their hand.
    
2. The selected cards are returned to the deck.
    
3. The deck is shuffled.
    
4. The player draws replacement cards equal to the number returned.
    

Each player may perform only one mulligan per match unless modified by card effects or game mode.

---

## Turn Order

Players alternate turns until the match ends.

Each player completes their full turn before the opposing player begins theirs.

A turn consists of the phases defined in Section 5.

---

## Mana

Players gain mana at the beginning of each turn.

Mana is used to play cards.

The following values are configurable gameplay constants:

- Starting Mana
    
- Maximum Mana
    
- Mana gained per turn
    

The exact values are intentionally not defined by the core rules and may be adjusted during balancing.

---

## Hand

Players maintain a hand of cards drawn from their deck.

The following values are configurable gameplay constants:

- Starting hand size
    
- Maximum hand size
    

Cards are added to a player's hand through drawing and other card effects.

---

## Deck Exhaustion

If a player attempts to draw a card from an empty deck, the draw fails.

Additional penalties or alternate rules may be introduced during balancing.

The exact behavior is a configurable gameplay rule.

---

## Graveyard

Cards that are discarded, destroyed, or otherwise leave play are placed into their owner's Graveyard unless explicitly stated otherwise.

Graveyards are public information.

Cards may interact with Graveyards if permitted by their effects.

---

## Concede

A player may concede the match at any time during their own turn.

Conceding immediately awards victory to the opposing player.

Game modes may optionally allow concession during the opponent's turn.

---

## Victory

The primary victory condition is achieving checkmate.

Unless modified by card text or game mode, standard chess victory conditions apply.

Future cards may introduce alternate victory conditions.

---

## Draw

A match may end in a draw through any standard chess draw condition, including:

- Stalemate
    
- Threefold repetition
    
- Fifty-move rule
    
- Insufficient material
    
- Mutual agreement (where supported)
    

Additional draw conditions may be introduced by future game modes.

---

## Match End

When a victory or draw condition is satisfied:

1. Gameplay immediately ends.
    
2. Remaining unresolved gameplay actions are cancelled unless required to determine the result.
    
3. The final board state is recorded.
    
4. Match statistics are generated.
    
5. Results are presented to both players.
    

---

## Configurable Gameplay Constants

The following values are intentionally configurable and are not considered part of the immutable ruleset.

- Deck size
    
- Starting hand size
    
- Maximum hand size
    
- Starting Mana
    
- Maximum Mana
    
- Mana gained each turn
    
- Mulligan rules
    
- Turn timer
    
- Match timer
    

These values may be adjusted through balancing without modifying the core rules of Wizard Chess.