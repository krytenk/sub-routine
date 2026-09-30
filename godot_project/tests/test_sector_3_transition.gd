extends RefCounted

# Test verification that Sector 3 does NOT bounce/backtrack player upon loading
const LevelManagerClass = preload("res://scripts/level_manager.gd")
const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

func test_sector_3_entry_does_not_backtrack() -> bool:
	var lm = LevelManagerClass.new()
	var roxy = RoxyVance.new()
	
	# Load Sector 3
	var load_success = lm.load_level(3)
	assert(load_success == true, "FAILED: Could not load level 3")
	assert(lm.current_level_index == 3, "FAILED: Current level should be 3")
	
	var lvl3 = lm.active_level_instance
	assert(lvl3 != null, "FAILED: active_level_instance is null")
	
	var spawn = lvl3.find_child("SpawnPoint", true, false) as Marker3D
	assert(spawn != null, "FAILED: Sector 3 missing SpawnPoint")
	
	var backtrack = lvl3.find_child("BacktrackPortal", true, false) as Area3D
	assert(backtrack != null, "FAILED: Sector 3 missing BacktrackPortal")
	
	# Verify spawn position is safely separated from backtrack portal (use position for nodes outside tree)
	var dist = spawn.position.distance_to(backtrack.position)
	print("[test_sector_3_transition] Spawn at: ", spawn.position, " Backtrack at: ", backtrack.position, " Distance: ", dist)
	assert(dist >= 3.5, "FAILED: SpawnPoint is too close to BacktrackPortal! Dist: " + str(dist))
	
	# Verify backtrack trigger grace period is enabled
	assert("grace_period" in backtrack and backtrack.grace_period > 0.0, "FAILED: BacktrackPortal missing grace_period")
	
	print("[PASS] test_sector_3_entry_does_not_backtrack: Sector 3 entry spawn is safe and does not trigger false backtrack.")
	
	# Test Sector 4 entry
	var load_s4 = lm.load_level(4)
	assert(load_s4 == true, "FAILED: Could not load level 4")
	var lvl4 = lm.active_level_instance
	var spawn4 = lvl4.find_child("SpawnPoint", true, false) as Marker3D
	var backtrack4 = lvl4.find_child("BacktrackPortal", true, false) as Area3D
	var dist4 = spawn4.position.distance_to(backtrack4.position)
	print("[test_sector_3_transition] Sector 4 Spawn at: ", spawn4.position, " Backtrack at: ", backtrack4.position, " Distance: ", dist4)
	assert(dist4 >= 7.0, "FAILED: Sector 4 SpawnPoint too close to BacktrackPortal! Dist: " + str(dist4))
	
	print("[PASS] test_sector_4_entry_safe: Sector 4 entry spawn is safely separated from backtrack portal.")
	
	roxy.free()
	lm.free()
	return true
