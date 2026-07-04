extends GutTest

const DEFAULT_GAME_CONFIG_PATH := "res://content/config/default_game_config.tres"

func test_default_game_config_loads() -> void:
	var config := load(DEFAULT_GAME_CONFIG_PATH) as GameConfig

	assert_not_null(config)
	assert_eq(config.project_name, "Wizard Chess")
	assert_eq(config.build_label, "Milestone 2 core chess")
	assert_true(config.auto_quit_on_headless)
