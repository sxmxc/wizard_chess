extends GutTest

const LOCAL_WIZARD_MATCH_SCREEN_PATH := "res://scenes/chess/local_wizard_match_screen.tscn"


func test_local_wizard_match_screen_builds_playable_match_ui() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene

	assert_not_null(packed_scene)

	var screen := packed_scene.instantiate()
	add_child_autofree(screen)

	assert_not_null(screen.wizard_match)
	assert_true(screen.has_node("PlaymatBackground"))
	assert_true(screen.get_node("PlaymatBackground").visible)
	assert_eq(screen.board_buttons.size(), 64)
	assert_not_null(screen.board_view)
	assert_not_null(screen.interaction_controller)
	assert_not_null(screen.hud_layout)
	assert_not_null(screen.targeting_overlay)
	assert_false(screen.has_node("HudLayer/PlayDropZone"))
	assert_true(screen.status_label.text.begins_with("Turn "))
	assert_false(screen.notification_toast.visible)
	assert_false(screen.inspect_popup.visible)
	assert_true(screen.inspect_popup is WizardMatchInspectorView)
	assert_true(screen.match_sidebar is WizardMatchHudSidebar)
	assert_true(screen.turn_action_panel is WizardMatchTurnActionPanel)
	assert_true(screen.local_deck_pile is WizardMatchPileView)
	assert_true(screen.local_graveyard_pile is WizardMatchPileView)
	assert_true(screen.environment_zone_panel is WizardMatchPublicZonePanel)
	assert_true(screen.artifacts_zone_panel is WizardMatchPublicZonePanel)
	assert_true(screen.traps_zone_panel is WizardMatchPublicZonePanel)
	assert_true(screen.captures_zone_panel is WizardMatchPublicZonePanel)
	assert_eq(screen.utilities_button.text, "Tools")
	assert_gt(screen.local_hand_row.get_child_count(), 0)
	assert_eq(screen.local_hand_title_label.text, "White Hand")
	assert_false(screen.match_sidebar.white_ai_button.button_pressed)
	assert_true(screen.match_sidebar.black_ai_button.button_pressed)

	var hud_layer := screen.get_node("HudLayer")

	assert_true(hud_layer is CanvasLayer)
	assert_true(screen.hud_layout is WizardMatchHudLayout)
	assert_false(screen.match_sidebar.visible)
	assert_false(screen.has_node("HudLayer/LocalZonePanel"))
	assert_true(screen.local_hand_row is HandFanView)
	assert_true(screen.opponent_hand_row is HandFanView)
	assert_true(screen.local_status_view is WizardMatchPlayerStatusView)
	assert_true(screen.opponent_status_view is WizardMatchPlayerStatusView)
	assert_not_null(screen.local_status_view.portrait_texture)
	assert_not_null(screen.opponent_status_view.portrait_texture)
	assert_not_null(screen.local_status_view.mana_texture)
	assert_eq(screen.local_status_view.portrait_texture.get_size(), Vector2(128, 128))
	assert_eq(screen.opponent_status_view.portrait_texture.get_size(), Vector2(128, 128))
	assert_eq(screen.local_status_view.mana_texture.get_size(), Vector2(64, 64))
	assert_eq(screen.local_status_view.mana_count_label.text, "0")
	assert_false(screen.local_status_view.mana_count_label.text.contains("/"))
	assert_gt(screen.board_view.get_piece_nodes().size(), 0)
	assert_eq(screen.inspect_popup.card_preview_center.custom_minimum_size, Vector2(220, 226))

	screen._on_utilities_button_pressed()
	assert_true(screen.match_sidebar.visible)
	assert_eq(screen.utilities_button.text, "Tools ▼")

	await get_tree().process_frame
	var board_rect: Rect2 = screen.board_view.get_global_rect()
	var opponent_hand_rect: Rect2 = screen.opponent_hand_panel.get_global_rect()
	var local_hand_rect: Rect2 = screen.local_hand_panel.get_global_rect()
	var viewport_rect: Rect2 = screen.get_viewport_rect()

	assert_false(opponent_hand_rect.intersects(board_rect), "Opponent hand must stay above the board")
	assert_false(local_hand_rect.intersects(board_rect), "Local hand must stay below the board")
	assert_gte(opponent_hand_rect.position.y, viewport_rect.position.y)
	assert_lte(local_hand_rect.end.y, viewport_rect.end.y)
	assert_almost_eq(opponent_hand_rect.get_center().x, viewport_rect.get_center().x, 2.0)
	assert_almost_eq(local_hand_rect.get_center().x, viewport_rect.get_center().x, 2.0)
	assert_true(opponent_hand_rect.has_point(screen.opponent_status_view.get_global_rect().get_center()))
	assert_true(local_hand_rect.has_point(screen.local_status_view.get_global_rect().get_center()))

	for widget in screen.local_hand_row.get_card_widgets():
		assert_gte(widget.position.x, 0.0)
		assert_lte(widget.position.x + widget.size.x, screen.local_hand_row.size.x)

	for widget in screen.opponent_hand_row.get_card_widgets():
		assert_gte(widget.position.x, 0.0)
		assert_lte(widget.position.x + widget.size.x, screen.opponent_hand_row.size.x)

	_assert_fan_is_centered(screen.local_hand_row)
	_assert_fan_is_centered(screen.opponent_hand_row)

	var first_local_card: WizardMatchCardWidget = screen.local_hand_row.get_card_widgets()[0]
	assert_true(first_local_card is Control)
	assert_eq(first_local_card.get_class(), "Control")
	assert_not_null(first_local_card.get_node("%CardFaceRoot"))
	assert_not_null(first_local_card.get_node("%ManaPipRect"))
	assert_not_null(first_local_card.get_node("%RarityIconRect"))
	assert_not_null(first_local_card.get_node("CardFaceRoot/TitleBannerRect"))
	assert_string_contains(first_local_card.mana_pip_rect.texture.resource_path, "mana_cost_pip_filled.png")
	assert_ne(first_local_card.title_label.text, "TITLE")
	assert_false(first_local_card.title_label.text.is_empty())
	assert_false(first_local_card.art_rect.texture.resource_path.is_empty())
	assert_eq(first_local_card.title_label.text, str(first_local_card.card_state.get("display_name", "")))
	assert_eq(first_local_card.art_rect.texture.resource_path, str(first_local_card.card_state.get("art_texture_path", "")))
	var fan_z_index := first_local_card.z_index
	first_local_card.set_spotlight_active(true)
	first_local_card.set_spotlight_active(false)
	assert_eq(first_local_card.z_index, fan_z_index)

	var first_square = screen.board_buttons[Vector2i.ZERO]
	var untargeted_color: Color = first_square.background_rect.color
	first_square.set_target_emphasis(true, true)
	assert_true(first_square.target_indicator.visible)
	assert_eq(first_square.target_indicator.text, "◆")
	assert_eq(first_square.background_rect.color, untargeted_color)
	assert_eq(screen.local_deck_pile.count_label.text, str(screen.wizard_match.get_player_state(ChessEngine.WHITE).get("deck", []).size()))
	assert_eq(screen.environment_zone_panel.body_label.text, "0")
	assert_eq(screen.artifacts_zone_panel.body_label.text, "0")
	assert_eq(screen.traps_zone_panel.body_label.text, "0")
	assert_eq(screen.captures_zone_panel.body_label.text, "0")
	assert_gt(screen.environment_zone_panel.visual_slots.size(), 0)
	assert_false(screen.environment_zone_panel.visual_slots[0].visible)
	assert_false(screen.artifacts_zone_panel.visual_slots[0].visible)
	assert_false(screen.traps_zone_panel.visual_slots[0].visible)
	assert_false(screen.captures_zone_panel.visual_slots[0].visible)


