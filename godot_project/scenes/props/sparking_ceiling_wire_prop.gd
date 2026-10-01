extends Node3D
class_name SparkingCeilingWireProp

# Sub-Routine Atmospheric Horror Prop: Sparking Ceiling Wire with Dynamic Shadows
# Simulates frayed industrial cables drooping from ceiling conduits above chamber thresholds.
# Intermittent high-voltage arc bursts cast dramatic flickering shadows across doorways and floors.

@export var door_label_text: String = ""
@export var door_label_color: Color = Color(1.0, 0.8, 0.4, 1.0)
@export var spark_color: Color = Color(0.65, 0.85, 1.0, 1.0)
@export var light_energy_peak: float = 5.2
@export var light_energy_base: float = 0.6
@export var light_range: float = 14.0
@export var min_interval: float = 1.8
@export var max_interval: float = 4.0

var broken_light: Node3D = null
var label_node: Label3D = null

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	# 1. Ceiling mount box
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.5, 0.25, 0.5)
	var box_mat = StandardMaterial3D.new()
	box_mat.albedo_color = Color(0.15, 0.16, 0.18, 1.0)
	box_mat.roughness = 0.8
	box_mesh.material = box_mat

	var box_inst = MeshInstance3D.new()
	box_inst.name = "CeilingMount"
	box_inst.mesh = box_mesh
	box_inst.position = Vector3(0.0, 3.5, 0.0)
	add_child(box_inst)

	# 2. Frayed cables dangling down
	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.08, 0.08, 0.1, 1.0)
	cable_mat.roughness = 0.9

	var copper_mat = StandardMaterial3D.new()
	copper_mat.albedo_color = Color(0.9, 0.5, 0.2, 1.0)
	copper_mat.emission_enabled = true
	copper_mat.emission = Color(1.0, 0.6, 0.2, 1.0)
	copper_mat.emission_energy_multiplier = 1.5

	var strand_offsets = [
		Vector3(-0.12, 0.0, -0.08),
		Vector3(0.05, 0.0, 0.10),
		Vector3(-0.06, 0.0, 0.08),
		Vector3(0.12, 0.0, -0.06)
	]
	var strand_lengths = [1.1, 1.35, 1.2, 1.45]

	for i in range(strand_offsets.size()):
		var length = strand_lengths[i]
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = 0.025
		cyl_mesh.bottom_radius = 0.02
		cyl_mesh.height = length
		cyl_mesh.radial_segments = 6
		cyl_mesh.material = cable_mat

		var strand_inst = MeshInstance3D.new()
		strand_inst.name = "Strand_%d" % i
		strand_inst.mesh = cyl_mesh
		# Position cylinder centered between mount and wire tip
		strand_inst.position = Vector3(strand_offsets[i].x, 3.5 - (length / 2.0), strand_offsets[i].z)
		strand_inst.rotation.z = deg_to_rad((i % 2 * 2 - 1) * 6.0)
		strand_inst.rotation.x = deg_to_rad(((i + 1) % 2 * 2 - 1) * 5.0)
		strand_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(strand_inst)

		# Exposed glowing wire tip
		var tip_mesh = SphereMesh.new()
		tip_mesh.radius = 0.03
		tip_mesh.height = 0.06
		tip_mesh.material = copper_mat

		var tip_inst = MeshInstance3D.new()
		tip_inst.name = "Tip_%d" % i
		tip_inst.mesh = tip_mesh
		tip_inst.position = Vector3(strand_offsets[i].x, 3.5 - length, strand_offsets[i].z)
		add_child(tip_inst)

	# 3. Broken electronics light controller (SPARK_BURST with shadows)
	var light_script = load("res://scripts/props/broken_electronics_light.gd")
	if light_script:
		broken_light = Node3D.new()
		broken_light.name = "BrokenLight"
		broken_light.set_script(light_script)
		broken_light.set("mode", 0) # LightMode.SPARK_BURST
		broken_light.set("base_color", spark_color)
		broken_light.set("base_energy", light_energy_base)
		broken_light.set("peak_energy", light_energy_peak)
		broken_light.set("light_range", light_range)
		broken_light.set("enable_shadows", true)
		broken_light.set("min_spark_interval", min_interval)
		broken_light.set("max_spark_interval", max_interval)
		broken_light.position = Vector3(0.0, 2.1, 0.0)
		add_child(broken_light)

	# 4. Optional illuminated doorway header sign
	if not door_label_text.is_empty():
		label_node = Label3D.new()
		label_node.name = "DoorwaySign"
		label_node.text = door_label_text
		label_node.font_size = 28
		label_node.outline_size = 6
		label_node.outline_modulate = Color(0, 0, 0, 0.9)
		label_node.modulate = door_label_color
		label_node.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		label_node.position = Vector3(0.0, 3.0, 0.15)
		add_child(label_node)
