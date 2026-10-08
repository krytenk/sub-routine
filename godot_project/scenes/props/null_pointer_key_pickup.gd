extends Node3D
class_name NullPointerKeyPickupProp

# Sector 08 Scavengeable Quest Item: Null Address Pointer Keycard
# Decryption keycard required to override the concourse lockdown gate.

signal keycard_collected

var collected: bool = false
var is_in_range: bool = false
var prompt_label: Label3D = null
var key_light: OmniLight3D = null
var mesh_anchor: Node3D = null

func _ready() -> void:
	_build_visuals()
	_build_prompt()

	var area = Area3D.new()
	area.name = "Area3D"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.6, 1.6, 1.6)
	col.shape = box
	area.add_child(col)
	area.collision_layer = 1
	area.collision_mask = 2
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	add_to_group("interactive_props")
	add_to_group("pickups")

func _build_visuals() -> void:
	mesh_anchor = Node3D.new()
	mesh_anchor.name = "KeyMeshAnchor"
	add_child(mesh_anchor)

	var card_mesh = BoxMesh.new()
	card_mesh.size = Vector3(0.18, 0.02, 0.28)
	var mat_card = StandardMaterial3D.new()
	mat_card.albedo_color = Color(0.9, 0.8, 0.2, 1.0)
	mat_card.metallic = 0.9
	mat_card.roughness = 0.2
	mat_card.emission_enabled = true
	mat_card.emission = Color(0.9, 0.7, 0.1, 1.0)
	mat_card.emission_energy_multiplier = 2.0

	var inst = MeshInstance3D.new()
	inst.name = "CardMesh"
	inst.mesh = card_mesh
	inst.material_override = mat_card
	mesh_anchor.add_child(inst)

	key_light = OmniLight3D.new()
	key_light.light_color = Color(1.0, 0.85, 0.2, 1.0)
	key_light.light_energy = 1.0
	key_light.omni_range = 2.5
	mesh_anchor.add_child(key_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "[E] Collect Null Address Pointer Keycard"
	prompt_label.font_size = 18
	prompt_label.modulate = Color(1.0, 0.9, 0.3, 1.0)
	prompt_label.position = Vector3(0, 0.5, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _process(delta: float) -> void:
	if mesh_anchor:
		mesh_anchor.rotate_y(delta * 1.8)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not collected and event.is_action_pressed("interact"):
		collect()

func interact(_player = null) -> void:
	collect()

func collect() -> void:
	if collected:
		return
	collected = true
	print("[NullPointerKeyPickup] Null Address Pointer Keycard collected!")

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("add_singularity_part"):
			lm.add_singularity_part("null_pointer_keycard")

	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ KEYCARD RECOVERED ]\nNull Address Pointer Keycard acquired. Swipe at Concourse Terminal to unseal Sector 09.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Swipe Null Pointer Keycard at the Concourse Terminal to open Sector 09.")

	keycard_collected.emit()
	queue_free()

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
