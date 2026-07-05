# Milestone 7 UI Handoff

## Current Truth

The local Milestone 7 match UI is functional and now uses a modular, editor-authored table composition. It is no longer the old debug-screen layout, but it is also not visually complete enough to call final production UI yet.

Interactive visual review in the Godot editor remains the final acceptance step; headless geometry and state tests do not replace that review.

The screen has moved away from the original monolithic debug layout and now presents the match through editor-authored surfaces:

- editor-first workflows
- composition over inheritance
- deterministic presentation derived from simulation state
- maintainability over cleverness
- card-game readability over debug-screen convenience

`LocalWizardMatchScreen` still coordinates too much state refresh, but the major visible regions now have composition boundaries and regression coverage. The screenshot review on the local/AI screen showed that passing tests is not enough: authored zones must be visually placed, must not overlap the board, and must not leak hidden information through hover text or board markers.

Current practical status:

- the chessboard remains fixed at 736x736 and is no longer shrunk to create HUD space
- hand trays, pile wells, public-card trays, portrait frames, and the inspector are modular authored surfaces
- hands and portraits are now scene-authored and should be tuned in the editor first, not by adding more hard-coded runtime offsets
- the local scene is the active Milestone 7 proving ground; multiplayer UI reuse is the next step after local visual acceptance

## Valid Current Architecture

These extracted pieces are still valid and should be preserved:

- `res://scenes/ui/hand_fan_view.tscn`
- `res://scripts/ui/hand_fan_view.gd`
- `res://scenes/ui/targeting_overlay.tscn`
- `res://scripts/ui/targeting_overlay.gd`
- `res://scripts/ui/card_interaction_controller.gd`
- `res://scenes/ui/wizard_match_inspector_view.tscn`
- `res://scripts/ui/wizard_match_inspector_view.gd`
- `res://scenes/ui/wizard_match_hud_sidebar.tscn`
- `res://scripts/ui/wizard_match_hud_sidebar.gd`
- `res://scenes/ui/wizard_match_hud_layout.tscn`
- `res://scripts/ui/wizard_match_hud_layout.gd`
- `res://scenes/ui/wizard_match_player_status_view.tscn`
- `res://scripts/ui/wizard_match_player_status_view.gd`
- `res://scripts/ui/wizard_match_pile_view.gd`
- `res://scripts/ui/wizard_match_turn_action_panel.gd`
- `res://scripts/ui/wizard_match_public_zone_panel.gd`
- `res://scenes/ui/wizard_match_visual_slot.tscn`
- `res://scenes/ui/wizard_match_piece_slot.tscn`

The direction is correct only when these are used as editor-visible composition boundaries. Avoid replacing scene composition with custom `_draw()` surfaces or large procedural layout methods.

The local hand card widget is also now a valid composed surface:

- `res://scenes/ui/wizard_match_card_widget.tscn`
- `res://scripts/ui/wizard_match_card_widget.gd`

It should remain a `Control`, not a `Button`. Interaction is handled through explicit pointer input and a local `pressed` signal. The card face is composed from reusable 2D texture layers and data-driven labels.

## Valid Product Direction

The screen should read like a card-game match wrapped around a chessboard, not like a diagnostics panel around a board.

The intended three-region structure remains valid:

- opponent strip: compact wizard status, compact hidden hand count/silhouettes, deck/graveyard counts
- central playfield: uninterrupted chessboard, targeting feedback, contextual inspection only when useful
- local dock: local wizard status, readable hand, deck/graveyard counts, one dominant phase/action control

As of the current local scene pass, moving the wizard portraits off the board centerline improved readability substantially. That direction is correct: player identity should read as part of the owner’s tray/territory, not as chrome sitting over the board.

The opponent hand should not show card faces. It uses enlarged card backs at 86x122 and leaves roughly half of each resting card visible. The local hand uses 124x177 cards with the same half-revealed resting behavior. Hovered and targeted local cards lift into a readable foreground state.

The local hand is the primary decision surface. Idle cards may sit low in the dock. Hovered cards should become the readable foreground card and may overlap lower chrome; tests now assert foreground z-order and viewport containment instead of requiring hover to avoid the board at all costs.

Static HUD regions should be authored in the scene with anchors and offsets, not buried in layout code. The pile pairs, turn/action panel, environment slots, artifact slots, trap slots, and captured-piece slots are editor-authored in `local_wizard_match_screen.tscn`; `WizardMatchHudLayout` should only handle board-dependent responsive regions, z-order, and collision avoidance for dynamic overlays such as the inspector.

Secondary surfaces should not compete with the board or hand:

- move history
- event history
- settings
- AI controls
- timing diagnostics
- full graveyard browsing

