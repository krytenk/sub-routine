extends Node3D
class_name WallMapPanelProp

# Sub-Routine Diegetic Wall Map Terminal
# Wall-mounted schematic display allowing players to view the architectural floor map
# and automatically recording a persistent checkpoint to browser IndexedDB storage.

signal map_terminal_accessed(sector_index: int)

@export var sector_index: int = 1
@export var prompt_message: String = "[E] Inspect Sector Blueprint"

var is_in_range: bool = false
var prompt_label: Label3D = null
var screen_mesh: MeshInstance3D = null
var panel_light: OmniLight3D = null

func _ready() -> void:
	_build_panel_visuals()
	_build_prompt()

	var area = Area3D.new()
	area.name = "InteractionArea"
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
	add_to_group("map_terminals")

func _build_panel_visuals() -> void:
	# Metal Wall Frame
	var frame = BoxMesh.new()
	frame.size = Vector3(1.6, 1.1, 0.1)
	var mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.12, 0.14, 0.18, 1.0)
	mat_frame.metallic = 0.9
	mat_frame.roughness = 0.35

	var frame_inst = MeshInstance3D.new()
	frame_inst.name = "Frame"
	frame_inst.mesh = frame
	frame_inst.material_override = mat_frame
	frame_inst.position = Vector3(0, 1.5, 0)
	add_child(frame_inst)

	# Schematic Display Screen
	var quad = QuadMesh.new()
	quad.size = Vector2(1.4, 0.9)
	var mat_screen = StandardMaterial3D.new()
	mat_screen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var map_path = "res://assets/textures/maps/sector_%02d_map.jpg" % sector_index
	if ResourceLoader.exists(map_path):
		var tex = ResourceLoader.load(map_path) as Texture2D
		mat_screen.albedo_texture = tex
	else:
		mat_screen.albedo_color = Color(0.1, 0.4, 0.6, 1.0)

	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "Screen"
	screen_mesh.mesh = quad
	screen_mesh.material_override = mat_screen
	screen_mesh.position = Vector3(0, 1.5, 0.06)
	add_child(screen_mesh)

	# Blue/Cyan Terminal Glow
	panel_light = OmniLight3D.new()
	panel_light.name = "PanelLight"
	panel_light.light_color = Color(0.2, 0.8, 0.95, 1.0)
	panel_light.light_energy = 0.9
	panel_light.omni_range = 3.5
	panel_light.position = Vector3(0, 1.5, 0.3)
	add_child(panel_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = prompt_message
	prompt_label.font_size = 18
	prompt_label.modulate = Color(0.2, 0.9, 1.0, 1.0)
	prompt_label.position = Vector3(0, 2.2, 0.1)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func interact(_player = null) -> void:
	print("[WallMapPanel] Player accessed Sector ", sector_index, " blueprint panel.")

	# Auto-save checkpoint to persistent storage
	if is_inside_tree() and has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game("Sector %02d Blueprint Station" % sector_index)

	# Open the MapViewerModal in HUD or Main
	var map_modal = null
	if is_inside_tree() and get_tree().root:
		map_modal = get_tree().root.find_child("MapViewerModal", true, false)

	if map_modal and map_modal.has_method("open_map"):
		map_modal.open_map(sector_index)
	elif is_inside_tree():
		# Instantiate modal directly onto viewport if not already present
		var modal_scene = load("res://scenes/ui/map_viewer_modal.tscn") as PackedScene
		if modal_scene:
			var inst = modal_scene.instantiate()
			get_tree().root.add_child(inst)
			if inst.has_method("open_map"):
				inst.open_map(sector_index)

	map_terminal_accessed.emit(sector_index)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player"):
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false
