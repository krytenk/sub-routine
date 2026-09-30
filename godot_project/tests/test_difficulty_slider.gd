extends RefCounted

# GDUnit4 Test Suite: Dynamic Difficulty Slider
# Validates scaling of enemy speed, damage, and puzzle complexity across Story to Nightmare.

func test_story_difficulty() -> bool:
    var dm = load("res://scripts/difficulty_manager.gd").new()
    dm.set_difficulty_value(0.0)
    
    assert(dm.get_difficulty_name() == "Story", "FAILED: Tier should be Story at 0.0")
    assert(is_equal_approx(dm.get_enemy_speed_multiplier(), 0.6), "FAILED: Story speed multiplier must be 0.6x")
    assert(is_equal_approx(dm.get_enemy_damage_multiplier(), 0.5), "FAILED: Story damage multiplier must be 0.5x")
    assert(dm.get_cipher_key_length() == 3, "FAILED: Story cipher key length must be 3 digits")
    print("[PASS] test_story_difficulty: Story tier correctly scales parameters down.")
    dm.free()
    return true

func test_nightmare_difficulty() -> bool:
    var dm = load("res://scripts/difficulty_manager.gd").new()
    dm.set_difficulty_value(1.0)
    
    assert(dm.get_difficulty_name() == "Nightmare", "FAILED: Tier should be Nightmare at 1.0")
    assert(is_equal_approx(dm.get_enemy_speed_multiplier(), 2.0), "FAILED: Nightmare speed multiplier must be 2.0x")
    assert(is_equal_approx(dm.get_enemy_damage_multiplier(), 2.5), "FAILED: Nightmare damage multiplier must be 2.5x")
    assert(dm.get_cipher_key_length() == 7, "FAILED: Nightmare cipher key length must be 7 digits")
    print("[PASS] test_nightmare_difficulty: Nightmare tier correctly scales parameters up.")
    dm.free()
    return true
