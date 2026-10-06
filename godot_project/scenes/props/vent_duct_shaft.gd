extends Node3D
class_name VentDuctShaftProp

# Sub-Routine Ventilation Duct System
# Low-clearance (1.2m x 1.1m) overhead duct network allowing Roxy to crawl
# above lethal patrol zones, peek through floor grates, and access secured research wings.

@export var length: float = 8.0
@export var has_floor_grate: bool = false
@export var grate_label: String = "TRENCH FLOOR // DREDGE TITAN PATROL BELOW"

@onready var duct_area: Area3D = find_child("DuctInteriorArea", true, false)

func _ready() -> void:
	_build_duct_geometry()
	if duct_area:
		duct_area.body_entered.connect(_on_duct_body_entered)
		duct_area.body_exited.connect(_on_duct_body_exited)

func _build_duct_geometry() -> void:
	var rust_tex = null
	if ResourceLoader.exists("res://assets/textures/rusted_metal.jpg"):
		rust_tex = ResourceLoader.load("res://assets/textures/rusted_metal.jpg")

	var mat_duct = StandardMaterial3D.new()
	mat_duct.albedo_color = Color(0.35, 0.38, 0.42, 1.0)
	if rust_tex:
		mat_duct.albedo_texture = rust_tex
		mat_duct.uv1_scale = Vector3(2.0, length * 0.5, 1.0)
		mat_duct.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_duct.metallic = 0.8
	mat_duct.roughness = 0.45

	var mat_grate = StandardMaterial3D.new()
	mat_grate.albedo_color = Color(0.2, 0.22, 0.25, 0.65)
	mat_grate.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_grate.metallic = 0.9
	mat_grate.roughness = 0.2

	# Floor
	var floor_body = StaticBody3D.new()
	floor_body.name = "FloorCol"
	add_child(floor_body)

	var floor_shape = CollisionShape3D.new()
	var box_floor = BoxShape3D.new()
	box_floor.size = Vector3(1.4, 0.1, length)
	floor_shape.shape = box_floor
	floor_shape.position = Vector3(0.0, -0.05, 0.0)
	floor_body.add_child(floor_shape)

	var floor_mesh = MeshInstance3D.new()
	var mesh_floor = BoxMesh.new()
	mesh_floor.size = Vector3(1.4, 0.1, length)
	floor_mesh.mesh = mesh_floor
	floor_mesh.material_override = mat_grate if has_floor_grate else mat_duct
	floor_mesh.position = Vector3(0.0, -0.05, 0.0)
	floor_body.add_child(floor_mesh)

	# Left Wall
	var wall_l_body = StaticBody3D.new()
	add_child(wall_l_body)
	var col_l = CollisionShape3D.new()
	var box_wall = BoxShape3D.new()
	box_wall.size = Vector3(0.1, 1.2, length)
	col_l.shape = box_wall
	col_l.position = Vector3(-0.65, 0.55, 0.0)
	wall_l_body.add_child(col_l)

	var mesh_l = MeshInstance3D.new()
	var box_mesh_w = BoxMesh.new()
	box_mesh_w.size = Vector3(0.1, 1.2, length)
	mesh_l.mesh = box_mesh_w
	mesh_l.material_override = mat_duct
	mesh_l.position = Vector3(-0.65, 0.55, 0.0)
	wall_l_body.add_child(mesh_l)

	# Right Wall
	var wall_r_body = StaticBody3D.new()
	add_child(wall_r_body)
	var col_r = CollisionShape3D.new()
	col_r.shape = box_wall
	col_r.position = Vector3(0.65, 0.55, 0.0)
	wall_r_body.add_child(col_r)

	var mesh_r = MeshInstance3D.new()
	mesh_r.mesh = box_mesh_w
	mesh_r.material_override = mat_duct
	mesh_r.position = Vector3(0.65, 0.55, 0.0)
	wall_r_body.add_child(mesh_r)

	# Ceiling (limits player to crouch/crawl height)
	var ceil_body = StaticBody3D.new()
	add_child(ceil_body)
	var col_ceil = CollisionShape3D.new()
	col_ceil.shape = box_floor
	col_ceil.position = Vector3(0.0, 1.15, 0.0)
	ceil_body.add_child(col_ceil)

	var mesh_ceil = MeshInstance3D.new()
	mesh_ceil.mesh = mesh_floor
	mesh_ceil.material_override = mat_duct
	mesh_ceil.position = Vector3(0.0, 1.15, 0.0)
	ceil_body.add_child(mesh_ceil)

	# If this section has a floor grate viewing downward
	if has_floor_grate:
		var grate_view = Label3D.new()
		grate_view.text = "« " + grate_label + " »"
		grate_view.font_size = 18
		grate_view.modulate = Color(1.0, 0.45, 0.2, 0.9)
		grate_view.outline_modulate = Color(0.1, 0.02, 0.0, 0.95)
		grate_view.outline_size = 4
		grate_view.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		grate_view.position = Vector3(0.0, 0.15, 0.0)
		add_child(grate_view)

func _on_duct_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("set_in_duct"):
		body.set_in_duct(true)

func _on_duct_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("set_in_duct"):
		body.set_in_duct(false)
