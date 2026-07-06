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

var board_safe_area: MarginContainer
var board_frame: Control
var board_view: WizardMatchBoardView
var opponent_hand_panel: Control
var local_hand_panel: Control
var opponent_library_panel: PanelContainer
var opponent_graveyard_panel: PanelContainer
var player_library_panel: PanelContainer
var player_graveyard_panel: PanelContainer
var turn_panel: PanelContainer
var local_zone_panel: PanelContainer
var opponent_zone_panel: PanelContainer
var match_sidebar: WizardMatchHudSidebar
var inspect_popup: WizardMatchInspectorView
var local_hand_row: HandFanView
var opponent_hand_row: HandFanView
var inspect_avoid_panels: Array[Control] = []


func _ready() -> void:
	_resolve_exported_nodes()


func configure_nodes(nodes: Dictionary) -> void:
	board_safe_area = nodes.get("board_safe_area", board_safe_area)
	board_frame = nodes.get("board_frame", board_frame)
	board_view = nodes.get("board_view", board_view)
	opponent_hand_panel = nodes.get("opponent_hand_panel", opponent_hand_panel)
	local_hand_panel = nodes.get("local_hand_panel", local_hand_panel)
	opponent_library_panel = nodes.get("opponent_library_panel", opponent_library_panel)
	opponent_graveyard_panel = nodes.get("opponent_graveyard_panel", opponent_graveyard_panel)
	player_library_panel = nodes.get("player_library_panel", player_library_panel)
	player_graveyard_panel = nodes.get("player_graveyard_panel", player_graveyard_panel)
	turn_panel = nodes.get("turn_panel", turn_panel)
	local_zone_panel = nodes.get("local_zone_panel", local_zone_panel)
	opponent_zone_panel = nodes.get("opponent_zone_panel", opponent_zone_panel)
	match_sidebar = nodes.get("match_sidebar", match_sidebar)
	inspect_popup = nodes.get("inspect_popup", inspect_popup)
	local_hand_row = nodes.get("local_hand_row", local_hand_row)
	opponent_hand_row = nodes.get("opponent_hand_row", opponent_hand_row)
	var next_avoid_panels: Array = nodes.get("inspect_avoid_panels", inspect_avoid_panels)
	inspect_avoid_panels.clear()
	for panel in next_avoid_panels:
		if panel is Control:
			inspect_avoid_panels.append(panel)


func _resolve_exported_nodes() -> void:
	if board_safe_area == null:
		board_safe_area = get_node_or_null(board_safe_area_path) as MarginContainer
	if board_frame == null:
		board_frame = get_node_or_null(board_frame_path) as Control
	if board_view == null:
		board_view = get_node_or_null(board_view_path) as WizardMatchBoardView
	if opponent_hand_panel == null:
		opponent_hand_panel = get_node_or_null(opponent_hand_panel_path) as Control
	if local_hand_panel == null:
		local_hand_panel = get_node_or_null(local_hand_panel_path) as Control
	if opponent_library_panel == null:
		opponent_library_panel = get_node_or_null(opponent_library_panel_path) as PanelContainer
	if opponent_graveyard_panel == null:
		opponent_graveyard_panel = get_node_or_null(opponent_graveyard_panel_path) as PanelContainer
	if player_library_panel == null:
		player_library_panel = get_node_or_null(player_library_panel_path) as PanelContainer
	if player_graveyard_panel == null:
		player_graveyard_panel = get_node_or_null(player_graveyard_panel_path) as PanelContainer
	if turn_panel == null:
		turn_panel = get_node_or_null(turn_panel_path) as PanelContainer
	if local_zone_panel == null:
		local_zone_panel = get_node_or_null(local_zone_panel_path) as PanelContainer
	if opponent_zone_panel == null:
		opponent_zone_panel = get_node_or_null(opponent_zone_panel_path) as PanelContainer
	if match_sidebar == null:
		match_sidebar = get_node_or_null(match_sidebar_path) as WizardMatchHudSidebar
	if inspect_popup == null:
		inspect_popup = get_node_or_null(inspect_popup_path) as WizardMatchInspectorView
	if local_hand_row == null:
		local_hand_row = get_node_or_null(local_hand_row_path) as HandFanView
	if opponent_hand_row == null:
		opponent_hand_row = get_node_or_null(opponent_hand_row_path) as HandFanView


func apply_layout(viewport_size: Vector2) -> void:
	if not is_node_ready():
		return
	_resolve_exported_nodes()
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

	_finalize_layout(viewport_size)


