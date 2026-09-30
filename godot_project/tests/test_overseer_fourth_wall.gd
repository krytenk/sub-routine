extends RefCounted

# GDUnit4 Test Suite: The Overseer Fourth-Wall Breaking Mechanics
# Validates exact developer dialogue interventions for navmesh breach, speedruns, and out-of-bounds.

func test_navmesh_breach_dialogue() -> bool:
    var overseer = load("res://scripts/the_overseer.gd").new()
    var result = {"text": "", "clip": ""}
    
    overseer.dialogue_triggered.connect(func(text, clip):
        result["text"] = text
        result["clip"] = clip
    )
    
    overseer.report_navmesh_boundary_hit()
    
    var expected = "Roxy, the nav-mesh doesn't even extend over there. Turn around and get back to the designated corridor before I delete your save file."
    assert(result["text"] == expected, "FAILED: Navmesh dialogue mismatch! Got: " + result["text"])
    assert(result["clip"] == "overseer_navmesh_warning", "FAILED: Incorrect VO clip triggered: " + result["clip"])
    print("[PASS] test_navmesh_breach_dialogue: Exact fourth-wall script verified.")
    overseer.free()
    return true

func test_speedrun_detection_dialogue() -> bool:
    var overseer = load("res://scripts/the_overseer.gd").new()
    var result = {"text": "", "clip": ""}
    
    overseer.dialogue_triggered.connect(func(text, clip):
        result["text"] = text
        result["clip"] = clip
    )
    
    overseer.report_speedrun_detected()
    
    var expected = "Are you trying to speed-run this? I haven't even finished rendering the next room. Slow down."
    assert(result["text"] == expected, "FAILED: Speedrun dialogue mismatch! Got: " + result["text"])
    assert(result["clip"] == "overseer_speedrun_warning", "FAILED: Incorrect VO clip triggered: " + result["clip"])
    print("[PASS] test_speedrun_detection_dialogue: Exact speedrun intervention verified.")
    overseer.free()
    return true