func test_public_match_zones_reflect_graveyard_environment_traps_and_captures() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var white_state: Dictionary = screen.wizard_match.get_player_state(ChessEngine.WHITE)
	var black_state: Dictionary = screen.wizard_match.get_player_state(ChessEngine.BLACK)
	var graveyard_card: Dictionary = white_state["hand"][0].duplicate(true)
	graveyard_card["display_name"] = "Public Spell"
	graveyard_card["art_texture_path"] = "res://assets/ui/wizard_match/arcane_card_art.png"
	white_state["graveyard"].append(graveyard_card)
	var environment_card: Dictionary = white_state["hand"][1].duplicate(true)
	environment_card["display_name"] = "Astral Weather"
	environment_card["card_type"] = CardDefinition.TYPE_ENVIRONMENT
	white_state["battlefield"].append(environment_card)
	var artifact_card: Dictionary = white_state["hand"][2].duplicate(true)
	artifact_card["display_name"] = "Mirror Relic"
	artifact_card["card_type"] = CardDefinition.TYPE_ARTIFACT
	white_state["battlefield"].append(artifact_card)
	var hidden_trap: Dictionary = black_state["hand"][0].duplicate(true)
	hidden_trap["display_name"] = "Runic Snare"
	hidden_trap["card_type"] = CardDefinition.TYPE_TRAP
	hidden_trap["face_down"] = true
	hidden_trap["placed_on"] = "e4"
	black_state["battlefield"].append(hidden_trap)
	screen.wizard_match.players[ChessEngine.WHITE] = white_state
	screen.wizard_match.players[ChessEngine.BLACK] = black_state
	screen.wizard_match.chess_state.move_history.append({
		"turn_number": 1,
		"color": ChessEngine.WHITE,
		"move": {
			"is_capture": true,
			"captured_piece_type": ChessEngine.PIECE_KNIGHT,
		},
		"notation": "Nxe5",
	})

	screen._refresh_player_zones()
	screen._refresh_environment()

	assert_eq(screen.local_graveyard_pile.count_label.text, "1")
	assert_false(screen.local_graveyard_pile.visual_rect.visible)
	assert_true(screen.local_graveyard_pile.top_card_widget.visible)
	assert_eq(screen.local_graveyard_pile.top_card_widget.title_label.text, "Public Spell")
	assert_eq(screen.local_graveyard_pile.top_card_widget.art_rect.texture.resource_path, "res://assets/ui/wizard_match/arcane_card_art.png")
	assert_eq(screen.local_graveyard_pile.tooltip_text, "White Graveyard: 1\nTop: Public Spell")
	assert_eq(screen.local_deck_pile.visual_rect.texture.resource_path, "res://assets/ui/wizard_match/card_back.png")
	assert_true(screen.environment_zone_panel.visual_slots[0].visible)
	assert_eq(screen.environment_zone_panel.visual_slots[0].texture.resource_path, str(environment_card.get("art_texture_path", "")))
	assert_string_contains(screen.environment_zone_panel.visual_slots[0].tooltip_text, "Astral Weather")
	assert_true(screen.artifacts_zone_panel.visual_slots[0].visible)
	assert_eq(screen.artifacts_zone_panel.visual_slots[0].texture.resource_path, str(artifact_card.get("art_texture_path", "")))
	assert_string_contains(screen.artifacts_zone_panel.visual_slots[0].tooltip_text, "Mirror Relic")
	assert_true(screen.traps_zone_panel.visual_slots[0].visible)
	assert_eq(screen.traps_zone_panel.visual_slots[0].texture.resource_path, "res://assets/ui/wizard_match/card_back.png")
	assert_string_contains(screen.traps_zone_panel.visual_slots[0].tooltip_text, "Face-down Trap")
	assert_false(screen.traps_zone_panel.visual_slots[0].tooltip_text.contains("e4"))
	assert_false(screen._square_marker_text(screen.wizard_match.chess_engine.algebraic_to_square("e4")).contains("Trap"))
	assert_true(screen.captures_zone_panel.visual_slots[0].visible)
	assert_not_null(screen.captures_zone_panel.visual_slots[0].texture)
	assert_string_contains(screen.captures_zone_panel.visual_slots[0].tooltip_text, "White captured Black Knight")


