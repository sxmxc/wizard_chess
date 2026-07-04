## Overview

Artificial Intelligence (AI) is a core component of Wizard Chess.

The AI should provide an enjoyable, challenging, and fair opponent for players of all skill levels.

The AI must always operate under the same rules and restrictions as a human player.

At no point should the AI gain hidden information or gameplay advantages unavailable to a human player.

---

# Design Principles

The AI should adhere to the following principles:

- Play by the same rules as the player.
    
- Never cheat.
    
- Make deterministic decisions based on available information.
    
- Prioritize enjoyable gameplay over perfect play.
    
- Support multiple difficulty levels.
    
- Be capable of using any legal deck.
    

---

# Hidden Information

The AI must respect all hidden information within the game.

The AI may not inspect:

- The opponent's hand.
    
- The opponent's deck.
    
- Face-down Trap cards.
    
- Future card draws.
    
- Random outcomes before they occur.
    

The AI should make decisions only from information that is legally available.

---

# Chess Evaluation

The AI should understand traditional chess concepts, including:

- Material advantage.
    
- Piece development.
    
- Board control.
    
- King safety.
    
- Mobility.
    
- Check and checkmate.
    
- Tactical exchanges.
    
- Long-term positioning.
    

Card mechanics should enhance these evaluations rather than replace them.

---

# Card Evaluation

The AI should understand the strategic value of cards.

Factors may include:

- Mana efficiency.
    
- Board impact.
    
- Long-term value.
    
- Synergy with attached Units.
    
- School synergy.
    
- Current board state.
    
- Current hand.
    
- Remaining deck.
    
- Available reactions.
    

The AI should recognize when a card is more valuable later in the match than immediately.

---

# Strategic Planning

The AI should plan beyond the current turn whenever practical.

The AI should consider:

- Future board positions.
    
- Potential reactions.
    
- Resource management.
    
- Card sequencing.
    
- Piece preservation.
    
- Win conditions.
    

Long-term planning should improve as difficulty increases.

---

# Difficulty Levels

Difficulty should be achieved through decision quality rather than unfair advantages.

Examples include:

**Beginner**

- Short planning horizon.
    
- Prioritizes obvious plays.
    
- More forgiving of mistakes.
    

**Intermediate**

- Improved positional awareness.
    
- Better card sequencing.
    
- More consistent tactical play.
    

**Advanced**

- Strong strategic planning.
    
- Effective use of synergies.
    
- Better resource management.
    
- Consistent positional play.
    

**Master**

- Near-optimal decision making.
    
- Excellent positional understanding.
    
- Strong tactical awareness.
    
- Efficient card utilization.
    

All difficulty levels should obey the same game rules.

---

# Personality

Different AI opponents should feel distinct.

Examples include:

- Aggressive
    
- Defensive
    
- Tactical
    
- Positional
    
- Combo-oriented
    
- Reactive
    
- Unpredictable
    

Personality should emerge from decision priorities rather than artificial bonuses.

---

# Wizard Identity

AI opponents should understand the strengths and weaknesses of the Wizard and deck they are using.

Different Wizards should naturally produce different styles of play.

An Arcane Wizard should not behave identically to a Pyromancy Wizard simply because both are controlled by the AI.

---

# Performance

The AI should make decisions within a reasonable amount of time.

Decision time may vary by:

- Difficulty level.
    
- Board complexity.
    
- Game mode.
    

Longer calculations may be appropriate for higher difficulties but should not unnecessarily interrupt gameplay.

---

# Determinism

Given the same game state, available information, and random seed, the AI should produce the same sequence of decisions.

This supports:

- Replays.
    
- Debugging.
    
- Testing.
    
- Competitive integrity.
    

---

# Learning

The AI is not intended to learn from player behavior during a match.

All decisions should be made using the current game state and predefined evaluation logic.

Future versions of the game may introduce adaptive AI as an optional feature.

---

# AI Assistance

The AI may internally evaluate:

- Legal moves.
    
- Card combinations.
    
- Threatened pieces.
    
- Future board states.
    
- Resource efficiency.
    

These evaluations should never reveal hidden information or violate the core game rules.

---

# Design Goals

The AI should:

- Feel intelligent.
    
- Play fairly.
    
- Respect the rules.
    
- Showcase the strategic depth of Wizard Chess.
    
- Encourage player improvement.
    
- Support casual and competitive play.
    

A player should lose because the AI made better decisions—not because it had access to information or abilities that the player did not.