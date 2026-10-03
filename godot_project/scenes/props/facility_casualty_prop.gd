extends Node3D
class_name FacilityCasualtyProp

# Sub-Routine Environmental Horror Prop: Deceased Facility Personnel
# Sparse human remains indicating prior trapped employees, torn clothing, severed limbs.
# Roxy can inspect their badges/datapads for environmental lore and scavenge rare generator components.

signal inspected(casualty_id: String)
signal component_scavenged(part_name: String)

@export_enum("slumped", "curled") var casualty_style: String = "slumped"
@export var casualty_id: String = ""
@export var technician_name: String = "Technician J. Miller (Systems Branch)"
@export_multiline var log_entry: String = "The blast doors locked from the outside... something is dragging metal through the ventilation ducts... my legs won't move..."
@export var holds_generator_part: String = "" # e.g. "generator_part_relay", "generator_part_fuse"

var is_in_range: bool = false
var has_been_searched: bool = false
var prompt_label: Label3D = null
var ambient_light: OmniLight3D = null
var datapad_mesh: MeshInstance3D = null
var datapad_mat: StandardMaterial3D = null
var time_passed: float = 0.0
var base_light_energy: float = 0.75
var light_col: Color = Color(0.3, 0.85, 0.4, 1.0) # Default phosphor green

func _ready() -> void:
	if casualty_id.is_empty():
		var pos = global_position if is_inside_tree() else position
		casualty_id = name + "_" + str(int(round(pos.x))) + "_" + str(int(round(pos.z)))
		
	# Setup mesh instance based on style
	var mesh_node = find_child("Model", true, false) as Node3D
	if not mesh_node:
		var glb_path = "res://assets/models/casualty_slumped_wall.glb"
		if casualty_style == "curled":
			glb_path = "res://assets/models/casualty_corner_curled.glb"
		if ResourceLoader.exists(glb_path):
			var scene_res = ResourceLoader.load(glb_path)
			if scene_res is PackedScene:
				var inst = scene_res.instantiate()
				inst.name = "Model"
				add_child(inst)

	_build_diegetic_lighting()

	# Interaction prompt floating above remains
	prompt_label = Label3D.new()
	prompt_label.text = "[E] SEARCH REMAINS"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.modulate = Color(0.9, 0.7, 0.4, 0.9)
	prompt_label.position = Vector3(0.0, 0.9, 0.2)
	prompt_label.visible = false
	add_child(prompt_label)

	var area = find_child("InteractArea", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_player_entered)
		area.body_exited.connect(_on_player_exited)

func _build_diegetic_lighting() -> void:
	# Determine color theme: holding key generator part vs standard lore casualty
	if not holds_generator_part.is_empty():
		light_col = Color(0.2, 0.85, 1.0, 1.0) # High-tech diagnostic cyan
		base_light_energy = 0.9
	else:
		# Alternate subtly between phosphor green and dying amber
		var hash_val = abs(casualty_id.hash())
		if hash_val % 2 == 0:
			light_col = Color(0.3, 0.85, 0.4, 1.0) # Phosphor CRT green
		else:
			light_col = Color(1.0, 0.65, 0.2, 1.0) # Dying cathode amber
		base_light_energy = 0.7

	# 1. Dropped industrial datapad / personnel badge on the floor beside remains
	var pad_mesh = BoxMesh.new()
	pad_mesh.size = Vector3(0.26, 0.025, 0.18)
	
	datapad_mat = StandardMaterial3D.new()
	datapad_mat.albedo_color = Color(0.12, 0.13, 0.15, 1.0)
	datapad_mat.roughness = 0.7
	datapad_mat.metallic = 0.4
	datapad_mat.emission_enabled = true
	datapad_mat.emission = light_col
	datapad_mat.emission_energy_multiplier = 2.4

	datapad_mesh = MeshInstance3D.new()
	datapad_mesh.name = "DroppedDatapad"
	datapad_mesh.mesh = pad_mesh
	datapad_mesh.material_override = datapad_mat
	datapad_mesh.position = Vector3(0.35, 0.02, 0.28)
	datapad_mesh.rotation.y = deg_to_rad(24.0)
	add_child(datapad_mesh)

	# 2. Ambient light casting subtle glow over corpse, floor, and bloodstains
	ambient_light = OmniLight3D.new()
	ambient_light.name = "CasualtyAmbientLight"
	ambient_light.light_color = light_col
	ambient_light.light_energy = base_light_energy
	ambient_light.omni_range = 4.4
	ambient_light.omni_attenuation = 1.8
	ambient_light.position = Vector3(0.35, 0.3, 0.28)
	add_child(ambient_light)

func _process(delta: float) -> void:
	if not ambient_light:
		return
	time_passed += delta
	# Subtle electronic flicker / scanline breathing
	var breath = sin(time_passed * 6.5) * 0.08
	var micro_jitter = (randf() - 0.5) * 0.04
	var dropout = 0.0
	if randf() < 0.007:
		dropout = -0.3 # Occasional screen flutter / scanline drop
	ambient_light.light_energy = clampf(base_light_energy + breath + micro_jitter + dropout, 0.15, 1.4)


func _on_player_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_player_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	inspected.emit(casualty_id)
	
	# Show lore dialog on HUD
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		var text = "[ %s ]\n\"%s\"" % [technician_name.to_upper(), log_entry]
		hud.display_overseer_message(text, "overseer_casualty_inspect")
	
	# Comment from Overseer
	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("casualty_inspect")
		
	# Scavenge component if present
	if not holds_generator_part.is_empty() and not has_been_searched:
		has_been_searched = true
		component_scavenged.emit(holds_generator_part)
		
		# Add to global inventory
		if is_inside_tree() and has_node("/root/LevelManager"):
			var lm = get_node("/root/LevelManager")
			if lm.has_method("add_generator_part"):
				lm.add_generator_part(holds_generator_part)
			elif "generator_parts" in lm and lm.generator_parts is Array:
				if not lm.generator_parts.has(holds_generator_part):
					lm.generator_parts.append(holds_generator_part)
				
		if datapad_mat:
			datapad_mat.emission = Color(0.2, 0.4, 0.2, 1.0)
			datapad_mat.emission_energy_multiplier = 0.8
		if ambient_light:
			base_light_energy = 0.45
			ambient_light.light_color = Color(0.3, 0.6, 0.3, 1.0)

		if hud and hud.has_method("update_objective"):
			var clean_part = holds_generator_part.replace("generator_part_", "").capitalize()
			hud.update_objective("Retrieved Generator Component: " + clean_part)
			
		if prompt_label:
			prompt_label.text = "[E] EXAMINE BADGE"
