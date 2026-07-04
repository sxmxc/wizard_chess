# Milestone 5 Validation

Use this checklist before treating Milestone 5 as complete.

Status: Completed on July 4, 2026 through automated simulation coverage.

## Required Outcomes

- Unit, Spell, Reaction, Trap, Environment, and Artifact cards all validate and resolve through `WizardMatch`.
- Card timing is enforced by phase and reaction-priority state rather than UI assumptions.
- Reaction cards validate against authoritative reaction-window events.
- Trap cards remain face-down on the battlefield until a legal trigger reveals and resolves them.
- Environment cards replace older Environments deterministically.
- Artifact and Environment cards remain in play as persistent battlefield objects.
- Attached Units remain bound to their chess piece, move with that piece, and leave play when their host is removed.
- Active effects are represented explicitly in match state and survive snapshot round trips.
- Card definitions remain resource-driven, including trigger and effect metadata.

## Recommended Automated Check

```powershell
godot --headless --path . --log-file .godot/gut_full_m5.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests -ginclude_subdirs -gexit
```

## Manual Checklist

1. Start a `WizardMatch` with legal decks containing all supported card types.
2. Play a Spell during Preparation and confirm it resolves immediately into the Graveyard.
3. Attach a Unit to a legal friendly piece and confirm the Unit moves with that piece.
4. Replace an attached Unit on the same piece and confirm the old Unit moves to the Graveyard.
5. Resolve a chess move that opens the Reaction Phase and confirm only the player with reaction priority may act next.
6. Play a legal Reaction whose trigger is currently present in the reaction window and confirm it resolves correctly.
7. Attempt to play a Reaction without priority or without an active trigger and confirm the action is rejected.
8. Set a Trap on a legal square, move a matching opposing piece onto that square, and confirm the Trap reveals, resolves, and leaves play.
9. Play an Environment and then a second Environment and confirm the first one is replaced deterministically.
10. Play an Artifact and confirm it remains on the battlefield as a persistent effect source.
11. Create and load a match snapshot and confirm active effects, reaction state, card zones, and chess state are preserved.

## Current Prototype Boundaries

- Card-type timing, targeting, replacement, triggering, and persistent-effect tracking are implemented as framework behavior.
- Trigger metadata and effect metadata are data-driven, but bespoke card-text execution is still future content work.
- Reaction handling currently validates one legal response at a time using match-owned priority state.
- Networking still synchronizes through snapshot-safe simulation state rather than card-specific presentation events.
- Production UI for card play and inspection is still a later milestone concern and is not required for Milestone 5 completion.
