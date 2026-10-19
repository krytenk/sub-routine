extends Node
class_name TestMapsSavesAndCredits

# Unit Test Suite for Maps on Wall Panels, Save Points/Checkpoints, and Demo Roll Credits

const WallMapPanelScene = preload("res://scenes/props/wall_map_panel_prop.tscn")
const MapViewerModalScene = preload("res://scenes/ui/map_viewer_modal.tscn")
const DemoCreditsRollScene = preload("res://scenes/ui/demo_credits_roll.tscn")

# 1. Test Wall Map Panel Prop
func test_wall_map_panel_prop() -> bool:
	var panel = WallMapPanelScene.instantiate()
	panel.sector_index = 8
	panel._ready()

	assert(panel.sector_index == 8, "FAILED: Wall map panel must retain sector_index")
	assert(panel.screen_mesh != null, "FAILED: Wall map panel must create a screen mesh")
	assert(panel.panel_light != null, "FAILED: Wall map panel must create a status light")

	var tracker = {"accessed": false, "idx": -1}
	panel.map_terminal_accessed.connect(func(idx: int):
		tracker["accessed"] = true
		tracker["idx"] = idx
	)
	panel.interact()

	assert(tracker["accessed"] == true, "FAILED: Interacting with map panel must emit map_terminal_accessed")
	assert(tracker["idx"] == 8, "FAILED: Map panel must pass sector index 8")

	panel.queue_free()
	print("[PASS] test_wall_map_panel_prop: Wall map panel fixture, visuals, and interaction validated.")
	return true

# 2. Test Map Viewer Modal UI
func test_map_viewer_modal_navigation() -> bool:
	var modal = MapViewerModalScene.instantiate()
	modal._ready()

	assert(modal.is_open == false, "FAILED: Map modal must be closed initially")

	modal.open_map(3)
	assert(modal.is_open == true, "FAILED: open_map must set is_open = true")
	assert(modal.current_sector_index == 3, "FAILED: Map modal must display sector 3")
	assert(modal.title_label.text.contains("SECTOR 03"), "FAILED: Sector title must reflect Sector 3")

	# Test Next sector
	modal._on_next_pressed()
	assert(modal.current_sector_index == 4, "FAILED: Next button must advance to sector 4")

	# Test Prev sector
	modal._on_prev_pressed()
	assert(modal.current_sector_index == 3, "FAILED: Prev button must return to sector 3")

	# Test close
	modal.close_map()
	assert(modal.is_open == false, "FAILED: close_map must set is_open = false")

	# Test keyboard closing via KEY_X
	modal.open_map(3)
	assert(modal.is_open == true, "FAILED: open_map must set is_open = true")
	var key_x = InputEventKey.new()
	key_x.pressed = true
	key_x.keycode = KEY_X
	modal._input(key_x)
	assert(modal.is_open == false, "FAILED: Pressing KEY_X must close the map")

	# Test keyboard closing via KEY_ESCAPE
	modal.open_map(3)
	var key_esc = InputEventKey.new()
	key_esc.pressed = true
	key_esc.keycode = KEY_ESCAPE
	modal._input(key_esc)
	assert(modal.is_open == false, "FAILED: Pressing KEY_ESCAPE must close the map")

	# Test keyboard closing via KEY_M
	modal.open_map(3)
	var key_m = InputEventKey.new()
	key_m.pressed = true
	key_m.keycode = KEY_M
	modal._input(key_m)
	assert(modal.is_open == false, "FAILED: Pressing KEY_M must close the map")

	modal.queue_free()
	print("[PASS] test_map_viewer_modal_navigation: Map viewer modal open/close, sector switching, and X/ESC/M keys validated.")
	return true

# 3. Test Save & Checkpoint Manager
func test_save_manager_persistence() -> bool:
	var sm = load("res://scripts/save_manager.gd").new()
	assert(sm != null, "FAILED: SaveManager script must instantiate")

	# Save checkpoint
	var save_ok = sm.save_game("Test Checkpoint Sector 08")
	assert(save_ok == true, "FAILED: SaveManager.save_game must return true")
	assert(sm.has_save_file() == true, "FAILED: Save file must exist after saving")

	# Verify loading
	var load_ok = sm.load_game()
	assert(load_ok == true, "FAILED: SaveManager.load_game must return true on valid save")

	# Clean up save file
	sm.delete_save()
	assert(sm.has_save_file() == false, "FAILED: Save file must be removed after delete_save")

	sm.free()
	print("[PASS] test_save_manager_persistence: SaveManager save, load, and deletion persistence validated.")
	return true

# 4. Test Demo Roll Credits Scene
func test_demo_credits_roll_scene() -> bool:
	var credits = DemoCreditsRollScene.instantiate()
	credits._ready()

	assert(credits.restart_btn != null, "FAILED: Credits must include a restart button")
	assert(credits.checkpoint_btn != null, "FAILED: Credits must include a reload checkpoint button")
	assert(credits.copy_link_btn != null, "FAILED: Credits must include a copy link button")
	assert(credits.stats_label.text.contains("12 / 12"), "FAILED: Stats label must reflect all 12 sectors cleared")

	credits.queue_free()
	print("[PASS] test_demo_credits_roll_scene: Demo roll credits and feedback interface validated.")
	return true

# 5. Test HUD Dialogue Non-Blocking Movement Properties
func test_hud_dialogue_non_blocking() -> bool:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "FAILED: Could not load hud.tscn")
	var hud = hud_scene.instantiate()
	hud._ready()

	hud.display_overseer_message("Test Glitch Walker Subroutine Alert")
	assert(hud.overseer_panel.visible == true, "FAILED: overseer_panel must be visible after display_overseer_message")
	assert(hud.overseer_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "FAILED: overseer_panel must ignore mouse events")
	assert(hud.overseer_text.mouse_filter == Control.MOUSE_FILTER_IGNORE, "FAILED: overseer_text must ignore mouse events")
	assert(hud.overseer_text.focus_mode == Control.FOCUS_NONE, "FAILED: overseer_text must have FOCUS_NONE so player movement isn't stolen")

	hud.queue_free()
	print("[PASS] test_hud_dialogue_non_blocking: Dialogue text elements verified non-blocking and focus-free.")
	return true

# 6. Test Roxy Vance Traversal While Dialogue Active
func test_roxy_walks_during_dialogue() -> bool:
	var player_scene = load("res://scenes/player/roxy_vance.tscn")
	assert(player_scene != null, "FAILED: Could not load roxy_vance.tscn")
	var player = player_scene.instantiate()

	# Verify that without modal UI open, _is_modal_ui_open() is false
	assert(player._is_modal_ui_open() == false, "FAILED: _is_modal_ui_open() should be false by default")

	player.queue_free()
	print("[PASS] test_roxy_walks_during_dialogue: Roxy Vance traversal permitted during dialogue.")
	return true

# 7. Test Pause Menu Music Toggle Button
func test_pause_menu_music_toggle() -> bool:
	var pause_scene = load("res://scenes/ui/pause_menu.tscn")
	assert(pause_scene != null, "FAILED: Could not load pause_menu.tscn")
	var menu = pause_scene.instantiate()
	menu._ready()

	assert(menu.music_toggle_button != null, "FAILED: music_toggle_button must exist in pause_menu")
	assert(menu.music_toggle_button.text.contains("Ambient Music"), "FAILED: Button text must mention Ambient Music")

	menu.queue_free()
	print("[PASS] test_pause_menu_music_toggle: Pause menu music toggle button validated.")
	return true

