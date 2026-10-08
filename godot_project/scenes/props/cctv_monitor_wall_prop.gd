extends Node3D
class_name CCTVMonitorWallProp

# Sub-Routine CCTV Surveillance Monitor Bank
# Reveals that Roxy was monitored by hidden facility cameras throughout Sectors 01-08.

signal surveillance_accessed

@export var is_powered: bool = false
@export var prompt_message: String = "[E] Inspect Surveillance Matrix"

var is_in_range: bool = false
var has_been_accessed: bool = false
var prompt_label: Label3D = null
var screen_labels: Array[Label3D] = []
var screen_lights: Array[OmniLight3D] = []
var audio_static: AudioStreamPlayer3D = null

func _ready() -> void:
	_build_monitor_wall()
	_build_prompt()
	_build_audio()

	var area = Area3D.new()
	area.name = "InteractionArea"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.2, 2.5, 2.5)
	col.shape = box
	area.add_child(col)
	area.collision_layer = 1
	area.collision_mask = 2
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	add_to_group("interactive_props")
	add_to_group("cctv_monitors")

func _build_monitor_wall() -> void:
	# Metal cabinet housing
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(2.6, 2.0, 0.6)
	var mat_housing = StandardMaterial3D.new()
	mat_housing.albedo_color = Color(0.1, 0.12, 0.14, 1.0)
	mat_housing.metallic = 0.85
	mat_housing.roughness = 0.4

	var housing_inst = MeshInstance3D.new()
	housing_inst.name = "Housing"
	housing_inst.mesh = housing_mesh
	housing_inst.material_override = mat_housing
	housing_inst.position = Vector3(0, 1.2, 0)
	add_child(housing_inst)

	# 4 CRT Monitor Screens (2x2 grid)
	var screen_offsets = [
		Vector3(-0.6, 1.6, 0.31),  # Top-Left (Sector 01)
		Vector3(0.6, 1.6, 0.31),   # Top-Right (Sector 04)
		Vector3(-0.6, 0.8, 0.31),  # Bottom-Left (Sector 06)
		Vector3(0.6, 0.8, 0.31)    # Bottom-Right (Sector 08 Live)
	]

	var default_texts = [
		"[ CAM 01: BIOS BOOT ]\nLOGGED: 00:04:12\nCORRIDOR EMPTY\nTARGET PROCEEDED",
		"[ CAM 04: ASCENSION ]\nLOGGED: 00:19:40\nWIREHOUND RETREAT\nSUBJECT ASCENDED",
		"[ CAM 06: SERVER VAULT ]\nLOGGED: 00:32:15\nCYBERHUSK OVERLOAD\nCIPHER BREACHED",
		"[ CAM 08: OBS ROOM ]\nLIVE STREAM\n[ ACTIVE TARGET DETECTED ]\nSUBJECT INSIDE ROOM"
	]

	for i in range(4):
		var scr_mesh = BoxMesh.new()
		scr_mesh.size = Vector3(1.05, 0.75, 0.05)
		var mat_scr = StandardMaterial3D.new()
		mat_scr.albedo_color = Color(0.04, 0.08, 0.05, 1.0)
		mat_scr.emission_enabled = true
		mat_scr.emission = Color(0.1, 0.6, 0.3, 1.0) if is_powered else Color(0.02, 0.1, 0.05, 1.0)
		mat_scr.emission_energy_multiplier = 1.4 if is_powered else 0.2

		var scr_inst = MeshInstance3D.new()
		scr_inst.name = "Screen_%d" % i
		scr_inst.mesh = scr_mesh
		scr_inst.material_override = mat_scr
		scr_inst.position = screen_offsets[i]
		add_child(scr_inst)

		var lbl = Label3D.new()
		lbl.name = "Text_%d" % i
		lbl.text = default_texts[i] if is_powered else "[ FEED OFFLINE - PRESS E TO BOOT ]"
		lbl.font_size = 14
		lbl.modulate = Color(0.3, 1.0, 0.5, 1.0) if is_powered else Color(0.2, 0.4, 0.2, 0.7)
		lbl.outline_modulate = Color.BLACK
		lbl.outline_size = 3
		lbl.position = screen_offsets[i] + Vector3(0, 0, 0.04)
		add_child(lbl)
		screen_labels.append(lbl)

		var light = OmniLight3D.new()
		light.name = "Light_%d" % i
		light.light_color = Color(0.2, 0.9, 0.4, 1.0)
		light.light_energy = 0.8 if is_powered else 0.1
		light.omni_range = 2.5
		light.position = screen_offsets[i] + Vector3(0, 0, 0.2)
		add_child(light)
		screen_lights.append(light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = prompt_message
	prompt_label.font_size = 20
	prompt_label.modulate = Color(0.2, 1.0, 0.4, 1.0)
	prompt_label.position = Vector3(0, 2.4, 0.4)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _build_audio() -> void:
	audio_static = AudioStreamPlayer3D.new()
	audio_static.name = "AudioStatic"
	audio_static.max_distance = 18.0
	audio_static.bus = "Master"
	add_child(audio_static)

	var sfx_path = "res://assets/audio/sfx/cctv_static.wav"
	if ResourceLoader.exists(sfx_path):
		audio_static.stream = ResourceLoader.load(sfx_path)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and event.is_action_pressed("interact"):
		interact()

func interact(_player = null) -> void:
	activate_surveillance()

func activate_surveillance() -> void:
	is_powered = true
	has_been_accessed = true

	if audio_static and audio_static.stream:
		audio_static.play()

	var active_texts = [
		"[ CAM 01: BIOS BOOT ]\nLOGGED: 00:04:12\nCORRIDOR EMPTY\nTARGET PROCEEDED",
		"[ CAM 04: ASCENSION ]\nLOGGED: 00:19:40\nWIREHOUND RETREAT\nSUBJECT ASCENDED",
		"[ CAM 06: SERVER VAULT ]\nLOGGED: 00:32:15\nCYBERHUSK OVERLOAD\nCIPHER BREACHED",
		"[ CAM 08: OBS ROOM ]\nLIVE STREAM\n[ ACTIVE TARGET DETECTED ]\nSUBJECT INSIDE ROOM"
	]

	for i in range(screen_labels.size()):
		screen_labels[i].text = active_texts[i]
		screen_labels[i].modulate = Color(0.3, 1.0, 0.5, 1.0)
		if i < screen_lights.size():
			screen_lights[i].light_energy = 0.9

	surveillance_accessed.emit()
	print("[CCTVMonitorWall] Surveillance Matrix Activated! All past sector camera feeds displayed.")

	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ SURVEILLANCE LOG: SUBJECT MONITORED ]\nEvery room traversed since Sector 01 was recorded.",
			"overseer_cctv_stalker_reveal"
		)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("cctv_stalker_reveal")

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false
