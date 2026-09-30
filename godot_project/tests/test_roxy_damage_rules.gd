extends RefCounted

# GDUnit4 Test Suite: Roxy Vance Damage Rules
# Roxy Vance takes ZERO environmental damage, damage only from direct enemy attacks.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

func test_environmental_damage_immunity() -> bool:
    var roxy = RoxyVance.new()
    roxy.current_health = 100
    
    # Environmental hazard test
    roxy.take_damage(50, "environmental")
    assert(roxy.current_health == 100, "FAILED: Roxy took environmental damage! GDD mandates 0 environmental damage.")
    
    roxy.take_damage(999, "environmental")
    assert(roxy.current_health == 100, "FAILED: Fatal environmental hazard damaged Roxy!")
    print("[PASS] test_environmental_damage_immunity: Roxy took 0 damage from environmental hazards.")
    roxy.free()
    return true

func test_enemy_damage_vulnerability() -> bool:
    var roxy = RoxyVance.new()
    roxy.current_health = 100
    
    # Direct enemy attack test
    roxy.take_damage(25, "enemy")
    assert(roxy.current_health == 75, "FAILED: Roxy failed to take direct enemy damage.")
    
    roxy.take_damage(75, "enemy")
    assert(roxy.current_health == 0, "FAILED: Health did not reduce to 0 upon fatal enemy attack.")
    print("[PASS] test_enemy_damage_vulnerability: Roxy properly took direct enemy attack damage.")
    roxy.free()
    return true

func test_emp_pulse_mechanics() -> bool:
    var roxy = RoxyVance.new()
    assert(roxy.emp_cooldown == 8.0, "FAILED: EMP cooldown default should be 8.0s")
    assert(roxy.emp_current_timer == 0.0, "FAILED: Initial EMP timer should be 0.0s")

    # Fire pulse
    roxy.fire_emp_pulse()
    assert(roxy.emp_current_timer == 8.0, "FAILED: EMP timer did not reset to cooldown length upon firing")

    # Attempt to fire while on cooldown
    roxy.fire_emp_pulse()
    assert(roxy.emp_current_timer == 8.0, "FAILED: EMP timer re-triggered during active cooldown")

    print("[PASS] test_emp_pulse_mechanics: Roxy EMP stun pulse cooldown and discharge validated.")
    roxy.free()
    return true