Those belong in drawers, dev overlays, or utility surfaces.

## Current Asset Direction

Text stand-ins such as `"White Wizard"`, `"Black Wizard"`, and `"0/0 mana"` should not be visible match UI.

Current player-status assets:

- `res://assets/ui/wizard_match/generated/white_wizard_portrait.png`
- `res://assets/ui/wizard_match/generated/black_wizard_portrait.png`
- `res://assets/ui/wizard_match/generated/mana_crystal.png`

Current player-status sizes:

- wizard portraits: 128x128 PNG with alpha
- mana crystal: 64x64 PNG with alpha
- the player status badge displays current mana only, centered at the top of the portrait

These are first-pass assets only. Keep using assets for player identity and resources, but improve them through composed scenes and visual QA, not procedural placeholder rendering.

Current modular playmat assets:

- `res://assets/ui/wizard_match/playmat_parts/table_base.png` - active 1920x1080 table and central board-field base, with no baked hand rails, portrait mounts, card wells, or utility panels
- `res://assets/ui/wizard_match/playmat_parts/hand_tray.png` - reusable continuous hand rail with no baked card divisions
- `res://assets/ui/wizard_match/playmat_parts/card_well.png` - reusable portrait card well used by piles and card-zone slots
- `res://assets/ui/wizard_match/playmat_parts/wizard_portrait_frame.png` - reusable player-status portrait mount
- `res://assets/ui/wizard_match/playmat_parts/utility_tray.png` - reusable framed tray used behind public zones and card inspection

The older `playmat_bg*.png` files are retained as source/reference assets but are no longer the active scene background. Do not bake authored card positions, pile wells, portrait rings, or hand slots back into the table base.

Current card-front asset kit:

- `res://assets/ui/wizard_match/card_front/card_paper_texture.png` - 512x768 reusable card body paper texture
- `res://assets/ui/wizard_match/card_front/card_outer_frame.png` - 512x768 alpha outer-frame overlay
- `res://assets/ui/wizard_match/card_front/card_art_frame.png` - 384x220 alpha art-window frame overlay
- `res://assets/ui/wizard_match/card_front/mana_cost_pip.png` - 128x128 alpha cost pip; Godot should draw the cost number on top
- `res://assets/ui/wizard_match/card_front/mana_cost_pip_filled.png` - generated filled mana cost pip for readable number overlay
- `res://assets/ui/wizard_match/card_front/card_title_banner.png` - generated title banner with a dark readable center over card art
- `res://assets/ui/wizard_match/card_front/rarity_icons.png` - 512x128 alpha icon strip for common, uncommon, rare, and legendary

These card assets are intentionally composable. `wizard_match_card_widget.tscn` now layers these assets directly: paper texture, art, art frame, title banner, outer frame, filled mana pip, rarity atlas icon, and data-driven title/type/rules text. Continue improving this as scene composition rather than baking complete card images per card. Card-specific art, cost, title, type, rules text, and rarity should continue to come from card data and runtime state.

Card artwork is now content-authored on `CardDefinition.art_texture`. Runtime card state stores the serializable `art_texture_path`, and UI card/inspector rendering should prefer that path before falling back to school-level placeholder art.

## Current Completed State

The current local match screen now has:

- a composed `Control` card face using layered 2D textures, data-driven title, mana, type, rules, rarity, and authored card art
- filled mana pip and title banner assets for readable card text
- authored deck/graveyard pile nodes using `WizardMatchPileView`
- deck piles shown as hidden card backs/counts
- graveyard piles shown as public full-card top cards/counts
- authored visual slot panels for current Environment, Artifacts, face-down Traps in play, and captured pieces
- modular playmat composition with separate table base, hand tray, card well, portrait frame, and utility tray textures
- a fixed authored 736x736 board frame; responsive layout no longer shrinks the board to create HUD space
- enlarged half-revealed local and opponent hands with complete-card scaling instead of partial child stretching
- a card-focused inspector that renders the actual composed card widget rather than a raw art image plus metadata panel
- the card inspector now uses a tighter composed presentation so hover and targeting review do not leave as much empty dead space beside the board
- face-down opponent Trap slots and board markers that do not reveal the hidden trap square to the viewer
- captured-piece slots that use the piece atlas rather than textual lists
- a composed turn/action panel with primary-action styling
- board readability pass for square colors and larger pieces
- UI tests for card data binding, authored-art rendering, public graveyard display, environment/trap/capture visual zones, static HUD placement, hand bounds, and inspector avoidance

Additional current truth after later tuning:

