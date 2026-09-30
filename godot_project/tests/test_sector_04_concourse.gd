extends RefCounted

# GDUnit4 Test Suite: Sector 04 The Decision Concourse & Advanced Horror Mechanics
# Tests Fall Damage, Respawning Medkits, Backtracking, WireHound, Stealth Lockers, and 5 Choice Rooms.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")
const NaniteMedkitProp = preload("res://scenes/props/nanite_medkit_prop.gd")
const WireHound = preload("res://scenes/enemies/wire_hound.gd")
const StealthLockerProp = preload("res://scenes/props/stealth_locker_prop.gd")
const ClimbableLadderProp = preload("res://scenes/props/climbable_ladder_prop.gd")

func test_roxy_fall_damage() -> bool:
	var roxy = RoxyVance.new()
	roxy.current_health = 100

	# Environmental damage should still be ignored
	roxy.take_damage(40, "environmental")
	assert(roxy.current_health == 100, "FAILED: Roxy took environmental damage! GDD rule violated.")

	# Fall damage MUST inflict damage
	roxy.take_damage(28, "fall")
	assert(roxy.current_health == 72, "FAILED: Roxy did not take fall damage! HP should be 72.")

	# Fatal fall damage
	roxy.take_damage(72, "fall")
	assert(roxy.current_health == 0, "FAILED: Fatal fall did not reduce HP to 0.")
	print("[PASS] test_roxy_fall_damage: Roxy fall damage rules validated.")
	roxy.free()
	return true

func test_nanite_medkit_respawn() -> bool:
	var medkit_scene = ResourceLoader.load("res://scenes/props/nanite_medkit_prop.tscn") as PackedScene
	assert(medkit_scene != null, "FAILED: Could not load nanite_medkit_prop.tscn")
	var medkit = medkit_scene.instantiate() as NaniteMedkitProp
	assert(medkit.can_respawn == true, "FAILED: Medkit should have can_respawn enabled by default.")

	var roxy = RoxyVance.new()
	roxy.current_health = 40

	# Simulate collection
	medkit._on_body_entered(roxy)
	assert(roxy.current_health == 90, "FAILED: Roxy should heal 50 HP upon collecting medkit.")
	assert(medkit.is_collected == true, "FAILED: Medkit should be marked collected.")

	# Simulate respawn timer tick
	medkit._respawn_medkit()
	assert(medkit.is_collected == false, "FAILED: Medkit should be uncollected after respawn.")
	assert(medkit.monitoring == true, "FAILED: Medkit monitoring should re-enable upon respawn.")
	print("[PASS] test_nanite_medkit_respawn: Nanite medkit respawn cycle validated.")

	roxy.free()
	medkit.free()
	return true

func test_wire_hound_mechanics() -> bool:
	var hound_scene = ResourceLoader.load("res://scenes/enemies/wire_hound.tscn") as PackedScene
	assert(hound_scene != null, "FAILED: Could not load wire_hound.tscn")
	var hound = hound_scene.instantiate() as WireHound

	# Verify quadruped limb nodes
	assert(hound.find_child("Leg_FL", true, false) != null, "FAILED: WireHound missing Leg_FL")
	assert(hound.find_child("Leg_FR", true, false) != null, "FAILED: WireHound missing Leg_FR")
	assert(hound.find_child("Leg_BL", true, false) != null, "FAILED: WireHound missing Leg_BL")
	assert(hound.find_child("Leg_BR", true, false) != null, "FAILED: WireHound missing Leg_BR")
	assert(hound.find_child("Head", true, false) != null, "FAILED: WireHound missing Head")
	assert(hound.find_child("Spine", true, false) != null, "FAILED: WireHound missing Spine")

	# Verify speed & combat stats
	assert(hound.base_speed >= 6.5, "FAILED: WireHound speed should be >= 6.5 m/s")
	hound.stagger(5.0)
	assert(hound.is_stunned == true, "FAILED: WireHound should be stunned after EMP stagger.")
	assert(hound.stun_timer == 5.0, "FAILED: WireHound stun timer should match duration.")

	print("[PASS] test_wire_hound_mechanics: WireHound quadruped anatomy and AI states validated.")
	hound.free()
	return true

