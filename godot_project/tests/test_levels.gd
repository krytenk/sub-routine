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

