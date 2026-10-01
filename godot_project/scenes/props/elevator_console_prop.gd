extends Node3D
class_name ElevatorConsoleProp

# Sub-Routine Elevator Hoist Interactive Console
# Gates elevator ascension from Sector 04 to Sector 05 on auxiliary turbine power.
# Requires player to have installed all 3 generator parts in Sector 4B.

signal elevator_engaged

@export var target_level_index: int = 5
@export var prompt_text_unpowered: String = "[E] ELEVATOR HOIST (UNPOWERED)"
@export var prompt_text_powered: String = "[E] ENGAGE ELEVATOR (ASCEND TO SECTOR 05)"

var is_in_range: bool = false
var is_activating: bool = false

var status_light: OmniLight3D = null
var prompt_label: Label3D = null
var crt_screen_label: Label3D = null
var audio_motor: AudioStreamPlayer = null
var audio_buzzer: AudioStreamPlayer = null

func _ready() -> void:
	_setup_visuals()
	_update_power_status()

	var area = find_child("InteractArea", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func _setup_visuals() -> void:
	# Console pedestal & CRT screen mesh
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var ped_mesh = BoxMesh.new()
	ped_mesh.size = Vector3(0.8, 1.2, 0.6)
	var ped_mat = StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.2, 0.22, 0.25, 1.0)
	ped_mat.metallic = 0.8
	ped_mat.roughness = 0.4
	ped_mesh.material = ped_mat
	pedestal.mesh = ped_mesh
	pedestal.position = Vector3(0.0, 0.6, 0.0)
	add_child(pedestal)

	var screen_casing = MeshInstance3D.new()
	screen_casing.name = "ScreenCasing"
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(0.7, 0.5, 0.4)
	screen_casing.mesh = screen_mesh
	screen_casing.position = Vector3(0.0, 1.35, 0.05)
	add_child(screen_casing)

	# Status indicator light
	status_light = OmniLight3D.new()
	status_light.name = "StatusLight"
	status_light.light_energy = 2.5
	status_light.omni_range = 6.0
	status_light.position = Vector3(0.0, 1.65, 0.25)
	add_child(status_light)

	# 3D CRT display label
	crt_screen_label = Label3D.new()
	crt_screen_label.name = "CRTScreen"
	crt_screen_label.pixel_size = 0.003
	crt_screen_label.font_size = 28
	crt_screen_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	crt_screen_label.position = Vector3(0.0, 1.35, 0.26)
	add_child(crt_screen_label)

	# Floating interaction prompt
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.position = Vector3(0.0, 2.0, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

	# Audio players
	audio_motor = AudioStreamPlayer.new()
	audio_motor.name = "MotorSFX"
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_generator_start.wav"):
		audio_motor.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_generator_start.wav")
	add_child(audio_motor)

	audio_buzzer = AudioStreamPlayer.new()
	audio_buzzer.name = "BuzzerSFX"
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_part_install.wav"):
		audio_buzzer.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_part_install.wav")
		audio_buzzer.pitch_scale = 0.5
	add_child(audio_buzzer)

func _process(_delta: float) -> void:
	if not is_activating:
		_update_power_status()

func is_powered() -> bool:
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if "is_generator_running" in lm and lm.is_generator_running:
			return true
	return false

func _update_power_status() -> void:
	var powered = is_powered()
	if powered:
		if status_light:
			status_light.light_color = Color(0.2, 1.0, 0.45) # Emerald Green
		if crt_screen_label:
			crt_screen_label.text = "[ ELEVATOR HOIST ]\nSTATUS: ONLINE (100%)\nROUTE: SECTOR 05"
			crt_screen_label.modulate = Color(0.3, 1.0, 0.5)
		if prompt_label:
			prompt_label.text = prompt_text_powered
			prompt_label.modulate = Color(0.3, 1.0, 0.5)
	else:
		if status_light:
			status_light.light_color = Color(1.0, 0.2, 0.15) # Warning Red
		if crt_screen_label:
			crt_screen_label.text = "[ ELEVATOR HOIST ]\nSTATUS: OFFLINE\nRESTORE AT SEC-4B"
			crt_screen_label.modulate = Color(1.0, 0.35, 0.2)
		if prompt_label:
			prompt_label.text = prompt_text_unpowered
			prompt_label.modulate = Color(1.0, 0.5, 0.25)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = true
		_update_power_status()
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not is_activating and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if is_activating:
		return

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not is_powered():
		# Elevator unpowered feedback
		if audio_buzzer:
			audio_buzzer.play()

		var part_count = 0
		if is_inside_tree() and has_node("/root/LevelManager"):
			var lm = get_node("/root/LevelManager")
			if "generator_parts" in lm:
				part_count = lm.generator_parts.size()

		var msg = "[ ELEVATOR HOIST: NO POWER ]\nMain traction hoist unpowered. Auxiliary turbine in Sector 4B offline.\nRequired components: Relay, Coolant, Fuse.\n(You have %d/3 components in inventory)" % part_count
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(msg, "overseer_generator_need_parts")

		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("elevator_unpowered", "That hoist isn't going anywhere without power, Roxy. Head to the Auxiliary Turbine Bay in Sector 4B and install the components you scavenged.")
		return

	# Powered: engage ascension!
	is_activating = true
	if prompt_label:
		prompt_label.visible = false

	if audio_motor:
		audio_motor.play()

	if is_inside_tree() and get_tree() and get_tree().root:
		var player = get_tree().root.find_child("RoxyVance", true, false)
		if player and player.has_method("apply_trauma"):
			player.apply_trauma(0.5)

	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message("[ ELEVATOR HOIST ENGAGED ]\nAscending to Sector 05: Executive Overlook...", "overseer_generator_restored")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("elevator_ascend", "Ascension engaged. Hold onto something, Roxy. The executive level hasn't had visitors in a very long time.")

	elevator_engaged.emit()

	get_tree().create_timer(1.2).timeout.connect(func():
		if is_inside_tree() and has_node("/root/LevelManager"):
			var lm = get_node("/root/LevelManager")
			if lm.has_method("load_level"):
				lm.load_level(target_level_index)
	)
