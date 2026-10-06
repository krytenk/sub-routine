extends Node3D
class_name SingularityPartPickupProp

# Sub-Routine Prototype Superweapon Component Pickup
# Scavengeable modules required to prime the Hyper-Flux Singularity Cannon.

signal component_collected(comp_name: String)

@export_enum("magnetron", "cryo", "key") var component_type: String = "magnetron"
@export var component_id: String = ""

var collected: bool = false
var prompt_label: Label3D = null
var part_light: OmniLight3D = null
var start_y: float = 0.0

func _ready() -> void:
	if component_id.is_empty():
		component_id = "singularity_" + component_type
	start_y = position.y

	# Check if already in inventory
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if "singularity_parts" in lm and lm.singularity_parts is Array:
			if lm.singularity_parts.has(component_id):
				queue_free()
				return

	_build_visuals()
	_build_prompt()

	var area = find_child("Area3D", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	add_to_group("interactive_props")
	add_to_group("singularity_parts")
	add_to_group("pickups")

func _build_visuals() -> void:
	var col = Color(1.0, 0.75, 0.2, 1.0) # Gold
	match component_type:
		"magnetron":
			col = Color(0.9, 0.2, 1.0, 1.0) # Violet plasma
		"cryo":
			col = Color(0.2, 0.85, 1.0, 1.0) # Cryo cyan
		"key":
			col = Color(1.0, 0.8, 0.15, 1.0) # Amber gold

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.25, 0.35, 0.25)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
	mat.metallic = 0.9
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	add_child(mesh_inst)

	part_light = OmniLight3D.new()
	part_light.light_color = col
	part_light.light_energy = 2.0
	part_light.omni_range = 5.0
	part_light.position = Vector3(0.0, 0.2, 0.0)
	add_child(part_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.text = "[E] TAKE " + _get_display_name().to_upper()
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.modulate = Color(0.3, 0.9, 1.0, 0.95)
	prompt_label.outline_size = 6
	prompt_label.position = Vector3(0.0, 0.55, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

func _get_display_name() -> String:
	match component_type:
		"magnetron":
			return "Magnetron Emitter Core"
		"cryo":
			return "Cryo-Stabilizer Capsule"
		"key":
			return "Targeting Matrix Key"
		_:
			return "Singularity Module"

func _process(delta: float) -> void:
	if collected:
		return
	var t = Time.get_ticks_msec() / 1000.0
	position.y = start_y + sin(t * 2.8) * 0.05
	rotate_y(delta * 1.5)

func interact(player: CharacterBody3D = null) -> void:
	if collected:
		return
	collect(player)

func collect(_player: CharacterBody3D = null) -> void:
	if collected:
		return
	collected = true
	print("[SingularityPart] Collected component: ", _get_display_name())

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if not ("singularity_parts" in lm):
			lm.set("singularity_parts", [])
		if not lm.singularity_parts.has(component_id):
			lm.singularity_parts.append(component_id)

	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ WEAPON MODULE ACQUIRED ]\n" + _get_display_name(),
			"overseer_emp_success"
		)

	component_collected.emit(component_id)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		if prompt_label:
			prompt_label.visible = false
