extends Node3D

# Main Game Initialization Node for "Sub-Routine"

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var level_container: Node3D = $LevelContainer
@onready var hud: Control = $HUD
@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
    # Cap frame rate to 60 FPS to prevent thermal throttling on mobile Android devices
    Engine.max_fps = 60
    
    # Audio Fix: Fix web audio crackling caused by browser buffer underruns in single-threaded WASM
    if OS.has_feature("web"):
        AudioServer.set("driver/output_latency", 50)
        print("[Sub-Routine Init] Web export detected. Set AudioServer driver/output_latency to 50ms.")

    print("[Sub-Routine Init] Engine initialized at 60 FPS cap on gl_compatibility renderer.")
    
    # Connect signals from autoload managers
    if has_node("/root/LevelManager"):
        var lm = get_node("/root/LevelManager")
        lm.level_loaded.connect(_on_level_loaded)
        var start_lvl = 1
        for arg in OS.get_cmdline_args():
            if arg.begins_with("--level="):
                start_lvl = int(arg.trim_prefix("--level="))
        lm.load_level(start_lvl)

    if has_node("/root/TheOverseer"):
        var overseer = get_node("/root/TheOverseer")
        overseer.dialogue_triggered.connect(_on_overseer_dialogue)

func _on_level_loaded(level_index: int, level_node: Node) -> void:
    print("[Main] Level ", level_index, " loaded into active viewport.")
    var player = find_child("RoxyVance", true, false)
    if player:
        var lm = get_node_or_null("/root/LevelManager")
        var is_backtrack = lm and "is_backtracking" in lm and lm.is_backtracking
        var spawn: Marker3D = null
        if is_backtrack and level_node:
            spawn = level_node.find_child("BacktrackSpawnPoint", true, false) as Marker3D
        if not spawn and level_node:
            spawn = level_node.find_child("SpawnPoint", true, false) as Marker3D

        if spawn:
            player.global_position = spawn.global_position
            player.rotation = spawn.rotation
        else:
            player.global_position = Vector3(0, 0.5, -12)
            player.rotation = Vector3(0, PI, 0)
        player.velocity = Vector3.ZERO
        # Preserve player health across level transitions so survival horror mechanics matter
        player.health_changed.emit(player.current_health, player.max_health)
        player.stamina_changed.emit(player.current_stamina, player.max_stamina)
        print("[Main] Player positioned at Sector ", level_index, " coordinates: ", player.global_position)

    if hud and hud.has_method("update_objective") and level_index > 1:
        hud.update_objective("Sector %02d: Recover Corrupted Memory Registers" % level_index)

    if has_node("/root/SaveManager"):
        var sm = get_node("/root/SaveManager")
        if not sm.is_loading_save and level_index > 1:
            sm.save_game("Sector %02d Checkpoint" % level_index)

    if "--capture-screenshot" in OS.get_cmdline_args():
        get_tree().create_timer(1.2).timeout.connect(func():
            var intro = find_child("IntroSequence", true, false)
            if intro:
                intro.visible = false
            var hud_node = find_child("HUD", true, false)
            if hud_node and "intro_active" in hud_node:
                hud_node.intro_active = false
            print("[Main] Intro auto-dismissed for automated gameplay capture.")
        )
        get_tree().create_timer(2.2).timeout.connect(func():
            var img = get_viewport().get_texture().get_image()
            if img:
                img.save_png("/tmp/godot_viewport_gameplay.png")
                print("[Main] Viewport screenshot saved to /tmp/godot_viewport_gameplay.png")
        )

func _on_overseer_dialogue(text: String, audio_stream_name: String) -> void:
    if hud and hud.has_method("display_overseer_message"):
        hud.display_overseer_message(text, audio_stream_name)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_map"):
        var map_modal = find_child("MapViewerModal", true, false)
        if map_modal:
            map_modal.toggle_map()
            get_viewport().set_input_as_handled()
            return
    elif event.is_action_pressed("pause_game"):
        var map_modal = find_child("MapViewerModal", true, false)
        if map_modal and ("is_open" in map_modal and map_modal.is_open or map_modal.visible):
            map_modal.close_map()
            get_viewport().set_input_as_handled()
            return
        var term = find_child("SubroutineTerminal", true, false)
        if term and term.visible:
            term.toggle_terminal()
            get_viewport().set_input_as_handled()
            return
        _toggle_pause()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F12:
            var img = get_viewport().get_texture().get_image()
            if img:
                img.save_png("/tmp/godot_viewport_gameplay.png")
                print("[Main] Screenshot saved to /tmp/godot_viewport_gameplay.png via F12")
        elif event.keycode == KEY_F1:
            if has_node("/root/LevelManager"):
                get_node("/root/LevelManager").load_level(1)
        elif event.keycode == KEY_F2:
            if has_node("/root/LevelManager"):
                get_node("/root/LevelManager").load_level(2)
        elif event.keycode == KEY_F3:
            if has_node("/root/LevelManager"):
                get_node("/root/LevelManager").load_level(3)
        elif event.keycode == KEY_F4:
            if has_node("/root/LevelManager"):
                get_node("/root/LevelManager").load_level(4)

func _toggle_pause() -> void:
    var is_paused = get_tree().paused
    get_tree().paused = not is_paused
    if pause_menu:
        pause_menu.visible = not is_paused
        if pause_menu.visible:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
