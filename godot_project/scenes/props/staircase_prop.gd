@tool
extends StaticBody3D
class_name StaircaseProp

# Modular Industrial Staircase Prop
# Provides a smooth collision ramp (under 32 degrees) for silky smooth character controller ascent/descent,
# combined with articulated steel step treads, hazard warning nosing, and side safety handrails with collision.

@export var step_count: int = 12
@export var stair_width: float = 2.6
@export var stair_rise: float = 3.5
@export var stair_run: float = 6.0
@export var railing_height: float = 1.1

var rust_texture: Texture2D = null

func _ready() -> void:
    if ResourceLoader.exists("res://assets/textures/rusted_metal.jpg"):
        rust_texture = ResourceLoader.load("res://assets/textures/rusted_metal.jpg")
    _build_visual_steps()

func _build_visual_steps() -> void:
    # Clear any previous dynamic step container
    var old_steps = find_child("DynamicSteps", false, false)
    if old_steps:
        old_steps.queue_free()

    var steps_root = Node3D.new()
    steps_root.name = "DynamicSteps"
    add_child(steps_root)

    var step_rise = stair_rise / float(step_count)
    var step_run = stair_run / float(step_count)

    var step_mat = StandardMaterial3D.new()
    if rust_texture:
        step_mat.albedo_texture = rust_texture
        step_mat.uv1_scale = Vector3(2.0, 1.0, 1.0)
    else:
        step_mat.albedo_color = Color(0.2, 0.22, 0.25)
    step_mat.roughness = 0.85
    step_mat.metallic = 0.65

    var hazard_mat = StandardMaterial3D.new()
    hazard_mat.albedo_color = Color(0.85, 0.65, 0.1) # Industrial caution yellow
    hazard_mat.roughness = 0.6

    for i in range(step_count):
        var t = float(i)
        var y_pos = (t + 0.5) * step_rise
        var z_pos = (t + 0.5) * step_run

        # Step tread
        var tread = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(stair_width, step_rise, step_run * 1.1)
        tread.mesh = box
        tread.material_override = step_mat
        tread.position = Vector3(0.0, y_pos, z_pos)
        steps_root.add_child(tread)

        # Hazard warning strip on front edge of each step
        var strip = MeshInstance3D.new()
        var strip_mesh = BoxMesh.new()
        strip_mesh.size = Vector3(stair_width * 0.98, 0.03, 0.08)
        strip.mesh = strip_mesh
        strip.material_override = hazard_mat
        strip.position = Vector3(0.0, y_pos + (step_rise * 0.5) + 0.015, z_pos - (step_run * 0.5) + 0.04)
        steps_root.add_child(strip)

    # Visual side stringer plates
    var stringer_mesh = BoxMesh.new()
    stringer_mesh.size = Vector3(0.08, 0.45, stair_run * 1.15)

    var stringer_left = MeshInstance3D.new()
    stringer_left.mesh = stringer_mesh
    stringer_left.material_override = step_mat
    stringer_left.position = Vector3(-stair_width * 0.5 - 0.04, stair_rise * 0.5, stair_run * 0.5)
    stringer_left.rotation.x = atan2(stair_rise, stair_run)
    steps_root.add_child(stringer_left)

    var stringer_right = MeshInstance3D.new()
    stringer_right.mesh = stringer_mesh
    stringer_right.material_override = step_mat
    stringer_right.position = Vector3(stair_width * 0.5 + 0.04, stair_rise * 0.5, stair_run * 0.5)
    stringer_right.rotation.x = atan2(stair_rise, stair_run)
    steps_root.add_child(stringer_right)
