extends Node3D
class_name ThreadLockCipherPickupProp

# Sector 09 Scavengeable Quest Item: Thread Lock Bypass Decryption Cipher
# Required alongside the 3 Deadlock Relays to unseal the Transit Gate to Sector 10.

signal cipher_collected

var collected: bool = false
var is_in_range: bool = false
var prompt_label: Label3D = null
var cipher_light: OmniLight3D = null
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
	mesh_anchor.name = "CipherMeshAnchor"
	add_child(mesh_anchor)

	# Encrypted data drive cylinder
	var drive_mesh = CylinderMesh.new()
	drive_mesh.top_radius = 0.08
	drive_mesh.bottom_radius = 0.08
	drive_mesh.height = 0.22
	var mat_drive = StandardMaterial3D.new()
	mat_drive.albedo_color = Color(0.1, 0.8, 0.9, 1.0)
	mat_drive.metallic = 0.95
	mat_drive.roughness = 0.2
	mat_drive.emission_enabled = true
	mat_drive.emission = Color(0.2, 0.9, 1.0, 1.0)
	mat_drive.emission_energy_multiplier = 3.0

	var inst = MeshInstance3D.new()
	inst.name = "DriveMesh"
	inst.mesh = drive_mesh
	inst.material_override = mat_drive
	mesh_anchor.add_child(inst)

	cipher_light = OmniLight3D.new()
	cipher_light.light_color = Color(0.2, 0.9, 1.0, 1.0)
	cipher_light.light_energy = 1.2
	cipher_light.omni_range = 2.8
	mesh_anchor.add_child(cipher_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "[E] Collect Thread Lock Bypass Cipher"
	prompt_label.font_size = 18
	prompt_label.modulate = Color(0.3, 1.0, 0.9, 1.0)
	prompt_label.position = Vector3(0, 0.5, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _process(delta: float) -> void:
	if mesh_anchor:
		mesh_anchor.rotate_y(delta * 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not collected and event.is_action_pressed("interact"):
		collect()

func interact(_player = null) -> void:
	collect()

func collect() -> void:
	if collected:
		return
	collected = true
	print("[ThreadLockCipherPickup] Thread Lock Bypass Decryption Cipher collected!")

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("add_singularity_part"):
			lm.add_singularity_part("thread_lock_cipher")

	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ CIPHER RECOVERED ]\nThread Lock Decryption Cipher acquired. Cycle all 3 Deadlock Relays to unseal the Core.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Cycle Deadlock Relays A, B, and C in the Multi-Thread Ring.")

	cipher_collected.emit()
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
