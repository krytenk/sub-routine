extends Control

# Sub-Routine Pause Menu with Dynamic Difficulty Slider

@onready var difficulty_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SliderContainer/HSlider
@onready var difficulty_val_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SliderContainer/DifficultyValLabel
@onready var multiplier_summary: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/MultiplierSummary
@onready var resume_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var view_map_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ViewMapButton
@onready var music_toggle_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/MusicToggleButton
@onready var save_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/LoadButton
@onready var restart_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton

func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
        _update_music_button_text()

func _ready() -> void:
    if difficulty_slider and has_node("/root/DifficultyManager"):
        var dm = get_node("/root/DifficultyManager")
        difficulty_slider.value = dm.difficulty_value
        _on_slider_value_changed(dm.difficulty_value)
        difficulty_slider.value_changed.connect(_on_slider_value_changed)

    if resume_button:
        resume_button.pressed.connect(_on_resume_pressed)
    if view_map_button:
        view_map_button.pressed.connect(_on_view_map_pressed)
    if music_toggle_button:
        music_toggle_button.pressed.connect(_on_music_toggle_pressed)
        _update_music_button_text()
    if has_node("/root/AudioManager"):
        get_node("/root/AudioManager").music_toggled.connect(func(_enabled): _update_music_button_text())
    if save_button:
        save_button.pressed.connect(_on_save_pressed)
    if load_button:
        load_button.pressed.connect(_on_load_pressed)
    if restart_button:
        restart_button.pressed.connect(_on_restart_pressed)
    if quit_button:
        quit_button.pressed.connect(_on_quit_pressed)


func _on_view_map_pressed() -> void:
    get_tree().paused = false
    visible = false
    var map_modal = null
    if is_inside_tree() and get_tree().root:
        map_modal = get_tree().root.find_child("MapViewerModal", true, false)
    if map_modal and map_modal.has_method("open_map"):
        map_modal.open_map()

func _on_save_pressed() -> void:
    if has_node("/root/SaveManager"):
        get_node("/root/SaveManager").save_game()

func _on_load_pressed() -> void:
    if has_node("/root/SaveManager"):
        get_node("/root/SaveManager").load_game()
        get_tree().paused = false
        visible = false
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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

func _on_music_toggle_pressed() -> void:
    if has_node("/root/AudioManager"):
        var am = get_node("/root/AudioManager")
        am.toggle_music()
        _update_music_button_text()

func _update_music_button_text() -> void:
    if not music_toggle_button:
        return
    if has_node("/root/AudioManager"):
        var is_on = get_node("/root/AudioManager").is_music_enabled
        music_toggle_button.text = "Ambient Music: [ ON ] (Toggle: N)" if is_on else "Ambient Music: [ MUTED ] (Toggle: N)"

