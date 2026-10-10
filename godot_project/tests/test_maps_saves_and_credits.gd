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

	modal.queue_free()
	print("[PASS] test_map_viewer_modal_navigation: Map viewer modal open/close and sector switching validated.")
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
	assert(credits.stats_label.text.contains("09 / 09"), "FAILED: Stats label must reflect all 9 sectors cleared")

	credits.queue_free()
	print("[PASS] test_demo_credits_roll_scene: Demo roll credits and feedback interface validated.")
	return true
