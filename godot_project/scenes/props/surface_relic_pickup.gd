extends Node3D
class_name SurfaceRelicPickupProp

# Persistent Cross-Sector Relic & Puzzle Item Pickup (Sectors 17 & 18+)
# Stores relic_id in LevelManager.surface_relics so items scavenged in the
# Clinical Behavioral Sanatorium Wing (Sector 17) carry forward into
# Vance Manor (Sector 18) and beyond.

signal relic_collected(relic_id: String)

@export var relic_id: String = "silver_nitrate_developer"
@export var relic_name: String = "Bottle of Silver Nitrate Developer"
@export var relic_description: String = "Clinical darkroom reagent. May develop unexposed glass plates in the Manor above."
@export var relic_color: Color = Color(0.95, 0.82, 0.28, 1.0)

var collected: bool = false
var is_in_range: bool = false
var prompt_label: Label3D = null
var relic_light: OmniLight3D = null
var mesh_anchor: Node3D = null

func _ready() -> void:
	# If this relic was already collected in a previous visit/checkpoint, hide it
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("has_surface_relic") and lm.has_surface_relic(relic_id):
			collected = true
			visible = false
			return

	_build_visuals()
	_build_prompt()

	var area = Area3D.new()
	area.name = "Area3D"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.8, 1.8, 1.8)
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
	mesh_anchor.name = "RelicMeshAnchor"
	add_child(mesh_anchor)

	var prism_mesh = BoxMesh.new()
	prism_mesh.size = Vector3(0.24, 0.28, 0.14)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = relic_color
	mat.metallic = 0.85
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = relic_color
	mat.emission_energy_multiplier = 2.6

	var inst = MeshInstance3D.new()
	inst.name = "RelicMesh"
	inst.mesh = prism_mesh
	inst.material_override = mat
	mesh_anchor.add_child(inst)

	relic_light = OmniLight3D.new()
	relic_light.light_color = relic_color
	relic_light.light_energy = 1.3
	relic_light.omni_range = 3.0
	mesh_anchor.add_child(relic_light)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "[E] Collect " + relic_name
	prompt_label.font_size = 18
	prompt_label.modulate = relic_color.lightened(0.25)
	prompt_label.position = Vector3(0, 0.55, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.visible = false
	add_child(prompt_label)

func _process(delta: float) -> void:
	if mesh_anchor and not collected:
		mesh_anchor.rotate_y(delta * 1.8)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and not collected and event.is_action_pressed("interact"):
		collect()

func interact(_player = null) -> void:
	collect()

func collect() -> void:
	if collected:
		return
	collected = true
	print("[SurfaceRelicPickup] Collected relic: ", relic_id, " (", relic_name, ")")

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("add_surface_relic"):
			lm.add_surface_relic(relic_id)

	if is_inside_tree() and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("sfx_part_pickup")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ ARTIFACT ACQUIRED: %s ]\n%s" % [relic_name.to_upper(), relic_description],
			""
		)

	relic_collected.emit(relic_id)
	visible = false
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
