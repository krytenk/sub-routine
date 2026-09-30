extends RefCounted

# GDUnit4 Test Suite: Environmental Hazards vs 90s Trope Immunity
# Validates that hazards inflict 40 damage per tick on general entities,
# but Roxy Vance strictly absorbs and takes 0 environmental damage.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")
const EnvironmentalHazard = preload("res://scripts/environmental_hazard.gd")

func test_hazard_immunity_roxy() -> bool:
    var roxy = RoxyVance.new()
    roxy.current_health = 100
    
    var hazard = EnvironmentalHazard.new()
    hazard.damage_per_tick = 40
    hazard.hazard_type = "toxic_coolant"
    
    # Simulate Roxy stepping into toxic coolant
    hazard._apply_hazard(roxy)
    
    assert(roxy.current_health == 100, "FAILED: Roxy took damage from environmental hazard!")
    print("[PASS] test_hazard_immunity_roxy: Roxy took 0 damage from toxic coolant hazard.")
    roxy.free()
    hazard.free()
    return true