func test_modular_playmat_parts_are_authored_and_clear_of_the_board() -> void:
	var screen: Variant = await _instantiate_screen_at_viewport_size(Vector2i(1920, 1080))
	var board_rect: Rect2 = screen.board_view.get_global_rect()
	var playmat := screen.get_node("PlaymatBackground") as TextureRect

	assert_eq(playmat.texture.resource_path, "res://assets/ui/wizard_match/playmat_parts/table_base.png")
	assert_string_contains(screen.get_node("HudLayer/LocalHandPanel/HandTrayTexture").texture.resource_path, "hand_tray.png")
	assert_string_contains(screen.get_node("HudLayer/OpponentHandPanel/HandTrayTexture").texture.resource_path, "hand_tray.png")
	var player_library_panel := screen.get_node("HudLayer/PlayerLibraryPanel") as PanelContainer
	var player_library_stylebox := player_library_panel.get("theme_override_styles/panel") as Resource
	assert_string_contains(player_library_stylebox.resource_path, "card_well.tres")
	var environment_zone_panel := screen.get_node("HudLayer/EnvironmentZonePanel") as PanelContainer
	var environment_zone_stylebox := environment_zone_panel.get("theme_override_styles/panel") as Resource
	assert_string_contains(environment_zone_stylebox.resource_path, "tray_panel.tres")
	for zone_path in [
		"HudLayer/EnvironmentZonePanel",
		"HudLayer/ArtifactsZonePanel",
		"HudLayer/TrapsZonePanel",
		"HudLayer/LocalCapturesZonePanel",
	]:
		assert_false(screen.get_node(zone_path).get_global_rect().intersects(board_rect), "%s overlaps board" % zone_path)


