## Overview

Wizard Chess is a two-player, turn-based strategy game played on a standard 8×8 chess board.

Each player controls a traditional chess army and a customizable deck of magical cards. Gameplay combines the positional strategy of chess with the deckbuilding and tactical decision-making of a trading card game.

A match begins as a standard game of chess and gradually evolves as players use cards to modify pieces, cast spells, manipulate the battlefield, and respond to their opponent's actions.

The game is designed around deterministic rules. Once a match begins, every game state is derived entirely from player actions and card draw order.

---

## Core Gameplay Loop

During a match, players repeat the following sequence until a victory condition is met.

1. Begin Turn
    
2. Gain Mana
    
3. Draw Card
    
4. Play Cards
    
5. Make One Mandatory Chess Move
    
6. Resolve Reactions and Effects
    
7. End Turn
    

Every turn must include exactly one legal chess move unless explicitly modified by card text.

---

## Match Flow

1. Players select decks.
    
2. The starting player is determined.
    
3. Both players shuffle their decks.
    
4. Both players draw their opening hand.
    
5. Mulligans are resolved.
    
6. The match begins.
    
7. Players alternate turns until a victory condition is met.
    
8. Results are displayed.
    

---

## Player Objectives

Each player must balance two interconnected systems.

### Chess

- Control space.
    
- Develop pieces.
    
- Create tactical advantages.
    
- Protect valuable pieces.
    
- Deliver checkmate.
    

### Magic

- Manage mana.
    
- Build an effective deck.
    
- Play cards at the correct time.
    
- Enhance pieces with Unit cards.
    
- Adapt to changing board states.
    
- Disrupt the opponent's strategy.
    

Success requires mastery of both systems.

---

## Match Structure

Each turn is divided into the following phases.

1. Beginning Phase
    
2. Preparation Phase
    
3. Move Phase
    
4. Reaction Phase
    
5. End Phase
    

Each phase has defined rules governing which actions may be performed.

---

## Public Information

The following information is always visible to both players.

- Chess board state
    
- Piece locations
    
- Piece status
    
- Attached Unit cards
    
- Active card effects
    
- Graveyards
    
- Mana totals
    
- Deck counts
    
- Hand counts
    
- Turn number
    
- Active player
    

---

## Hidden Information

The following information is hidden.

- Cards in each player's hand
    
- Card order within each deck
    
- Face-down Trap cards
    

No additional hidden information exists.

---

## Victory Conditions

The primary victory condition is achieving checkmate.

Unless explicitly modified by card text, all standard chess victory conditions remain in effect.

Future card sets may introduce alternate victory conditions.

---

## Gameplay Principles

Wizard Chess is built around the following principles.

- Chess remains the foundation of every match.
    
- Cards create exceptions rather than replacing chess.
    
- Positioning is more valuable than numerical advantages.
    
- Every decision should create meaningful strategic tradeoffs.
    
- Complexity emerges through card interactions rather than complicated rules.
    
- Every rule must be deterministic and objectively evaluable.
    
- The board state should remain understandable throughout the match.