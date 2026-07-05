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
	if board_safe_area == null or board_frame == null or board_view == null:
		return
	if opponent_hand_panel == null or local_hand_panel == null:
		return
	if opponent_library_panel == null or opponent_graveyard_panel == null:
		return
	if player_library_panel == null or player_graveyard_panel == null:
		return
	if turn_panel == null or local_zone_panel == null or opponent_zone_panel == null:
		return
	if match_sidebar == null or inspect_popup == null:
		return
	if local_hand_row == null or opponent_hand_row == null:
		return
	var outer_margin := 18.0
	var top_strip_height := 182.0
	var bottom_dock_height := 238.0
	var utility_drawer_width := clampf(viewport_size.x * 0.22, 280.0, 360.0)
	var resolved_board_edge := board_frame.custom_minimum_size.x
	var board_view_edge := board_view.custom_minimum_size.x
	var board_frame_origin := (viewport_size - Vector2.ONE * resolved_board_edge) * 0.5
	var board_rect := Rect2(board_frame_origin + Vector2(10.0, 10.0), Vector2(board_view_edge, board_view_edge))
	var top_panel_width := minf(220.0, maxf(180.0, board_rect.position.x - outer_margin - 20.0))
	var turn_panel_width := minf(240.0, maxf(196.0, board_rect.position.x - outer_margin - 20.0))

	opponent_hand_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	opponent_hand_panel.position = Vector2(board_rect.position.x - 50.0, opponent_hand_top_offset)
	opponent_hand_panel.size = Vector2(board_rect.size.x + 100.0, top_strip_height)
	opponent_hand_panel.z_index = 80

	local_hand_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	local_hand_panel.position = Vector2(board_rect.position.x - 50.0, viewport_size.y - bottom_dock_height)
	local_hand_panel.size = Vector2(board_rect.size.x + 100.0, bottom_dock_height)
	local_hand_panel.z_index = 90

	opponent_library_panel.z_index = 20
	opponent_graveyard_panel.z_index = 20
	player_graveyard_panel.z_index = 20
	player_library_panel.z_index = 20

	match_sidebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	match_sidebar.position = Vector2(viewport_size.x - outer_margin - utility_drawer_width, outer_margin + 54.0)
	match_sidebar.size = Vector2(utility_drawer_width, viewport_size.y - match_sidebar.position.y - outer_margin)

	turn_panel.custom_minimum_size.x = turn_panel_width
	turn_panel.z_index = 35

	local_zone_panel.visible = false
	local_zone_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	local_zone_panel.position = Vector2(local_hand_panel.position.x - top_panel_width - 18.0, local_hand_panel.position.y + bottom_dock_height - 144.0)
	local_zone_panel.size = Vector2(top_panel_width, 126.0)

	opponent_zone_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	opponent_zone_panel.position = Vector2(opponent_hand_panel.position.x - top_panel_width - 18.0, opponent_hand_panel.position.y + 4.0)
	opponent_zone_panel.size = Vector2(top_panel_width, 124.0)

	inspect_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var inspector_width := 280.0
	var inspector_x := board_rect.end.x + 16.0
	if inspector_x + inspector_width > viewport_size.x - outer_margin:
		inspector_x = maxf(outer_margin, board_rect.position.x - inspector_width - 16.0)
	var inspector_y := board_rect.position.y + 18.0
	var inspector_bottom_limit := minf(local_hand_panel.position.y - 12.0, turn_panel.position.y - 12.0)
	var inspector_height := clampf(inspector_bottom_limit - inspector_y, 360.0, 470.0)
	inspect_popup.position = Vector2(inspector_x, inspector_y)
	inspect_popup.size = Vector2(inspector_width, inspector_height)
	inspect_popup.z_index = 30

	local_hand_row.refresh_layout()
	opponent_hand_row.refresh_layout()
