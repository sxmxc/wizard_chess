class_name WizardMatchHudLayout
extends Node

@export var board_safe_area_path: NodePath
@export var board_frame_path: NodePath
@export var board_view_path: NodePath
@export var opponent_hand_panel_path: NodePath
@export var local_hand_panel_path: NodePath
@export var opponent_library_panel_path: NodePath
@export var opponent_graveyard_panel_path: NodePath
@export var player_library_panel_path: NodePath
@export var player_graveyard_panel_path: NodePath
@export var turn_panel_path: NodePath
@export var local_zone_panel_path: NodePath
@export var opponent_zone_panel_path: NodePath
@export var match_sidebar_path: NodePath
@export var inspect_popup_path: NodePath
@export var local_hand_row_path: NodePath
@export var opponent_hand_row_path: NodePath
@export var opponent_hand_top_offset: float = 36.0

@onready var board_safe_area := get_node_or_null(board_safe_area_path) as MarginContainer
@onready var board_frame := get_node_or_null(board_frame_path) as PanelContainer
@onready var board_view := get_node_or_null(board_view_path) as WizardMatchBoardView
@onready var opponent_hand_panel := get_node_or_null(opponent_hand_panel_path) as Control
@onready var local_hand_panel := get_node_or_null(local_hand_panel_path) as Control
@onready var opponent_library_panel := get_node_or_null(opponent_library_panel_path) as PanelContainer
@onready var opponent_graveyard_panel := get_node_or_null(opponent_graveyard_panel_path) as PanelContainer
@onready var player_library_panel := get_node_or_null(player_library_panel_path) as PanelContainer
@onready var player_graveyard_panel := get_node_or_null(player_graveyard_panel_path) as PanelContainer
@onready var turn_panel := get_node_or_null(turn_panel_path) as PanelContainer
@onready var local_zone_panel := get_node_or_null(local_zone_panel_path) as PanelContainer
@onready var opponent_zone_panel := get_node_or_null(opponent_zone_panel_path) as PanelContainer
@onready var match_sidebar := get_node_or_null(match_sidebar_path) as WizardMatchHudSidebar
@onready var inspect_popup := get_node_or_null(inspect_popup_path) as WizardMatchInspectorView
@onready var local_hand_row := get_node_or_null(local_hand_row_path) as HandFanView
@onready var opponent_hand_row := get_node_or_null(opponent_hand_row_path) as HandFanView


func apply_layout(viewport_size: Vector2) -> void:
	if not is_node_ready():
		return
	if board_view == null:
		return
	if opponent_hand_panel == null or local_hand_panel == null:
		return
	if local_hand_row == null or opponent_hand_row == null:
		return

	# Scene-authored HUD geometry owns the major table layout. Runtime only
	# clamps floating surfaces and refreshes card fans after viewport changes.
	opponent_hand_panel.z_index = 80
	local_hand_panel.z_index = 90
	if opponent_library_panel != null:
		opponent_library_panel.z_index = 20
	if opponent_graveyard_panel != null:
		opponent_graveyard_panel.z_index = 20
	if player_graveyard_panel != null:
		player_graveyard_panel.z_index = 20
	if player_library_panel != null:
		player_library_panel.z_index = 20
	if turn_panel != null:
		turn_panel.z_index = 35
	if inspect_popup != null:
		inspect_popup.z_index = 30

	_clamp_sidebar_to_viewport(viewport_size)
	_position_inspector(viewport_size)

	local_hand_row.refresh_layout()
	opponent_hand_row.refresh_layout()


func _clamp_sidebar_to_viewport(viewport_size: Vector2) -> void:
	if match_sidebar == null:
		return
	var sidebar_size := match_sidebar.size
	if sidebar_size.x <= 0.0 or sidebar_size.y <= 0.0:
		sidebar_size = match_sidebar.get_combined_minimum_size()
		match_sidebar.size = sidebar_size
	var margin := 16.0
	match_sidebar.position.x = clampf(
		match_sidebar.position.x,
		margin,
		maxf(margin, viewport_size.x - sidebar_size.x - margin)
	)
	match_sidebar.position.y = clampf(
		match_sidebar.position.y,
		margin,
		maxf(margin, viewport_size.y - sidebar_size.y - margin)
	)


func _position_inspector(viewport_size: Vector2) -> void:
	if inspect_popup == null:
		return
	var board_rect := board_view.get_global_rect()
	var inspector_size := inspect_popup.size
	if inspector_size.x <= 0.0 or inspector_size.y <= 0.0:
		inspector_size = inspect_popup.get_combined_minimum_size()
	var margin := 16.0
	var inspector_x := board_rect.end.x + 16.0
	if inspector_x + inspector_size.x > viewport_size.x - margin:
		inspector_x = maxf(margin, board_rect.position.x - inspector_size.x - 16.0)
	var inspector_y := inspect_popup.position.y
	if inspector_y <= 0.0:
		inspector_y = board_rect.position.y + 18.0
	var inspector_position := Vector2(
		clampf(inspector_x, margin, maxf(margin, viewport_size.x - inspector_size.x - margin)),
		clampf(inspector_y, margin, maxf(margin, viewport_size.y - inspector_size.y - margin))
	)
	if turn_panel != null:
		var turn_rect := turn_panel.get_global_rect()
		var inspector_rect := Rect2(inspector_position, inspector_size)
		if inspector_rect.intersects(turn_rect):
			var above_turn_y := turn_rect.position.y - inspector_size.y - 12.0
			if above_turn_y >= margin:
				inspector_position.y = above_turn_y
			else:
				inspector_position.x = maxf(margin, board_rect.position.x - inspector_size.x - 16.0)
				inspector_position.y = clampf(
					board_rect.position.y + 18.0,
					margin,
					maxf(margin, viewport_size.y - inspector_size.y - margin)
				)
	inspect_popup.position = inspector_position