func test_hud_sidebar_owns_lists_settings_and_card_selection_mapping() -> void:
	var sidebar_scene := load("res://scenes/ui/wizard_match_hud_sidebar.tscn") as PackedScene
	var sidebar: WizardMatchHudSidebar = sidebar_scene.instantiate()
	add_child_autofree(sidebar)
	var selected_card_ids: Array[String] = []
	sidebar.card_selected.connect(func(card_instance_id: String) -> void: selected_card_ids.append(card_instance_id))

	sidebar.set_histories(["1. e4"], ["White began preparation"])
	sidebar.set_active_cards([{"card_instance_id": "active-1", "label": "White: Test Artifact"}])
	sidebar.set_graveyards(
		[{"card_instance_id": "white-grave-1", "label": "Spent Spell"}],
		[]
	)
	sidebar.set_settings(true, false, 2, true, false)
	sidebar.active_cards_list.select(0)
	sidebar.active_cards_list.item_selected.emit(0)

	assert_eq(sidebar.move_history_list.get_item_text(0), "1. e4")
	assert_eq(sidebar.event_history_list.get_item_text(0), "White began preparation")
	assert_eq(sidebar.black_graveyard_list.get_item_text(0), "(empty)")
	assert_eq(selected_card_ids, ["active-1"])
	assert_true(sidebar.threat_toggle.button_pressed)
	assert_false(sidebar.coordinates_toggle.button_pressed)
	assert_eq(sidebar.perspective_option.selected, 2)
	assert_true(sidebar.white_ai_button.button_pressed)
	assert_false(sidebar.black_ai_button.button_pressed)


func test_hud_layout_component_owns_major_region_geometry() -> void:
	var layout_scene := load("res://scenes/ui/wizard_match_hud_layout.tscn") as PackedScene
	assert_not_null(layout_scene)
	var layout := layout_scene.instantiate() as WizardMatchHudLayout
	add_child_autofree(layout)
	assert_true(layout is WizardMatchHudLayout)


func test_inspector_component_presents_card_and_square_details() -> void:
	var inspector_scene := load("res://scenes/ui/wizard_match_inspector_view.tscn") as PackedScene
	var inspector: WizardMatchInspectorView = inspector_scene.instantiate()
	add_child_autofree(inspector)
	var card_state := {
		"card_id": "test_card",
		"display_name": "Test Card",
		"card_type": "spell",
		"mana_cost": 2,
		"rules_text": "Test rules.",
		"target_requirements": ["square"],
	}

	inspector.show_card(card_state, "hand", ChessEngine.WHITE, null)

	assert_true(inspector.visible)
	assert_eq(inspector.title_label.text, "Test Card")
	assert_true(inspector.card_preview.visible)
	assert_false(inspector.square_preview_frame.visible)
	assert_eq(inspector.card_preview.title_label.text, "Test Card")
	assert_string_contains(inspector.body_label.text, "Owner: White")
	assert_string_contains(inspector.body_label.text, "Targeting: square")
	assert_eq(inspector.card_preview_center.custom_minimum_size, Vector2(220, 226))

	inspector.show_square("e4", null, "white pawn", ["Bound Familiar"], ["e5"], true)

	assert_eq(inspector.title_label.text, "Square e4")
	assert_false(inspector.card_preview.visible)
	assert_true(inspector.square_preview_frame.visible)
	assert_string_contains(inspector.body_label.text, "Attached Units: Bound Familiar")
	assert_string_contains(inspector.body_label.text, "Threatened: yes")

	inspector.clear_inspection()
	assert_false(inspector.visible)