- `HudLayer` is now a `Control`, so authored HUD anchors resolve against a proper full-screen control root at runtime
- hand-panel and portrait placement are no longer being recomputed by broad runtime layout math
- `WizardMatchHudLayout` now only handles narrow responsive behavior such as inspector placement, sidebar clamping, and z-order, rather than trying to own the entire HUD geometry
- the local portrait positions have been moved in the editor to improve match readability and territory clarity

## Remaining Risks

- `LocalWizardMatchScreen` still owns too much orchestration and refresh logic.
- `WizardMatchHudLayout` still exists, but static pile, public-zone, and turn-panel placement should remain scene-authored. Do not move those back into hard-coded layout math.
- the modular assets need final in-editor visual acceptance at the 1920x1080 project viewport; automated capture through Godot's headless dummy renderer is not reliable in 4.7.
- lower display sizes cannot preserve a fixed 736 board plus two full readable hand states without overlap; the project currently treats 1920x1080 as the authored gameplay viewport and uses canvas-item stretching for smaller windows.
- local card faces have a composed texture-layer pass; they may still need editor visual QA for typography, spacing, and card-type readability.
- visual QA is still insufficient; headless tests do not prove the screen feels good at runtime.
- AI/dev controls and diagnostics still need a cleaner developer-only path.
- multiplayer has not been visually proven. Keep player identity/status/pile/hand/public-zone views simulation-derived and owner-oriented so local, host, client, spectator, and replay views can reuse the same composed components.

Known visual gaps still visible in the current local scene:

- the opponent hand remains smaller than desired relative to the available tray space
- the action area still reads more like HUD text than a deliberate tabletop tray
- side-zone labels still dominate more than the slot visuals themselves
- the board presentation is serviceable, but it still feels less integrated with the table than the card and pile surfaces do

## Obsolete Or Misleading Notes

Ignore older guidance in previous versions of this file that says the following are next steps:

- extract hand fan layout: already done
- introduce explicit interaction states: already done
- remove `PlayDropZone`: already done
- extract targeting overlay: already done
- extract inspector: already done
- extract HUD sidebar: already done
- add transformed-card bounds tests: partially done and useful, but not a substitute for visual QA
- keep tuning panel offsets: wrong direction
- make opponent hand a mirrored full-card fan: wrong direction
- solve UI quality through hidden labels or shorter labels: wrong direction

## Godot 4.7 UI Note

Godot 4.7 adds `Control` offset transform support for visual offsets on child controls. This is relevant for card hover/lift, portrait overlap, and small local visual nudges because it can separate visual placement from layout ownership.

The hand fan still uses scripted `position`, `rotation`, and `z_index` for deterministic fan layout. Hover/lift now uses `Control` offset transform properties (`offset_transform_position`, `offset_transform_scale`, and visual-only input behavior) so layout-owned positions remain stable while the card is visually raised and enlarged. `HandFanView` has explicit visual-bounds helpers that include those offset transforms for tests and QA.

## Important Rules Clarification

After playing a preparation card, chess piece movement is not immediately available unless the player ends preparation.

That is rules-correct.

Relevant simulation flow:

- `resolve_beginning_phase()` -> `PHASE_PREPARATION`
- `finish_preparation_phase()` -> `PHASE_MOVE`
- `apply_move_action()` -> `PHASE_REACTION`
- two passes in reaction -> `PHASE_END`

Relevant methods:

- `finish_preparation_phase()`
- `apply_move_action()`
- `pass_reaction_phase()`
- `play_card_from_hand()`

Do not “fix” this in UI unless the rules change.

## Next Implementation Plan

1. Complete interactive visual acceptance at the authored 1920x1080 viewport and tune only scene offsets or modular assets found to be visually incorrect.
2. Enlarge the opponent hand presentation and continue pushing both hand systems toward deliberate tabletop card presence.
3. Replace HUD-feeling action/readout presentation with a more authored card/tray surface.
4. Reuse the local match UI components for the hosted/client multiplayer screen instead of duplicating UI logic.
5. Prove the same public/hidden information rules through multiplayer snapshots: hand/deck hidden, graveyard/captures/environment/artifacts public, face-down Trap identity and square hidden until reveal.
6. Move more HUD refresh mapping out of `LocalWizardMatchScreen` only where it reduces real complexity.
7. Keep headless tests for geometry, scene wiring, data binding, and public/hidden information regressions.

## Validation Commands

Use explicit `--log-file` for all local headless Godot commands.

```powershell
godot --headless --path . --log-file .godot/local-wizard-ui.log --scene res://scenes/chess/local_wizard_match_screen.tscn --quit-after 2
godot --headless --path . --log-file .godot/gut-ui.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests/ui -ginclude_subdirs -gexit -gexit_on_success
godot --headless --path . --log-file .godot/gut.log --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests -ginclude_subdirs -gexit -gexit_on_success
```
