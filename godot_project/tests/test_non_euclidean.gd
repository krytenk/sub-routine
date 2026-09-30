extends RefCounted

# GDUnit4 Test Suite: Non-Euclidean Geometry & Looping Corridor
# Validates infinite looping threshold and unlocking upon puzzle completion.

const NonEuclideanCorridor = preload("res://scripts/non_euclidean_corridor.gd")
const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

func test_corridor_looping() -> bool:
    var corridor = NonEuclideanCorridor.new()
    var entry_marker = Marker3D.new()
    entry_marker.position = Vector3(0, 0, -20)
    entry_marker.global_position = Vector3(0, 0, -20)
    corridor.entry_anchor = entry_marker
    corridor.is_unlocked = false
    
    var roxy = RoxyVance.new()
    roxy.position = Vector3(0, 0, 15)
    roxy.global_position = Vector3(0, 0, 15)
    
    # Simulate entering locked corridor
    corridor._on_body_entered(roxy)
    
    var loop_ok = (corridor.loop_counter == 1)
    var warp_ok = is_equal_approx(roxy.global_position.z, -20.0) or is_equal_approx(roxy.position.z, -20.0)
    
    # Always free nodes to guarantee zero RID leaks
    corridor.free()
    entry_marker.free()
    roxy.free()
    
    assert(loop_ok, "FAILED: Loop counter should increment to 1")
    assert(warp_ok, "FAILED: Player was not teleported to entry anchor!")
    print("[PASS] test_corridor_looping: Non-Euclidean spatial warp loop verified.")
    return true

func test_corridor_unlock() -> bool:
    var corridor = NonEuclideanCorridor.new()
    corridor.is_unlocked = false
    
    corridor._on_puzzle_solved()
    assert(corridor.is_unlocked == true, "FAILED: Corridor failed to unlock on puzzle solved signal.")
    print("[PASS] test_corridor_unlock: Corridor unlocks successfully after solving register puzzle.")
    corridor.free()
    return true
