extends Node3D
class_name DeadlockRelayProp

# Sector 09 Multi-Thread Deadlock Relay
# One of three asynchronous breaker relays that must be cycled to break the thread mutex lock.

signal relay_cycled(relay_id: String)

@export var relay_id: String = "relay_a"
@export var relay_name: String = "Deadlock Relay Alpha"

var is_cycled: bool = false
var is_in_range: bool = false
var prompt_label: Label3D = null
var status_light: OmniLight3D = null
var lamp_mesh: MeshInstance3D = null

func _ready() -> void:
	_build_visuals()
	_build_prompt()

	var area = Area3D.new()
	area.name = "Area3D"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4, 2.4, 2.4)
	col.shape = box
	area.add_child(col)
	area.collision_layer = 1
	area.collision_mask = 2
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	add_to_group("interactive_props")
	add_to_group("deadlock_relays")

func _build_visuals() -> void:
	# Pedestal
	var ped_mesh = BoxMesh.new()
	ped_mesh.size = Vector3(0.9, 1.3, 0.9)
	var mat_ped = StandardMaterial3D.new()
	mat_ped.albedo_color = Color(0.12, 0.14, 0.18, 1.0)
	mat_ped.metallic = 0.85
	mat_ped.roughness = 0.35

	var ped_inst = MeshInstance3D.new()
	ped_inst.name = "Pedestal"
	ped_inst.mesh = ped_mesh
	ped_inst.material_override = mat_ped
	ped_inst.position = Vector3(0, 0.65, 0)
	add_child(ped_inst)

	# High-voltage copper coil
	var coil = CylinderMesh.new()
	coil.top_radius = 0.28
	coil.bottom_radius = 0.28
	coil.height = 0.4
	var mat_coil = StandardMaterial3D.new()
	mat_coil.albedo_color = Color(0.85, 0.45, 0.15, 1.0)
	mat_coil.metallic = 0.95
	mat_coil.roughness = 0.2

	var coil_inst = MeshInstance3D.new()
	coil_inst.name = "CopperCoil"
	coil_inst.mesh = coil
	coil_inst.material_override = mat_coil
	coil_inst.position = Vector3(0, 1.5, 0)
	add_child(coil_inst)

	# Status indicator lamp
	var lamp = SphereMesh.new()
	lamp.radius = 0.12
	lamp.height = 0.24
	var mat_lamp = StandardMaterial3D.new()
	mat_lamp.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
	mat_lamp.emission_enabled = true
	mat_lamp.emission = Color(1.0, 0.1, 0.1, 1.0)
	mat_lamp.emission_energy_multiplier = 3.0

	lamp_mesh = MeshInstance3D.new()
	lamp_mesh.name = "StatusLamp"
	lamp_mesh.mesh = lamp
	lamp_mesh.material_override = mat_lamp
	lamp_mesh.position = Vector3(0, 1.9, 0)
	add_child(lamp_mesh)

	status_light = OmniLight3D.new()
	status_light.light_color = Color(1.0, 0.1, 0.1, 1.0)
	status_light.light_energy = 1.2
	status_light.omni_range = 3.5
	status_light.position = Vector3(0, 2.0, 0)
	add_child(status_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "[E] De-synchronize " + relay_name
	prompt_label.font_size = 18
	prompt_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	prompt_label.position = Vector3(0, 2.3, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not is_cycled and event.is_action_pressed("interact"):
		cycle_relay()

func interact(_player = null) -> void:
	cycle_relay()

func cycle_relay() -> void:
	if is_cycled:
		return
	is_cycled = true
	print("[DeadlockRelay] ", relay_name, " (", relay_id, ") DE-SYNCHRONIZED!")

	if lamp_mesh and lamp_mesh.material_override:
		var mat = lamp_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.1, 1.0, 0.5, 1.0)
		mat.emission = Color(0.1, 1.0, 0.5, 1.0)

	if status_light:
		status_light.light_color = Color(0.1, 1.0, 0.5, 1.0)
		status_light.light_energy = 2.0

	if prompt_label:
		prompt_label.text = "[ " + relay_name + " DE-SYNCHRONIZED ]"
		prompt_label.modulate = Color(0.2, 1.0, 0.4, 1.0)

	relay_cycled.emit(relay_id)

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
