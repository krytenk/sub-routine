extends Node

# Sub-Routine Dynamic Difficulty Manager
# Scales enemy speed, enemy damage, and puzzle complexity from "Story" to "Nightmare"

signal difficulty_changed(value: float, name_label: String)

enum DifficultyTier {
    STORY,
    STANDARD,
    HARDCORE,
    NIGHTMARE
}

# Value ranges from 0.0 (Story) to 1.0 (Nightmare)
var difficulty_value: float = 0.33:
    set(val):
        difficulty_value = clampf(val, 0.0, 1.0)
        difficulty_changed.emit(difficulty_value, get_difficulty_name())

func set_difficulty_value(val: float) -> void:
    difficulty_value = val

func get_difficulty_tier() -> DifficultyTier:
    if difficulty_value < 0.25:
        return DifficultyTier.STORY
    elif difficulty_value < 0.6:
        return DifficultyTier.STANDARD
    elif difficulty_value < 0.85:
        return DifficultyTier.HARDCORE
    else:
        return DifficultyTier.NIGHTMARE

func get_difficulty_name() -> String:
    match get_difficulty_tier():
        DifficultyTier.STORY:
            return "Story"
        DifficultyTier.STANDARD:
            return "Standard"
        DifficultyTier.HARDCORE:
            return "Hardcore"
        DifficultyTier.NIGHTMARE:
            return "Nightmare"
        _:
            return "Standard"

# Enemy Speed Multiplier: 0.6x (Story) up to 2.0x (Nightmare)
func get_enemy_speed_multiplier() -> float:
    return lerpf(0.6, 2.0, difficulty_value)

# Enemy Damage Multiplier: 0.5x (Story) up to 2.5x (Nightmare)
func get_enemy_damage_multiplier() -> float:
    return lerpf(0.5, 2.5, difficulty_value)

# Puzzle Complexity Multiplier: 1.0x to 2.5x sequence/cipher length and tighter time constraints
func get_puzzle_complexity_multiplier() -> float:
    return lerpf(1.0, 2.5, difficulty_value)

# Puzzle time limit scaling factor (Story grants more time, Nightmare grants minimal time)
func get_puzzle_time_factor() -> float:
    return lerpf(1.8, 0.6, difficulty_value)

# Code / Cipher key length scaling (e.g. 3 digits on Story, 7 on Nightmare)
func get_cipher_key_length() -> int:
    return int(round(lerpf(3.0, 7.0, difficulty_value)))