func test_stealth_locker_concealment() -> bool:
	var locker_scene = ResourceLoader.load("res://scenes/props/stealth_locker_prop.tscn") as PackedScene
	assert(locker_scene != null, "FAILED: Could not load stealth_locker_prop.tscn")
	var locker = locker_scene.instantiate() as StealthLockerProp

	var roxy = RoxyVance.new()
	assert(roxy.is_hiding == false, "FAILED: Roxy should not be hiding initially.")

	# Enter locker
	locker.interact(roxy)
	assert(roxy.is_hiding == true, "FAILED: Roxy should be hiding after interacting with locker.")
	assert(locker.is_occupied == true, "FAILED: Locker should be marked occupied.")

	# Exit locker
	locker.interact(roxy)
	assert(roxy.is_hiding == false, "FAILED: Roxy should exit hiding after second interaction.")
	assert(locker.is_occupied == false, "FAILED: Locker should be unoccupied.")

	print("[PASS] test_stealth_locker_concealment: Stealth locker concealment cycle validated.")
	roxy.free()
	locker.free()
	return true

func test_climbable_ladder() -> bool:
	var ladder_scene = ResourceLoader.load("res://scenes/props/climbable_ladder_prop.tscn") as PackedScene
	assert(ladder_scene != null, "FAILED: Could not load climbable_ladder_prop.tscn")
	var ladder = ladder_scene.instantiate() as ClimbableLadderProp

	var roxy = RoxyVance.new()
	assert(roxy.is_on_ladder == false, "FAILED: Roxy should not be on ladder initially.")

	# Mount ladder
	ladder._on_body_entered(roxy)
	assert(roxy.is_on_ladder == true, "FAILED: Roxy should be marked on ladder upon entry.")

	# Dismount ladder
	ladder._on_body_exited(roxy)
	assert(roxy.is_on_ladder == false, "FAILED: Roxy should dismount ladder upon exit.")

	print("[PASS] test_climbable_ladder: Climbable vertical ladder mount/dismount validated.")
	roxy.free()
	ladder.free()
	return true

func test_level_04_architecture_and_5_choice_rooms() -> bool:
	var lvl4_scene = ResourceLoader.load("res://scenes/levels/level_04.tscn") as PackedScene
	assert(lvl4_scene != null, "FAILED: Could not load level_04.tscn")
	var lvl4 = lvl4_scene.instantiate()

	# 1. Navigation & Spawns
	assert(lvl4.find_child("SpawnPoint", true, false) != null, "FAILED: Level 04 missing SpawnPoint")
	assert(lvl4.find_child("BacktrackSpawnPoint", true, false) != null, "FAILED: Level 04 missing BacktrackSpawnPoint")
	assert(lvl4.find_child("BacktrackPortal", true, false) != null, "FAILED: Level 04 missing BacktrackPortal")

	# 2. Corridor Glitch Walkers
	assert(lvl4.find_child("GlitchWalker_Corridor_1", true, false) != null, "FAILED: Level 04 missing GlitchWalker 1")
	assert(lvl4.find_child("GlitchWalker_Corridor_2", true, false) != null, "FAILED: Level 04 missing GlitchWalker 2")

	# 3. Red Herring Exploration Rooms
	assert(lvl4.find_child("Room_A_Archives", true, false) != null, "FAILED: Missing Red Herring Room A (Archives)")
	assert(lvl4.find_child("Room_B_Ventilation", true, false) != null, "FAILED: Missing Red Herring Room B (Ventilation)")

	# 4. Five Critical Choice Rooms
	assert(lvl4.find_child("Room_01_DeadEnds", true, false) != null, "FAILED: Missing Room 1 (Dead Ends Trap)")
	assert(lvl4.find_child("Room_02_ArtShowcase", true, false) != null, "FAILED: Missing Room 2 (Art Showcase)")
	assert(lvl4.find_child("Room_03_Kennel", true, false) != null, "FAILED: Missing Room 3 (WireHound Kennel)")
	assert(lvl4.find_child("Room_04_Sanctuary", true, false) != null, "FAILED: Missing Room 4 (Recovery Sanctuary)")
	assert(lvl4.find_child("Room_05_ElevatorShaft", true, false) != null, "FAILED: Missing Room 5 (Elevator Shaft)")

	# 5. WireHound and Stealth Locker instances in Level 04
	assert(lvl4.find_child("WireHound_Kennel", true, false) != null, "FAILED: Missing WireHound in Kennel")
	assert(lvl4.find_child("StealthLocker_1", true, false) != null, "FAILED: Missing Stealth Locker 1 in Sanctuary")
	assert(lvl4.find_child("ClimbableLadder", true, false) != null, "FAILED: Missing Climbable Ladder in Elevator Shaft")

	print("[PASS] test_level_04_architecture_and_5_choice_rooms: Level 04 Concourse & 5 choice rooms validated.")
	lvl4.free()
	return true
