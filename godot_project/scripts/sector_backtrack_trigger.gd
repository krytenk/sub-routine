extends Area3D
class_name SectorBacktrackTrigger

# Sector Backtracking Trigger
# Allows player to step backwards into previously cleared sectors to scavenge respawned supplies.
# Features spawn grace period to prevent immediate loop trigger upon loading a sector.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

@export var target_level_index: int = 1
@export var grace_period: float = 2.5

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visuals()

func _build_visuals() -> void:
	# Overhead transit gate label
	var sign_label = Label3D.new()
	sign_label.name = "BacktrackSign"
	sign_label.text = "« RETROGRADE GATEWAY // SECTOR 0" + str(target_level_index) + " »\n[ RETREAT TO PREVIOUS SECTOR ]"
	sign_label.font_size = 26
	sign_label.outline_size = 8
	sign_label.modulate = Color(1.0, 0.72, 0.15, 1.0)
	sign_label.outline_modulate = Color(0.1, 0.03, 0.0, 0.95)
	sign_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign_label.position = Vector3(0.0, 1.4, 0.0)
	add_child(sign_label)

	# Amber warning light
	var caution_light = OmniLight3D.new()
	caution_light.name = "CautionLight"
	caution_light.light_color = Color(1.0, 0.65, 0.15)
	caution_light.light_energy = 1.2
	caution_light.omni_range = 6.0
	caution_light.position = Vector3(0.0, 1.6, 0.0)
	add_child(caution_light)

	# Bulkhead frame mesh
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(3.8, 0.15, 0.25)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.22)
	mat.metallic = 0.8
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.25, 0.05)
	mat.emission_energy_multiplier = 0.5

	var header = MeshInstance3D.new()
	header.name = "GateHeaderMesh"
	header.mesh = frame_mesh
	header.material_override = mat
	header.position = Vector3(0.0, 1.65, 0.0)
	add_child(header)

func _process(delta: float) -> void:
	if grace_period > 0.0:
		grace_period -= delta

func _on_body_entered(body: Node3D) -> void:
	if grace_period > 0.0 or has_triggered:
		return
	if not (body is RoxyVance or body.is_in_group("player")):
		return

	has_triggered = true
	print("[SectorBacktrackTrigger] Backtracking to Sector ", target_level_index)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"backtrack_hint",
			"Retreating to previous sectors? You can scavenge respawned nanites, but the complex doesn't forget where you've been."
		)

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		get_tree().create_timer(0.2).timeout.connect(func():
			if lm.has_method("backtrack_to_level"):
				lm.backtrack_to_level(target_level_index)
			else:
				lm.load_level(target_level_index)
		)
