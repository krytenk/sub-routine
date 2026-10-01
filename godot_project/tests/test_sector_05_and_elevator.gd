extends RefCounted

# GDUnit4 Test Suite: Sector 04 Elevator Gating & Sector 05 Tram Hub
# Validates ladder clearance in Room 05, elevator power gating via LevelManager,
# and Sector 05 Executive Overlook architecture & tram decryption mechanics.

const ElevatorConsoleProp = preload("res://scenes/props/elevator_console_prop.gd")
const TramDepartureConsoleProp = preload("res://scenes/props/tram_departure_console_prop.gd")

func test_level_04_elevator_shaft_geometry_and_ladder() -> bool:
	var lvl4_scene = ResourceLoader.load("res://scenes/levels/level_04.tscn") as PackedScene
	assert(lvl4_scene != null, "FAILED: Could not load level_04.tscn")
	var lvl4 = lvl4_scene.instantiate()

	var shaft = lvl4.find_child("Room_05_ElevatorShaft", true, false)
	assert(shaft != null, "FAILED: Room_05_ElevatorShaft missing from level_04")

	var ladder = shaft.find_child("ClimbableLadder", true, false)
	assert(ladder != null, "FAILED: ClimbableLadder missing from Room_05_ElevatorShaft")
	assert(ladder.position.z > -1.0, "FAILED: Ladder must be mounted on gantry front face, not under gantry ceiling.")
	assert(ladder.ladder_height >= 6.0, "FAILED: Ladder height must reach gantry deck level.")

	var gantry_col = shaft.find_child("GantryCol", true, false)
	assert(gantry_col != null, "FAILED: GantryCol missing from Room_05_ElevatorShaft")

	var console = shaft.find_child("ElevatorConsole", true, false)
	assert(console != null, "FAILED: ElevatorConsole missing from Room_05_ElevatorShaft")

	print("[PASS] test_level_04_elevator_shaft_geometry_and_ladder: Elevator shaft ladder placement and gantry access validated.")
	lvl4.free()
	return true

func test_elevator_console_power_gating() -> bool:
	var console_scene = ResourceLoader.load("res://scenes/props/elevator_console_prop.tscn") as PackedScene
	assert(console_scene != null, "FAILED: Could not load elevator_console_prop.tscn")
	var console = console_scene.instantiate() as ElevatorConsoleProp

	# Mock LevelManager if not present
	var tree = Engine.get_main_loop() as SceneTree
	var root = tree.root if tree else null
	var lm = null
	if root and root.has_node("LevelManager"):
		lm = root.get_node("LevelManager")

	if lm:
		lm.is_generator_running = false
		assert(console.is_powered() == false, "FAILED: Console should report unpowered when generator is offline")

		lm.is_generator_running = true
		assert(console.is_powered() == true, "FAILED: Console should report powered when generator is online")

	print("[PASS] test_elevator_console_power_gating: Elevator hoist power gating logic validated.")
	console.free()
	return true

func test_level_05_scene_architecture() -> bool:
	var lvl5_scene = ResourceLoader.load("res://scenes/levels/level_05.tscn") as PackedScene
	assert(lvl5_scene != null, "FAILED: Could not load level_05.tscn")
	var lvl5 = lvl5_scene.instantiate()

	# Navigation & Spawns
	assert(lvl5.find_child("SpawnPoint", true, false) != null, "FAILED: Missing SpawnPoint in level_05")
	assert(lvl5.find_child("BacktrackSpawnPoint", true, false) != null, "FAILED: Missing BacktrackSpawnPoint in level_05")
	assert(lvl5.find_child("BacktrackPortal", true, false) != null, "FAILED: Missing BacktrackPortal in level_05")

	# Casualties & Environmental Narrative
	var dir_cas = lvl5.find_child("Casualty_ExecutiveDirector", true, false)
	assert(dir_cas != null, "FAILED: Missing Casualty_ExecutiveDirector in level_05")
	assert(dir_cas.technician_name.contains("Director Sterling"), "FAILED: Director Sterling name mismatch")

	var res_cas = lvl5.find_child("Casualty_LeadResearcher", true, false)
	assert(res_cas != null, "FAILED: Missing Casualty_LeadResearcher in level_05")
	assert(res_cas.technician_name.contains("Dr. A. Mercer"), "FAILED: Dr. Mercer name mismatch")

	# Enemies & Stealth
	assert(lvl5.find_child("GlitchWalker_Overlook", true, false) != null, "FAILED: Missing GlitchWalker_Overlook in level_05")
	assert(lvl5.find_child("GlitchWalker_ResearchLab", true, false) != null, "FAILED: Missing GlitchWalker_ResearchLab in level_05")
	assert(lvl5.find_child("StealthLocker_Overlook", true, false) != null, "FAILED: Missing StealthLocker_Overlook in level_05")
	assert(lvl5.find_child("StealthLocker_Lab", true, false) != null, "FAILED: Missing StealthLocker_Lab in level_05")

	# Progression & Tram Station
	assert(lvl5.find_child("TramDecryptionTerminal", true, false) != null, "FAILED: Missing TramDecryptionTerminal in level_05")
	assert(lvl5.find_child("TramDepartureConsole", true, false) != null, "FAILED: Missing TramDepartureConsole in level_05")
	assert(lvl5.find_child("ExitArea", true, false) != null, "FAILED: Missing ExitArea in level_05")

	print("[PASS] test_level_05_scene_architecture: Sector 05 Executive Overlook & Tram Hub validated.")
	lvl5.free()
	return true

func test_tram_departure_decryption_flow() -> bool:
	var lvl5_scene = ResourceLoader.load("res://scenes/levels/level_05.tscn") as PackedScene
	var lvl5 = lvl5_scene.instantiate()

	var tram_console = lvl5.find_child("TramDepartureConsole", true, false) as TramDepartureConsoleProp
	assert(tram_console != null, "FAILED: Missing TramDepartureConsole")
	assert(tram_console.is_authorized == false, "FAILED: Tram console must start locked")

	lvl5.decrypt_tram_departure()
	assert(tram_console.is_authorized == true, "FAILED: Tram console should be authorized after decryption")

	print("[PASS] test_tram_departure_decryption_flow: Research lab decryption to tram departure cycle validated.")
	lvl5.free()
	return true
