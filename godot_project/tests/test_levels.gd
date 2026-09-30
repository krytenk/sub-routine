extends RefCounted

# GDUnit4 Test Suite: Level Roadmap & Playable Content
# Validates 120 level roadmap metadata, and all 40 playable level scenes.

func test_roadmap_scope() -> bool:
    var lm = load("res://scripts/level_manager.gd").new()
    assert(lm.TOTAL_ROADMAP_LEVELS == 120, "FAILED: Total roadmap scope must be 120 levels.")
    assert(lm.LAUNCH_DAY_LEVELS == 20, "FAILED: Launch Day scope must be 20 levels.")
    assert(lm.EXPANSION_PACK_1_LEVELS == 40, "FAILED: Expansion Pack 1 scope must be 40 levels.")
    assert(lm.level_roadmap_metadata.size() == 120, "FAILED: Metadata count must match 120 levels.")
    print("[PASS] test_roadmap_scope: 120-level roadmap validated.")
    lm.free()
    return true

func test_playable_levels_exist() -> bool:
    for i in range(1, 41):
        var path = "res://scenes/levels/level_%02d.tscn" % i
        var exists = ResourceLoader.exists(path) or FileAccess.file_exists(path)
        assert(exists, "FAILED: Missing level scene: " + path)
    print("[PASS] test_playable_levels_exist: All 40 playable level scenes verified on disk.")
    return true

func test_level_01_exit_architecture() -> bool:
    var scene = load("res://scenes/levels/level_01.tscn")
    assert(scene != null, "FAILED: Could not load level_01.tscn")
    var level = scene.instantiate()
    assert(level != null, "FAILED: Could not instantiate level_01.tscn")

    var blast_door = level.find_child("BlastDoor", true, false)
    assert(blast_door != null, "FAILED: BlastDoor prop missing from level_01")
    assert(is_equal_approx(blast_door.position.z, 16.0), "FAILED: BlastDoor should be positioned in doorway at Z = 16.0")

    var exit_area = level.find_child("ExitArea", true, false)
    assert(exit_area != null, "FAILED: ExitArea missing from level_01")

    var transit_floor = level.find_child("Transit_Floor_Col", true, false)
    assert(transit_floor != null, "FAILED: Transit corridor floor missing from level_01")

    var door_frame = blast_door.find_child("DoorFrame", true, false)
    var leaf_l = blast_door.find_child("DoorLeaf_L", true, false)
    var leaf_r = blast_door.find_child("DoorLeaf_R", true, false)
    assert(door_frame != null, "FAILED: BlastDoor missing permanent DoorFrame")
    assert(leaf_l != null, "FAILED: BlastDoor missing sliding DoorLeaf_L")
    assert(leaf_r != null, "FAILED: BlastDoor missing sliding DoorLeaf_R")

    print("[PASS] test_level_01_exit_architecture: Exit doorway, transit tunnel, and articulated blast gate validated.")
    level.free()
    return true

func test_level_02_trench_architecture() -> bool:
    var scene = load("res://scenes/levels/level_02.tscn")
    assert(scene != null, "FAILED: Could not load level_02.tscn")
    var level = scene.instantiate()
    assert(level != null, "FAILED: Could not instantiate level_02.tscn")

    var spawn = level.find_child("SpawnPoint", true, false)
    assert(spawn != null, "FAILED: SpawnPoint missing from level_02")
    assert(is_equal_approx(spawn.position.y, 2.7), "FAILED: SpawnPoint should be on elevated catwalk at Y = 2.7")

    var catwalk = level.find_child("CatwalkDeckCol", true, false)
    assert(catwalk != null, "FAILED: CatwalkDeckCol missing from level_02")

    var ramp = level.find_child("RampCol", true, false)
    assert(ramp != null, "FAILED: RampCol missing from level_02")

    var puzzle = level.find_child("PrimaryPuzzle", true, false)
    assert(puzzle != null, "FAILED: PrimaryPuzzle missing from level_02")
    assert(puzzle is CircuitBreakerPuzzle, "FAILED: PrimaryPuzzle must be CircuitBreakerPuzzle")
    assert(puzzle.puzzle_id == "SECTOR_02_BREAKER", "FAILED: Puzzle ID should be SECTOR_02_BREAKER")

    var blast_door = level.find_child("BlastDoor", true, false)
    assert(blast_door != null, "FAILED: BlastDoor missing from level_02")
    assert(is_equal_approx(blast_door.position.z, 19.0), "FAILED: BlastDoor should be at Z = 19.0")

    var exit_area = level.find_child("ExitArea", true, false)
    assert(exit_area != null, "FAILED: ExitArea missing from level_02")

    var walker = level.find_child("GlitchWalker", true, false)
    assert(walker != null, "FAILED: GlitchWalker missing from level_02")

    var core = level.find_child("MemoryCorePickup", true, false)
    assert(core != null, "FAILED: MemoryCorePickup missing from level_02")
    assert(core.core_id == "CORE_BETA_02", "FAILED: MemoryCorePickup should be CORE_BETA_02")

    var broken_rack = level.find_child("BrokenServerRack_1", true, false)
    var fuse_box = level.find_child("SparkingFuseBox", true, false)
    var inverter = level.find_child("PowerInverter_1", true, false)
    assert(broken_rack != null, "FAILED: BrokenServerRack_1 missing from level_02")
    assert(fuse_box != null, "FAILED: SparkingFuseBox missing from level_02")
    assert(inverter != null, "FAILED: PowerInverter_1 missing from level_02")

    print("[PASS] test_level_02_trench_architecture: Catwalk gantry, access ramp, breaker grid, horror electronics, and Sector 03 transit validated.")
    level.free()
    return true

func test_inter_sector_progression() -> bool:
    var lm = load("res://scripts/level_manager.gd").new()
    var success_l1 = lm.load_level(1)
    assert(success_l1 == true, "FAILED: Failed to load Level 1")
    assert(lm.current_level_index == 1, "FAILED: Expected current_level_index == 1")

    lm.complete_current_level()
    assert(lm.current_level_index == 2, "FAILED: Expected progression to Level 2")
    assert(lm.completed_levels.has(1), "FAILED: Level 1 should be recorded in completed_levels")
    assert(lm.active_level_instance != null, "FAILED: Expected active Level 2 instance")
    assert(lm.active_level_instance.name == "Level_02", "FAILED: Active level should be Level_02")

    var spawn = lm.active_level_instance.find_child("SpawnPoint", true, false)
    assert(spawn != null, "FAILED: Level 2 must have SpawnPoint for player placement")

    print("[PASS] test_inter_sector_progression: Seamless Sector 01 -> Sector 02 progression validated.")
    if lm.active_level_instance:
        lm.active_level_instance.free()
    lm.free()
    return true