func test_card_hover_only_temporarily_drives_inspector() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var card_id: String = screen.local_hand_widgets.keys()[0]
	var widget: WizardMatchCardWidget = screen.local_hand_widgets[card_id]
	var expected_title := str(widget.card_state.get("display_name", ""))

	screen.on_card_widget_hovered(widget)
	assert_eq(screen.inspect_popup.title_label.text, expected_title)
	assert_eq(screen.selected_card_instance_id, "")

	screen.on_card_widget_unhovered(widget)
	assert_false(screen.inspect_popup.visible)
	assert_eq(screen.selected_card_instance_id, "")

	screen._on_hand_card_pressed(card_id)
	assert_eq(screen.selected_card_instance_id, card_id)
	assert_true(screen.inspect_popup.visible)

	screen.on_card_widget_hovered(widget)
	screen.on_card_widget_unhovered(widget)
	assert_true(screen.inspect_popup.visible)
	assert_eq(screen.inspect_popup.title_label.text, expected_title)
	assert_eq(screen.selected_card_instance_id, card_id)


func test_piece_hover_drives_inspector_and_square_tint() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var square: Vector2i = screen.wizard_match.chess_engine.algebraic_to_square("e2")
	var button = screen.board_buttons[square]
	var base_color: Color = button.background_rect.color

	screen._on_board_square_hovered(square)

	assert_true(screen.inspect_popup.visible)
	assert_eq(screen.inspect_popup.title_label.text, "Square e2")
	assert_string_contains(screen.inspect_popup.body_label.text, "Piece: White Pawn")
	assert_ne(button.background_rect.color, base_color)

	screen._on_board_square_unhovered(square)

	assert_false(screen.inspect_popup.visible)
	assert_eq(button.background_rect.color, base_color)


func test_selected_piece_can_be_cleared_without_locking_inspector() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var square: Vector2i = screen.wizard_match.chess_engine.algebraic_to_square("e2")

	screen.selected_square = square
	screen.hovered_square = square
	screen.selected_moves = [{"to": screen.wizard_match.chess_engine.algebraic_to_square("e3")}]
	screen._refresh_ui()

	assert_eq(screen.selected_square, square)
	assert_false(screen.selected_moves.is_empty())
	assert_true(screen.inspect_popup.visible)

	screen._on_board_square_pressed(square)
	assert_eq(screen.selected_square, null)
	assert_true(screen.selected_moves.is_empty())
	assert_true(screen.inspect_popup.visible)

	screen._on_board_square_unhovered(square)
	assert_false(screen.inspect_popup.visible)


func test_after_action_clears_pinned_square_inspector() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var square: Vector2i = screen.wizard_match.chess_engine.algebraic_to_square("e2")

	screen.selected_square = square
	screen.hovered_square = square
	screen.selected_moves = [{"to": screen.wizard_match.chess_engine.algebraic_to_square("e3")}]
	screen._refresh_ui()

	assert_true(screen.inspect_popup.visible)
	assert_eq(screen.inspect_popup.title_label.text, "Square e2")

	screen._after_action({"ok": true}, "Move e2 to e3")

	assert_eq(screen.selected_square, null)
	assert_false(screen.inspect_popup.visible)


func test_escape_clears_pinned_card_selection() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var card_id: String = screen.local_hand_widgets.keys()[0]

	screen._on_hand_card_pressed(card_id)
	assert_eq(screen.selected_card_instance_id, card_id)

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	screen._input(event)

	assert_eq(screen.selected_card_instance_id, "")


func test_right_click_clears_pinned_square_selection() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var square: Vector2i = screen.wizard_match.chess_engine.algebraic_to_square("e2")
	screen.selected_square = square
	screen.selected_moves = [{"to": screen.wizard_match.chess_engine.algebraic_to_square("e3")}]
	screen._refresh_ui()

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	screen._input(event)

	assert_eq(screen.selected_square, null)
	assert_true(screen.selected_moves.is_empty())


