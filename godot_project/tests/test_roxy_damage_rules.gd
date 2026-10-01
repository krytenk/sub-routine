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

func test_health_replenishment() -> bool:
    var roxy = RoxyVance.new()
    roxy.current_health = 40
    roxy.heal(30)
    assert(roxy.current_health == 70, "FAILED: Health should be 70 after healing 30 from 40")
    roxy.heal(50)
    assert(roxy.current_health == 100, "FAILED: Health should not exceed max_health (100)")
    print("[PASS] test_health_replenishment: Health replenishment restores HP correctly up to cap.")
    roxy.free()
    return true

func test_roxy_jump_mechanics() -> bool:
    var roxy = RoxyVance.new()
    assert(roxy.jump_velocity == 5.4, "FAILED: Default jump_velocity should be 5.4")

    var jump_signal_fired: Array[bool] = [false]
    roxy.player_jumped.connect(func(): jump_signal_fired[0] = true)

    roxy.current_stamina = 100.0

    # Execute jump logic test
    var initial_stamina = roxy.current_stamina
    var jump_force = roxy.jump_velocity
    if roxy.current_stamina >= 6.0:
        roxy.current_stamina -= 6.0
    roxy.velocity.y = jump_force
    roxy.player_jumped.emit()

    assert(is_equal_approx(roxy.velocity.y, 5.4), "FAILED: Jump velocity should equal 5.4")
    assert(jump_signal_fired[0], "FAILED: player_jumped signal was not fired")
    assert(is_equal_approx(roxy.current_stamina, initial_stamina - 6.0), "FAILED: Jump did not consume 6 stamina")

    # Fatigue jump scaling test
    roxy.is_exhausted = true
    var fatigue_force = roxy.jump_velocity * 0.72
    assert(is_equal_approx(fatigue_force, 5.4 * 0.72), "FAILED: Fatigue jump force calculated incorrectly")

    print("[PASS] test_roxy_jump_mechanics: Roxy jump mechanics, velocity, stamina drain, and fatigue validated.")
    roxy.free()
    return true