func _finalize_layout(viewport_size: Vector2) -> void:
	if not is_instance_valid(self):
		return
	_layout_hand_panels(viewport_size)
	if inspect_popup != null:
		inspect_popup.custom_minimum_size = Vector2(320, 420)
		inspect_popup.size = Vector2(320, 420)
		_position_inspector(viewport_size)

	local_hand_row.refresh_layout()
	opponent_hand_row.refresh_layout()


func _layout_hand_panels(viewport_size: Vector2) -> void:
	if board_view == null:
		return
	var board_rect := board_view.get_global_rect()
	_layout_opponent_hand_panel(viewport_size, board_rect)
	_layout_local_hand_panel(viewport_size, board_rect)


func _layout_opponent_hand_panel(viewport_size: Vector2, board_rect: Rect2) -> void:
	if opponent_hand_panel == null:
		return
	var width := clampf(viewport_size.x * 0.42, 520.0, 820.0)
	var max_height := maxf(96.0, board_rect.position.y - 10.0)
	var height := clampf(max_height, 96.0, 126.0)
	opponent_hand_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	opponent_hand_panel.position = Vector2((viewport_size.x - width) * 0.5, maxf(0.0, board_rect.position.y - height - 10.0))
	opponent_hand_panel.size = Vector2(width, height)
	var tray := opponent_hand_panel.get_node_or_null("HandTrayTexture") as Control
	if tray != null:
		tray.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var status_view := opponent_hand_panel.get_node_or_null("OpponentStatusView") as Control
	if status_view != null:
		var status_size := Vector2(118.0, minf(118.0, height - 8.0))
		status_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		status_view.position = Vector2(width - status_size.x - 8.0, 4.0)
		status_view.size = status_size
	if opponent_hand_row != null:
		opponent_hand_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		opponent_hand_row.offset_top = 0.0
		opponent_hand_row.offset_bottom = 0.0
		opponent_hand_row.opponent_top_margin = -72.0


func _layout_local_hand_panel(viewport_size: Vector2, board_rect: Rect2) -> void:
	if local_hand_panel == null:
		return
	var width := clampf(viewport_size.x * 0.46, 560.0, 920.0)
	var available_height := maxf(96.0, viewport_size.y - board_rect.end.y - 10.0)
	var height := clampf(available_height, 96.0, 120.0)
	local_hand_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	local_hand_panel.position = Vector2((viewport_size.x - width) * 0.5, viewport_size.y - height)
	local_hand_panel.size = Vector2(width, height)
	var tray := local_hand_panel.get_node_or_null("HandTrayTexture") as Control
	if tray != null:
		tray.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tray.offset_top = 0.0
	var status_view := local_hand_panel.get_node_or_null("LocalStatusView") as Control
	if status_view != null:
		var status_size := Vector2(118.0, minf(118.0, height - 8.0))
		status_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		status_view.position = Vector2(8.0, 4.0)
		status_view.size = status_size
		status_view.z_index = 20
	if local_hand_row != null:
		local_hand_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		local_hand_row.offset_top = 42.0
		local_hand_row.offset_right = 0.0
		local_hand_row.offset_bottom = 0.0
		local_hand_row.local_bottom_margin = 0.0
		local_hand_row.local_curve_height_per_card = 0.0
		local_hand_row.local_rotation_scale = 0.85
		local_hand_row.targeted_preview_y = 0.0


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
	var candidate_positions := [
		Vector2(board_rect.end.x + 16.0, board_rect.position.y + 18.0),
		Vector2(board_rect.position.x - inspector_size.x - 16.0, board_rect.position.y + 18.0),
	]
	for candidate in candidate_positions:
		var clamped_candidate := Vector2(
			clampf(candidate.x, margin, maxf(margin, viewport_size.x - inspector_size.x - margin)),
			clampf(candidate.y, margin, maxf(margin, viewport_size.y - inspector_size.y - margin))
		)
		var candidate_rect := Rect2(clamped_candidate, inspector_size)
		if not _inspector_intersects_avoid_panels(candidate_rect):
			inspect_popup.position = clamped_candidate
			return

	var fallback_position := Vector2(
		clampf(board_rect.end.x - inspector_size.x - 12.0, margin, maxf(margin, viewport_size.x - inspector_size.x - margin)),
		clampf(board_rect.position.y + 18.0, margin, maxf(margin, viewport_size.y - inspector_size.y - margin))
	)
	inspect_popup.position = fallback_position


func _inspector_intersects_avoid_panels(inspector_rect: Rect2) -> bool:
	for panel in inspect_avoid_panels:
		if panel == null or not is_instance_valid(panel) or not panel.visible:
			continue
		if inspector_rect.intersects(panel.get_global_rect()):
			return true
	return false
