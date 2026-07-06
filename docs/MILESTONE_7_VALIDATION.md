# Milestone 7 Validation

Milestone 7 is complete when the shared Wizard Match gameplay UI is suitable for extended local and networked play, remains editor-first in structure, and preserves public/hidden information rules while presenting the authoritative simulation clearly.

## Acceptance Checklist

1. Confirm `res://scenes/chess/local_wizard_match_screen.tscn` loads cleanly through headless scene validation.
2. Confirm `res://scenes/chess/network_wizard_match_screen.tscn` reuses the same core UI composition and owner-oriented perspective mapping.
3. Confirm the match board is editor-authored and texture-based rather than runtime-generated as a grid of procedural controls.
4. Confirm local and opponent hands, pile wells, public zones, wizard status views, and the turn/action surface are scene-authored and visually grouped around the board.
5. Confirm targeted local hand preview states remain inside the intended local decision region and do not overlap the board.
6. Confirm hovered local cards become the readable foreground card without leaking into invalid board space or falling behind tray chrome.
7. Confirm Black-seat network clients view the board from Black’s perspective with correct square mapping.
8. Confirm the inspector clears pinned square state correctly after resolved piece moves.
9. Confirm opponent hidden information remains hidden: opponent hand faces stay concealed, face-down trap identity remains hidden, and hidden trap square/location is not leaked through board markers or hover text.
10. Confirm public information remains visible: graveyards, environment, artifacts, captures, deck counts, mana, turn/phase state, and active cards.
11. Confirm local and networked Wizard Match UI tests pass together.

## Validation Commands

Use explicit `--log-file` for all local headless Godot commands.

```powershell
godot --headless --path . --log-file .godot/local-wizard-screen.log --scene res://scenes/chess/local_wizard_match_screen.tscn --quit-after 2
godot --headless --path . --log-file .godot/gut-ui.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests/ui -ginclude_subdirs -gexit -gexit_on_success
```

## Completion Record

Milestone 7 was accepted as complete on July 5, 2026.

Validated state at acceptance:

- the shared Wizard Match screen is now the active gameplay UI for both local and networked flows
- the board is an editor-authored 832x832 composed surface with texture-based squares and authored frame/background assets
- per-square presentation now lives on dedicated square nodes rather than runtime-generated button wrappers
- local hover/target card presentation, inspector behavior, and black-seat network perspective mapping are covered by UI tests
- the full Wizard Match UI suite passed at acceptance: 24/24 tests passing

Remaining work after Milestone 7 belongs to later polish or future milestones, not to Milestone 7 exit criteria.
