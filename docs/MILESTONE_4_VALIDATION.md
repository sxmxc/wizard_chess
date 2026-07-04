# Milestone 4 Validation

Use this checklist before treating Milestone 4 as complete.

## Required Outcomes

- The authoritative match state lives in `WizardMatch`, with chess rules delegated through `ChessEngine`.
- A match initializes with validated decks, shuffled opening hands, and a mulligan step before turn 1 begins.
- Turn phases are enforced in order: Beginning, Preparation, Move, Reaction, End.
- Mana refreshes at the beginning of the turn and is consumed when cards are played.
- Deck, hand, battlefield, graveyard, and hand-count transitions are tracked in simulation state.
- The Event Queue records setup, card-play, move, discard, and turn-transition events.
- Card definitions and deck definitions load from Resources.
- Basic card play validation rejects illegal timing, insufficient mana, invalid deck lists, and invalid targets.
- End-of-turn hand-size enforcement supports explicit discard selection rather than hidden automatic discards.

## Recommended Automated Check

```powershell
godot --headless --path . --log-file .godot/gut.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests -ginclude_subdirs -gexit -gexit_on_success
```

## Manual Checklist

1. Start a `WizardMatch` with two legal decks and confirm both players receive opening hands before turn 1 begins.
2. Confirm each player may either keep or mulligan once, and that the match does not enter the first turn until both players finish setup.
3. Resolve the Beginning Phase and confirm maximum mana increases, mana refreshes, and a card draw occurs for the active player.
4. Play a legal Preparation-phase card and confirm mana is spent and the card moves to the correct zone.
5. Attempt to play a card with the wrong timing, insufficient mana, or invalid target and confirm the action is rejected without changing match state.
6. Resolve a legal chess move in the Move Phase and confirm the match advances to the Reaction Phase.
7. Pass the Reaction Phase and confirm the match enters the End Phase.
8. Force a hand above the configured limit, resolve the End Phase, and confirm the player must explicitly choose discards before the turn ends.
9. Create and load a match snapshot and confirm the restored match preserves chess state, card zones, setup state, and event history.
10. Confirm card and deck Resources under `content/` load successfully without hardcoded gameplay data.

## Current Prototype Boundaries

- Card timing, targeting, zones, deck validation, and setup flow are implemented as framework rules only.
- Full card resolution for every card type was completed in Milestone 5 on July 4, 2026.
- `NetworkMatchBridge` still synchronizes chess-only matches through the compatibility `ChessMatch` wrapper.
- Production gameplay UI for cards, hands, graveyards, and phases remains later milestone work.