func test_interaction_controller_exposes_explicit_drag_states() -> void:
	var controller := CardInteractionController.new()
	add_child_autofree(controller)

	controller.begin_card_drag("card-1", Vector2(20, 30), true)
	assert_eq(controller.state, CardInteractionController.State.CARD_TARGETING)
	assert_eq(controller.drag_kind(), "card_target")

	controller.begin_card_drag("card-2", Vector2(40, 50), false)
	assert_eq(controller.state, CardInteractionController.State.CARD_DRAGGING)
	assert_eq(controller.drag_kind(), "card_play")

	controller.begin_piece_drag(Vector2i(1, 2), Vector2(60, 70))
	assert_eq(controller.state, CardInteractionController.State.PIECE_DRAGGING)
	assert_eq(controller.drag_kind(), "piece")

	controller.reset_drag()
	assert_eq(controller.state, CardInteractionController.State.IDLE)
	assert_false(controller.is_dragging())


func test_invalid_card_release_cancels_targeting_and_selection() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var card_id: String = screen.local_hand_widgets.keys()[0]

	screen.selected_card_instance_id = card_id
	screen.interaction_controller.begin_card_drag(card_id, Vector2(-100, -100), true)
	screen._finalize_active_drag()

	assert_eq(screen.interaction_controller.state, CardInteractionController.State.IDLE)
	assert_eq(screen.selected_card_instance_id, "")
	assert_false(screen.targeting_overlay.visible)


func test_targeted_card_preview_stays_inside_reserved_local_hand_region() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var card_id: String = screen.local_hand_widgets.keys()[0]
	var widget: WizardMatchCardWidget = screen.local_hand_widgets[card_id]

	screen.selected_card_instance_id = card_id
	screen.interaction_controller.begin_card_drag(card_id, widget.get_card_center_global(), true)
	screen._refresh_hand_fan_views()
	await get_tree().process_frame

	var bounds: Rect2 = screen.local_hand_row.get_card_visual_bounds_global(widget)
	assert_true(screen.local_hand_panel.get_global_rect().has_point(bounds.get_center()))
	assert_false(bounds.intersects(screen.board_view.get_global_rect()))


func test_resting_hands_are_half_revealed_and_clear_of_fixed_board() -> void:
	var viewport_size := Vector2i(1920, 1080)
	var screen: Variant = await _instantiate_screen_at_viewport_size(viewport_size)
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var board_rect: Rect2 = screen.board_view.get_global_rect()
	assert_eq(screen.board_view.size, Vector2(832, 832))
	for bounds: Rect2 in screen.opponent_hand_row.get_all_card_visual_bounds_global():
		_assert_resting_card_reveal(viewport_rect, bounds, "Opponent resting card")
		assert_false(bounds.intersects(board_rect), "Opponent card intersects fixed board")
	for bounds: Rect2 in screen.local_hand_row.get_all_card_visual_bounds_global():
		assert_gt(bounds.get_center().y, board_rect.end.y, "Local resting card should stay in the local tray territory")
		assert_false(bounds.intersects(board_rect), "Local card intersects fixed board")


func test_static_hud_regions_keep_editor_authored_sides() -> void:
	var screen: Variant = await _instantiate_screen_at_viewport_size(Vector2i(1600, 900))
	var board_rect: Rect2 = screen.board_view.get_global_rect()
	var turn_rect: Rect2 = screen.get_node("HudLayer/TurnPanel").get_global_rect()
	# var local_graveyard_rect: Rect2 = screen.get_node("HudLayer/PlayerGraveyardPanel").get_global_rect()
	# var local_library_rect: Rect2 = screen.get_node("HudLayer/PlayerLibraryPanel").get_global_rect()
	# var opponent_graveyard_rect: Rect2 = screen.get_node("HudLayer/OpponentGraveyardPanel").get_global_rect()
	# var opponent_library_rect: Rect2 = screen.get_node("HudLayer/OpponentLibraryPanel").get_global_rect()

	# assert_lt(local_graveyard_rect.end.x, board_rect.position.x, "Local graveyard should stay on the local left side")
	# assert_lt(local_library_rect.end.x, board_rect.position.x, "Local library should stay paired with local graveyard")
	# assert_gt(opponent_graveyard_rect.position.x, board_rect.end.x, "Opponent graveyard should stay on the opponent right side")
	# assert_gt(opponent_library_rect.position.x, board_rect.end.x, "Opponent library should stay paired with opponent graveyard")
	assert_gt(turn_rect.position.x, board_rect.end.x, "Turn controls should stay to the right of the board")
	assert_false(turn_rect.intersects(board_rect), "Turn controls should not overlap the board")


