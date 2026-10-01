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
		if "generator_parts" in lm:
			var parts: Array = lm.get("generator_parts")
			if parts.has("generator_part_" + part_type):
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

	var area = find_child("Area3D", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	add_to_group("interactive_props")
	add_to_group("generator_parts")
	add_to_group("pickups")

func interact(_player: CharacterBody3D = null) -> void:
	print("[GeneratorPartPickup] Interaction received for: ", part_type)
	collect()

func _process(delta: float) -> void:
	# Subtle floating bob and slow rotation
	var t = Time.get_ticks_msec() / 1000.0
	position.y = start_y + sin(t * 2.2) * 0.05
	rotate_y(delta * 1.2)

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
	part_collected.emit(full_key)

	if audio_player and audio_player.stream:
		audio_player.play()

	# Register in global LevelManager inventory
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if not "generator_parts" in lm:
			lm.set("generator_parts", [])
		var parts: Array = lm.get("generator_parts")
		if not parts.has(full_key):
			parts.append(full_key)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Acquired: %s" % _get_part_display_name())

	if prompt_label:
		prompt_label.visible = false
	var model = find_child("Model", true, false)
	if model:
		model.visible = false

	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.6).timeout.connect(queue_free)
	else:
		queue_free()
