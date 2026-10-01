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
			if not "generator_parts" in lm:
				lm.set("generator_parts", [])
			var parts: Array = lm.get("generator_parts")
			if not parts.has(holds_generator_part):
				parts.append(holds_generator_part)
				
		if hud and hud.has_method("update_objective"):
			var clean_part = holds_generator_part.replace("generator_part_", "").capitalize()
			hud.update_objective("Retrieved Generator Component: " + clean_part)
			
		if prompt_label:
			prompt_label.text = "[E] EXAMINE BADGE"
