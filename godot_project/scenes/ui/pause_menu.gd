extends Control

# Sub-Routine Pause Menu with Dynamic Difficulty Slider

@onready var difficulty_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SliderContainer/HSlider
@onready var difficulty_val_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SliderContainer/DifficultyValLabel
@onready var multiplier_summary: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/MultiplierSummary
@onready var resume_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
    if difficulty_slider and has_node("/root/DifficultyManager"):
        var dm = get_node("/root/DifficultyManager")
        difficulty_slider.value = dm.difficulty_value
        _on_slider_value_changed(dm.difficulty_value)
        difficulty_slider.value_changed.connect(_on_slider_value_changed)

    if resume_button:
        resume_button.pressed.connect(_on_resume_pressed)
    if restart_button:
        restart_button.pressed.connect(_on_restart_pressed)
    if quit_button:
        quit_button.pressed.connect(_on_quit_pressed)

func _on_slider_value_changed(val: float) -> void:
    if has_node("/root/DifficultyManager"):
        var dm = get_node("/root/DifficultyManager")
        dm.set_difficulty_value(val)
        
        var tier_name = dm.get_difficulty_name()
        var speed_mult = dm.get_enemy_speed_multiplier()
        var puzzle_mult = dm.get_puzzle_complexity_multiplier()
        
        if difficulty_val_label:
            difficulty_val_label.text = tier_name.to_upper()
        if multiplier_summary:
            multiplier_summary.text = "Enemy Speed: %.1fx | Puzzle Complexity: %.1fx" % [speed_mult, puzzle_mult]

func _on_resume_pressed() -> void:
    get_tree().paused = false
    visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_restart_pressed() -> void:
    get_tree().paused = false
    visible = false
    if has_node("/root/LevelManager"):
        var lm = get_node("/root/LevelManager")
        lm.load_level(lm.current_level_index)

func _on_quit_pressed() -> void:
    get_tree().quit()
