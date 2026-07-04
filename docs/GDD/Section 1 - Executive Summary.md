# Overview

## High Concept

Wizard Chess is a competitive turn-based strategy game that combines the tactical depth of traditional chess with the creativity and replayability of a customizable card game.

Players take the role of powerful wizards engaged in a magical duel through an enchanted game of chess. Every match begins as a standard game of chess, then gradually evolves as players cast spells, empower their pieces with Unit cards, alter the battlefield, and react to their opponent's strategy.

Wizard Chess is **not** a replacement for chess. It is chess enhanced through magic.

Unless explicitly overridden by card text, every standard rule of chess remains in effect.

The objective is to outplay your opponent through superior positioning, resource management, deck construction, and tactical spellcasting.

---

# Vision Statement

Create a game where every match begins with familiar chess fundamentals but evolves into a completely unique tactical battle.

Players should constantly be asking questions that traditional chess never asks.

- Should I protect my Queen because my deck revolves around her?
    
- Is sacrificing this Bishop worth enabling my Necromancy strategy?
    
- Should I advance this Pawn because I have a powerful Unit card waiting for it?
    
- Do I spend mana improving my position now, or save it to react to my opponent?
    

Wizard Chess should reward both strong chess fundamentals and intelligent card play.

Neither should completely replace the other.

---

# Elevator Pitch

**"What if chess evolved during the match?"**

Wizard Chess preserves the timeless strategy of chess while introducing magical cards that transform pieces, alter movement, reshape the battlefield, and create entirely new tactical possibilities.

Every match tells a different story.

---

# Genre

- Digital Strategy Board Game
    
- Turn-Based Strategy
    
- Tactical Strategy Game
    
- Deck Construction Game
    
- Competitive Multiplayer Strategy
    

---

# Target Platforms

Primary

- Windows PC
    

Future Considerations

- macOS
    
- Linux
    
- Steam Deck
    
- Mobile
    
- Consoles
    

---

# Target Audience

Primary Audience

Players who enjoy:

- Chess
    
- Tactical strategy games
    
- Trading card games
    
- Competitive multiplayer games
    

Secondary Audience

Players who enjoy:

- Deck builders
    
- Roguelikes
    
- Tabletop strategy games
    
- Single-player AI challenges
    

---

# Target Match Length

Average match duration:

**10–20 minutes**

This value is intentionally configurable and will be refined through playtesting.

**Status:** Experimental

---

# Core Design Goals

## 1. Preserve Chess

Traditional chess should remain recognizable from the first move to the final move.

Players with strong chess fundamentals should have a meaningful advantage.

---

## 2. Enhance Rather Than Replace

Cards should introduce new strategic possibilities.

They should not invalidate the importance of positioning, tempo, or tactical planning.

---

## 3. Reward Planning

Players should be rewarded for long-term planning.

Deck construction should influence how players value and protect their chess pieces.

---

## 4. Encourage Emergent Gameplay

No two matches should evolve the same way.

Cards should create unique board states that emerge naturally from player decisions.

---

## 5. Minimize Randomness

Randomness should primarily come from deck construction and card draw.

Once a card is played, game outcomes should be deterministic.

---

## 6. Competitive First

Every rule should support fair competition.

The game should be suitable for:

- Ranked online play
    
- Spectating
    
- Tournament play
    
- Replay analysis
    
- AI opponents
    

---

# Design Philosophy

When multiple design solutions exist, prefer the one that is:

- Simpler
    
- More deterministic
    
- More chess-like
    
- Easier to understand
    
- Easier for both humans and AI to evaluate
    

Complexity should emerge from interactions between systems, not from unnecessarily complicated rules.

---

# Design Pillars

## Chess is Canon

Traditional chess rules always apply unless explicitly overridden by card text.

Cards create exceptions.

Chess remains the foundation.

---

## Simple Rules, Complex Interactions

The core rules should be straightforward.

Depth should emerge from the interaction between chess strategy and magical cards.

---

## Position Is Power

Cards should influence how players think about positioning.

Movement, timing, and board control should matter more than raw numerical bonuses.

---

## Every Piece Matters

Every chess piece should remain strategically valuable throughout the match.

A humble Pawn may become the centerpiece of an entire strategy.

The value of each piece should be influenced by the player's deck and decisions.

---

## Readable Board State

Players should be able to understand the current game state by inspecting the board.

The game should minimize unnecessary bookkeeping and hidden complexity.

---

## Deterministic Gameplay

Every game state should produce a single correct outcome.

No hidden calculations.

No ambiguous interactions.

Hidden information is limited to:

- Cards in players' hands
    
- Face-down Trap cards
    

All other game information is public.

---

# Core Principles

The following principles guide every mechanic added to Wizard Chess.

## Chess Is Canon

All standard chess rules remain in effect unless explicitly overridden by card text.

---

## Cards Create Exceptions

Cards modify the rules of chess.

They do not replace the game itself.

---

## Decisions Over Arithmetic

Cards should create interesting strategic decisions.

Changing movement, positioning, targeting, or timing is preferred over increasing numerical values.

---

## Deterministic Rules

Every rule must produce a single objective outcome.

If two independent developers implement the game using the GDD, they should produce identical gameplay.

---

## AI-Readable Design

Every rule should be objective.

Avoid subjective language such as:

- Nearby
    
- Strongest
    
- Weakest
    
- Dangerous
    
- Protected
    
- Vulnerable
    

Instead, rules should use precise, measurable conditions.

Example:

**Incorrect**

"Target a threatened Pawn."

**Correct**

"Target a Pawn currently attacked by one or more opposing pieces."

---

## Specific Overrides General

If a card contradicts a general game rule, the card's text takes precedence for that interaction only.

---

## Balance Through Variables

Core rules should remain stable.

Balance should primarily be achieved by adjusting configurable values such as:

- Deck size
    
- Starting hand size
    
- Mana cap
    
- Maximum hand size
    
- Card costs
    
- Card rarity
    
- Maximum copies per deck
    

These values should remain configurable throughout development.

---

# Project Philosophy

Wizard Chess should feel like two master wizards sitting down to play an ordinary game of chess, then gradually bending the rules through powerful magic.

The magic should change how players think about the board.

The board should never stop feeling like chess.