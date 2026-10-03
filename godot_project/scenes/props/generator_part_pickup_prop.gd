extends Node3D
class_name GeneratorPartPickupProp

# Sub-Routine Multi-Component Puzzle: Generator Repair Part Pickup
# Collectible industrial components required to restore power to the auxiliary generator.

signal part_collected(part_type: String)

@export_enum("relay", "coolant", "fuse") var part_type: String = "relay"
@export var part_id: String = ""

var collected: bool = false
var audio_player: AudioStreamPlayer = null
var prompt_label: Label3D = null
var part_light: OmniLight3D = null
var base_light_energy: float = 0.85
var is_in_range: bool = false
var start_y: float = 0.0

func _ready() -> void:
	if part_id.is_empty():
		var pos = global_position if is_inside_tree() else position
		part_id = "part_" + part_type + "_" + str(int(round(pos.x))) + "_" + str(int(round(pos.z)))
		
	start_y = position.y
	
	# Check if already in inventory
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("has_generator_part"):
			if lm.has_generator_part("generator_part_" + part_type):
				queue_free()
				return
		elif "generator_parts" in lm and lm.generator_parts is Array:
			if lm.generator_parts.has("generator_part_" + part_type):
				queue_free()
				return
				
	# Load specific mesh
	var glb_path = "res://assets/models/generator_part_" + part_type + ".glb"
	if ResourceLoader.exists(glb_path):
		var scene_res = ResourceLoader.load(glb_path)
		if scene_res is PackedScene:
			var inst = scene_res.instantiate()
			inst.name = "Model"
			add_child(inst)

	audio_player = AudioStreamPlayer.new()
	audio_player.name = "PickupAudio"
	audio_player.bus = "Master"
	add_child(audio_player)
	var sound_path = "res://assets/audio/sfx/sfx_part_pickup.wav"
	if ResourceLoader.exists(sound_path):
		audio_player.stream = ResourceLoader.load(sound_path)

	prompt_label = Label3D.new()
	var part_display_name = _get_part_display_name()
	prompt_label.text = "[E] TAKE " + part_display_name.to_upper()
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.modulate = Color(0.2, 0.9, 1.0, 0.9)
	prompt_label.position = Vector3(0.0, 0.55, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

	_build_part_lighting()

	var area = find_child("Area3D", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	add_to_group("interactive_props")
	add_to_group("generator_parts")
	add_to_group("pickups")

func _build_part_lighting() -> void:
	var col = Color(0.2, 0.85, 1.0, 1.0) # Coolant azure
	match part_type:
		"relay":
			col = Color(1.0, 0.65, 0.2, 1.0) # Induction coil amber
		"coolant":
			col = Color(0.2, 0.85, 1.0, 1.0) # Cryo cyan
		"fuse":
			col = Color(0.4, 0.75, 1.0, 1.0) # High-voltage electric blue

	# Soft ambient equipment glow
	part_light = OmniLight3D.new()
	part_light.name = "PartLight"
	part_light.light_color = col
	part_light.light_energy = base_light_energy
	part_light.omni_range = 4.6
	part_light.omni_attenuation = 1.7
	part_light.position = Vector3(0.0, 0.25, 0.0)
	add_child(part_light)

	# Blinking status micro-LED on the component chassis
	var led_mesh = SphereMesh.new()
	led_mesh.radius = 0.02
	led_mesh.height = 0.04

	var led_mat = StandardMaterial3D.new()
	led_mat.albedo_color = col
	led_mat.emission_enabled = true
	led_mat.emission = col
	led_mat.emission_energy_multiplier = 3.5

	var led_inst = MeshInstance3D.new()
	led_inst.name = "StatusLED"
	led_inst.mesh = led_mesh
	led_inst.material_override = led_mat
	led_inst.position = Vector3(0.08, 0.18, 0.08)
	add_child(led_inst)

func interact(_player: CharacterBody3D = null) -> void:
	print("[GeneratorPartPickup] Interaction received for: ", part_type)
	collect()

func _process(delta: float) -> void:
	# Subtle floating bob and slow rotation
	var t = Time.get_ticks_msec() / 1000.0
	position.y = start_y + sin(t * 2.2) * 0.05
	rotate_y(delta * 1.2)
	
	if part_light:
		part_light.light_energy = base_light_energy + sin(t * 3.2) * 0.18

func _get_part_display_name() -> String:
	match part_type:
		"relay":
			return "Transformer Relay"
		"coolant":
			return "Coolant Compression Cell"
		"fuse":
			return "Heavy Magnetic Fuse"
		_:
			return "Generator Component"

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

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and event.is_action_pressed("interact") and not collected:
		get_viewport().set_input_as_handled()
		collect()

func collect() -> void:
	if collected:
		return
	collected = true
	var full_key = "generator_part_" + part_type
	print("[GeneratorPartPickup] Collecting part: ", full_key)
	part_collected.emit(full_key)

	# Instantly remove from interactive groups so it cannot be re-triggered
	remove_from_group("interactive_props")
	remove_from_group("generator_parts")
	remove_from_group("pickups")

	var area = find_child("Area3D", true, false) as Area3D
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

	# Register in global LevelManager inventory
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("add_generator_part"):
			lm.add_generator_part(full_key)
		elif "generator_parts" in lm and lm.generator_parts is Array:
			if not lm.generator_parts.has(full_key):
				lm.generator_parts.append(full_key)

	if is_inside_tree() and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("sfx_part_pickup")
	elif audio_player and audio_player.stream:
		audio_player.play()

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Acquired: %s" % _get_part_display_name())

	if prompt_label:
		prompt_label.visible = false
	for child in get_children():
		if child is VisualInstance3D or child is Light3D:
			child.visible = false

	queue_free()