func test_inspector_avoids_right_side_turn_controls() -> void:
	var screen: Variant = await _instantiate_screen_at_viewport_size(Vector2i(1600, 900))
	var card_state := {
		"card_id": "mana_storm",
		"display_name": "Mana Storm",
		"card_type": "environment",
		"mana_cost": 2,
		"rules_text": "Prototype environment used to validate AI battlefield planning.",
	}

	screen.inspect_popup.show_card(card_state, "hand", ChessEngine.WHITE, null)
	screen.hud_layout.apply_layout(Vector2(1600, 900))
	await get_tree().process_frame

	assert_false(screen.inspect_popup.get_global_rect().intersects(screen.get_node("HudLayer/TurnPanel").get_global_rect()))


func test_hovered_local_card_becomes_readable_foreground_card() -> void:
	var screen: Variant = await _instantiate_screen_at_viewport_size(Vector2i(1920, 1080))
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(1920, 1080))

	for widget: Control in screen.local_hand_row.get_card_widgets():
		var base_bounds: Rect2 = screen.local_hand_row.get_card_visual_bounds_global(widget)
		widget.set_spotlight_active(true)
		var bounds: Rect2 = screen.local_hand_row.get_card_visual_bounds_global(widget)
		assert_gt(bounds.size.x, base_bounds.size.x, "Hovered local card should enlarge for readability")
		assert_gt(widget.z_index, screen.local_status_view.z_index, "Hovered local card should appear above portrait/status chrome")
		assert_false(bounds.intersects(screen.board_view.get_global_rect()), "Hovered local card should stay clear of the board")
		assert_gt(bounds.get_center().y, viewport_rect.get_center().y, "Hovered local card should remain in the local half of the table")
		widget.set_spotlight_active(false)


func test_right_click_cancels_active_card_drag() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen := packed_scene.instantiate()
	add_child_autofree(screen)
	var card_id: String = screen.local_hand_widgets.keys()[0]
	var widget: WizardMatchCardWidget = screen.local_hand_widgets[card_id]
	widget.is_pointer_down = true
	widget.is_dragging = true
	screen.selected_card_instance_id = card_id
	screen.interaction_controller.begin_card_drag(card_id, Vector2(100, 100), true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true

	screen._input(event)

	assert_eq(screen.interaction_controller.state, CardInteractionController.State.IDLE)
	assert_eq(screen.selected_card_instance_id, "")
	assert_false(widget.is_pointer_down)
	assert_false(widget.is_dragging)


func _assert_fan_is_centered(hand: HandFanView) -> void:
	var widgets := hand.get_card_widgets()
	if widgets.is_empty():
		return
	var min_x := INF
	var max_x := -INF
	for widget in widgets:
		var center_x: float = widget.position.x + widget.size.x * 0.5
		min_x = minf(min_x, center_x)
		max_x = maxf(max_x, center_x)
	assert_almost_eq((min_x + max_x) * 0.5, hand.size.x * 0.5, 2.0)


func _instantiate_screen_at_viewport_size(viewport_size: Vector2i) -> Variant:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene
	var screen: Variant = packed_scene.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame
	screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	screen.position = Vector2.ZERO
	screen.offset_left = 0.0
	screen.offset_top = 0.0
	screen.offset_right = viewport_size.x
	screen.offset_bottom = viewport_size.y
	await get_tree().process_frame
	screen.hud_layout.apply_layout(Vector2(viewport_size))
	await get_tree().process_frame
	return screen


func _assert_rect_inside(outer: Rect2, inner: Rect2, message: String) -> void:
	var tolerance: float = 1.0
	assert_gte(inner.position.x, outer.position.x - tolerance, message)
	assert_gte(inner.position.y, outer.position.y - tolerance, message)
	assert_lte(inner.end.x, outer.end.x + tolerance, message)
	assert_lte(inner.end.y, outer.end.y + tolerance, message)


func _assert_resting_card_reveal(viewport_rect: Rect2, card_bounds: Rect2, message: String) -> void:
	var visible_bounds := card_bounds.intersection(viewport_rect)
	var visible_ratio := visible_bounds.size.y / card_bounds.size.y
	assert_gt(visible_ratio, 0.35, "%s should remain identifiable" % message)
	assert_lt(visible_ratio, 0.72, "%s should conserve table space" % message)
