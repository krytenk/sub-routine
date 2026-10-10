extends Control

# Sub-Routine Sleek PS1 HUD, Introductory Briefing, and Overseer Glitch Monitor

@onready var health_bar: ProgressBar = $VitalsContainer/BarsContainer/HealthBar
@onready var health_label: Label = $VitalsContainer/BarsContainer/HealthLabel
@onready var stamina_bar: ProgressBar = $VitalsContainer/BarsContainer/StaminaBar
@onready var emp_label: Label = $VitalsContainer/BarsContainer/EMPLabel
@onready var objective_toast: PanelContainer = $ObjectiveToast
@onready var objective_label: Label = $ObjectiveToast/MarginContainer/ObjectiveLabel
@onready var overseer_panel: PanelContainer = $OverseerDialogue
@onready var overseer_text: RichTextLabel = $OverseerDialogue/MarginContainer/VBoxContainer/DialogueText
@onready var overseer_title: Label = $OverseerDialogue/MarginContainer/VBoxContainer/TitleLabel
@onready var intro_sequence: ColorRect = $IntroSequence
@onready var crt_glitch_rect: ColorRect = $CRTGlitchOverlay

var dialogue_timer: float = 0.0
var glitch_timer: float = 0.0
var target_glitch_intensity: float = 0.0
var objective_tween: Tween = null
var intro_active: bool = true

func _ready() -> void:
	overseer_panel.visible = false
	objective_toast.visible = false
	
	if intro_sequence and intro_sequence.visible:
		intro_active = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		intro_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").glitch_overlay_requested.connect(_on_glitch_requested)

	# Listen to player signals
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if p.has_signal("health_changed"):
			p.health_changed.connect(_on_player_health_changed)
		if p.has_signal("stamina_changed"):
			p.stamina_changed.connect(_on_player_stamina_changed)
		if p.has_signal("emp_cooldown_updated"):
			p.emp_cooldown_updated.connect(_on_player_emp_cooldown_updated)

func _input(event: InputEvent) -> void:
	if intro_active and intro_sequence and intro_sequence.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_intro()
			get_viewport().set_input_as_handled()

func dismiss_intro() -> void:
	if not intro_active:
		return
	intro_active = false
	if is_inside_tree() and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am and am.has_method("unlock_audio"):
			am.unlock_audio()
		elif am and am.ambient_player and not am.ambient_player.playing:
			am.start_ambient_drone()
	_play_terminal_chirp()
	var tween = create_tween()
	if tween:
		tween.tween_property(intro_sequence, "modulate:a", 0.0, 0.45)
		tween.tween_callback(func():
			if intro_sequence:
				intro_sequence.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			update_objective("Recover the glowing Memory Core and interface with the CRT Terminal [E]")
		)
	else:
		intro_sequence.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		update_objective("Recover the glowing Memory Core and interface with the CRT Terminal [E]")

	# Chilling developer AI greeting 2.2 seconds after boot into Sector 1
	get_tree().create_timer(2.2).timeout.connect(func():
		if is_inside_tree() and has_node("/root/TheOverseer"):
			var ov = get_node("/root/TheOverseer")
			if ov.dialogue_history.is_empty():
				ov.trigger_dialogue("darkness_whisper")
	)


func _play_terminal_chirp() -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	var player = AudioStreamPlayer.new()
	player.stream = gen
	add_child(player)
	player.play()
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var frames = int(gen.mix_rate * 0.08)
		for i in range(frames):
			var t = float(i) / gen.mix_rate
			var sample = sin(t * 880.0 * TAU) * 0.25
			playback.push_frame(Vector2(sample, sample))
	get_tree().create_timer(0.2).timeout.connect(player.queue_free)

func update_objective(new_text: String) -> void:
	if not objective_toast or not objective_label:
		return
	objective_label.text = "OBJECTIVE: " + new_text
	objective_toast.visible = true
	objective_toast.modulate.a = 1.0

	if objective_tween and objective_tween.is_valid():
		objective_tween.kill()
	
	objective_tween = create_tween()
	objective_tween.tween_interval(4.5)
	objective_tween.tween_property(objective_toast, "modulate:a", 0.0, 0.6)
	objective_tween.tween_callback(func():
		if objective_toast:
			objective_toast.visible = false
	)

func _process(delta: float) -> void:
	if dialogue_timer > 0:
		dialogue_timer -= delta
		if dialogue_timer <= 0:
			overseer_panel.visible = false

	# Glitch decay
	if glitch_timer > 0:
		glitch_timer -= delta
		var intensity = clampf(glitch_timer * target_glitch_intensity, 0.0, 1.0)
		_set_crt_glitch(intensity)
	else:
		_set_crt_glitch(0.0)

func _on_player_health_changed(cur: int, max_val: int) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = cur
	if health_label:
		health_label.text = "ROXY HP: %d / %d" % [cur, max_val]

func _on_player_stamina_changed(cur: float, max_val: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = cur

func display_overseer_message(message: String, _clip_name: String = "") -> void:
	if overseer_panel and overseer_text:
		overseer_title.text = "[ THE OVERSEER - RUNTIME DEV AI ]"
		overseer_text.text = "[shake rate=15.0 level=4]" + message + "[/shake]"
		overseer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overseer_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overseer_text.focus_mode = Control.FOCUS_NONE
		overseer_text.release_focus()
		overseer_panel.visible = true
		var dur: float = 5.5
		if is_inside_tree() and has_node("/root/AudioManager"):
			var am = get_node("/root/AudioManager")
			if am.has_method("get_vo_duration"):
				dur = maxf(5.5, am.get_vo_duration(_clip_name) + 0.8)
		dialogue_timer = dur

func _on_glitch_requested(intensity: float, duration: float) -> void:
	target_glitch_intensity = intensity
	glitch_timer = duration

func _set_crt_glitch(val: float) -> void:
	if crt_glitch_rect and crt_glitch_rect.material is ShaderMaterial:
		(crt_glitch_rect.material as ShaderMaterial).set_shader_parameter("glitch_intensity", val)

func _on_player_emp_cooldown_updated(current: float, max_val: float) -> void:
	if emp_label:
		var mk_text = "MK I"
		if max_val <= 4.0:
			mk_text = "MK III"
		elif max_val <= 6.0:
			mk_text = "MK II"
		
		if current <= 0.0:
			emp_label.text = "[F] EMP PULSE (%s): READY" % mk_text
			emp_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 1.0))
		else:
			emp_label.text = "[F] EMP (%s) RECHARGE: %.1fs" % [mk_text, current]
			emp_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2, 1.0))
