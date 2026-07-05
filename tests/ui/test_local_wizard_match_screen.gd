extends GutTest

const LOCAL_WIZARD_MATCH_SCREEN_PATH := "res://scenes/chess/local_wizard_match_screen.tscn"


func test_local_wizard_match_screen_builds_playable_match_ui() -> void:
	var packed_scene := load(LOCAL_WIZARD_MATCH_SCREEN_PATH) as PackedScene

	assert_not_null(packed_scene)

	var screen := packed_scene.instantiate()
	add_child_autofree(screen)

	assert_not_null(screen.wizard_match)
	assert_eq(screen.board_buttons.size(), 64)
	assert_not_null(screen.board_view)
	assert_not_null(screen.play_drop_zone)
	assert_true(screen.status_label.text.begins_with("Turn "))
	assert_false(screen.notification_toast.visible)
	assert_false(screen.inspect_popup.visible)
	assert_gt(screen.local_hand_row.get_child_count(), 0)
	assert_eq(screen.local_hand_title_label.text, "White Hand")
	assert_false(screen.white_ai_button.button_pressed)
	assert_true(screen.black_ai_button.button_pressed)
