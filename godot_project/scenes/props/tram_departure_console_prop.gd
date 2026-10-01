extends Node3D
class_name TramDepartureConsoleProp

# Sub-Routine Sub-Core Transit Tram Console
# Gates departure to Sector 06 (Deep Server Sub-Basement).
# Requires departure code to be decrypted in the Bio-Synthetic Research Bay.

signal tram_departed

@export var target_level_index: int = 6
@export var is_authorized: bool = false

var is_in_range: bool = false
var is_departing: bool = false

var status_light: OmniLight3D = null
var prompt_label: Label3D = null
var crt_screen_label: Label3D = null
var audio_motor: AudioStreamPlayer = null
var audio_buzzer: AudioStreamPlayer = null

func _ready() -> void:
	_setup_visuals()
	_update_display()

	var area = find_child("InteractArea", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _setup_visuals() -> void:
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var ped_mesh = BoxMesh.new()
	ped_mesh.size = Vector3(0.9, 1.2, 0.6)
	var ped_mat = StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.18, 0.22, 0.28, 1.0)
	ped_mat.metallic = 0.85
	ped_mat.roughness = 0.35
	ped_mesh.material = ped_mat
	pedestal.mesh = ped_mesh
	pedestal.position = Vector3(0.0, 0.6, 0.0)
	add_child(pedestal)

	var screen_casing = MeshInstance3D.new()
	screen_casing.name = "ScreenCasing"
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(0.8, 0.55, 0.45)
	screen_casing.mesh = screen_mesh
	screen_casing.position = Vector3(0.0, 1.35, 0.05)
	add_child(screen_casing)

	status_light = OmniLight3D.new()
	status_light.name = "StatusLight"
	status_light.light_energy = 2.8
	status_light.omni_range = 7.0
	status_light.position = Vector3(0.0, 1.65, 0.25)
	add_child(status_light)

	crt_screen_label = Label3D.new()
	crt_screen_label.name = "CRTScreen"
	crt_screen_label.pixel_size = 0.003
	crt_screen_label.font_size = 26
	crt_screen_label.position = Vector3(0.0, 1.35, 0.28)
	add_child(crt_screen_label)

	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.position = Vector3(0.0, 2.0, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

	audio_motor = AudioStreamPlayer.new()
	audio_motor.name = "MotorSFX"
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_generator_start.wav"):
		audio_motor.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_generator_start.wav")
	add_child(audio_motor)

	audio_buzzer = AudioStreamPlayer.new()
	audio_buzzer.name = "BuzzerSFX"
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_part_install.wav"):
		audio_buzzer.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_part_install.wav")
		audio_buzzer.pitch_scale = 0.45
	add_child(audio_buzzer)

func authorize_departure() -> void:
	is_authorized = true
	_update_display()

func _update_display() -> void:
	if is_authorized:
		if status_light:
			status_light.light_color = Color(0.2, 0.95, 0.4)
		if crt_screen_label:
			crt_screen_label.text = "[ MAGLEV TRANSIT 01 ]\nROUTE: SECTOR 06\nSTATUS: AUTHORIZED"
			crt_screen_label.modulate = Color(0.3, 1.0, 0.5)
		if prompt_label:
			prompt_label.text = "[E] BOARD ESCAPE TRAM (DEPART TO SECTOR 06)"
			prompt_label.modulate = Color(0.3, 1.0, 0.5)
	else:
		if status_light:
			status_light.light_color = Color(1.0, 0.2, 0.15)
		if crt_screen_label:
			crt_screen_label.text = "[ MAGLEV TRANSIT 01 ]\nSTATUS: LOCKED\nDECRYPT AT LAB"
			crt_screen_label.modulate = Color(1.0, 0.35, 0.2)
		if prompt_label:
			prompt_label.text = "[E] TRAM DEPARTURE (LOCKED - RESEARCH BAY CODE REQUIRED)"
			prompt_label.modulate = Color(1.0, 0.5, 0.25)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = true
		_update_display()
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not is_departing and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if is_departing:
		return

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not is_authorized:
		if audio_buzzer:
			audio_buzzer.play()
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ TRAM HOIST LOCKED ]\nExecutive departure lockdown active. Decrypt departure code in the Bio-Synthetic Research Bay.",
				"overseer_generator_need_parts"
			)
		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue(
				"tram_locked",
				"The tram magnetic coils are locked by executive emergency order, Roxy. Head to the Bio-Synthetic Research Bay and decrypt the departure override."
			)
		return

	# Authorized: Depart!
	is_departing = true
	if prompt_label:
		prompt_label.visible = false

	if audio_motor:
		audio_motor.play()

	if is_inside_tree() and get_tree() and get_tree().root:
		var player = get_tree().root.find_child("RoxyVance", true, false)
		if player and player.has_method("apply_trauma"):
			player.apply_trauma(0.65)

	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ ESCAPE TRAM ENGAGED ]\nDeparting to Sector 06: Deep Server Sub-Basement...",
			"overseer_generator_restored"
		)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"tram_depart",
			"Hold on tight, Roxy. Next stop is the Deep Server Sub-Basement. No one who's gone that deep has ever returned to the surface."
		)

	tram_departed.emit()

	get_tree().create_timer(1.2).timeout.connect(func():
		if is_inside_tree() and has_node("/root/LevelManager"):
			var lm = get_node("/root/LevelManager")
			if lm.has_method("load_level"):
				lm.load_level(target_level_index)
	)
