extends Node3D
class_name EmpUpgradePickupProp

# Sub-Routine EMP Upgrade Component Pickup: Dielectric Capacitor Core
# Upgrades Roxy's EMP Discharger to higher MK tiers, expanding radius, damage, and reducing cooldown.

signal upgrade_collected(new_tier: int)

@export var upgrade_level_target: int = 2
@export var upgrade_id: String = "emp_capacitor_mk2"

var collected: bool = false
var audio_player: AudioStreamPlayer = null
var prompt_label: Label3D = null
var capacitor_light: OmniLight3D = null
var start_y: float = 0.0
var is_in_range: bool = false

func _ready() -> void:
	start_y = position.y
	
	# If player has already acquired this upgrade tier, destroy pickup
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if "emp_upgrade_level" in lm and lm.emp_upgrade_level >= upgrade_level_target:
			queue_free()
			return

	_build_capacitor_visuals()
	_build_audio()
	_build_prompt()

	var area = find_child("Area3D", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	add_to_group("interactive_props")
	add_to_group("emp_upgrades")
	add_to_group("pickups")

func _build_capacitor_visuals() -> void:
	var root_anchor = Node3D.new()
	root_anchor.name = "CapacitorMeshAnchor"
	add_child(root_anchor)

	# Outer cylindrical dielectric housing
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.18
	cyl.height = 0.45

	var mat_housing = StandardMaterial3D.new()
	mat_housing.albedo_color = Color(0.12, 0.14, 0.18, 1.0)
	mat_housing.metallic = 0.85
	mat_housing.roughness = 0.25

	var cyl_mesh = MeshInstance3D.new()
	cyl_mesh.name = "Housing"
	cyl_mesh.mesh = cyl
	cyl_mesh.material_override = mat_housing
	cyl_mesh.position = Vector3(0.0, 0.25, 0.0)
	root_anchor.add_child(cyl_mesh)

	# Glowing cyan energy dielectric coil ring
	var torus = TorusMesh.new()
	torus.inner_radius = 0.19
	torus.outer_radius = 0.24

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = Color(0.2, 0.9, 1.0, 1.0)
	mat_glow.emission_enabled = true
	mat_glow.emission = Color(0.2, 0.9, 1.0, 1.0)
	mat_glow.emission_energy_multiplier = 4.0

	var ring1 = MeshInstance3D.new()
	ring1.name = "EnergyRing1"
	ring1.mesh = torus
	ring1.material_override = mat_glow
	ring1.position = Vector3(0.0, 0.32, 0.0)
	root_anchor.add_child(ring1)

	var ring2 = MeshInstance3D.new()
	ring2.name = "EnergyRing2"
	ring2.mesh = torus
	ring2.material_override = mat_glow
	ring2.position = Vector3(0.0, 0.18, 0.0)
	root_anchor.add_child(ring2)

	# High-frequency electrode tips
	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	tip_mat.metallic = 1.0
	tip_mat.roughness = 0.1

	var tip = BoxMesh.new()
	tip.size = Vector3(0.06, 0.15, 0.06)

	var tip_top = MeshInstance3D.new()
	tip_top.name = "CathodeTip"
	tip_top.mesh = tip
	tip_top.material_override = tip_mat
	tip_top.position = Vector3(0.0, 0.52, 0.0)
	root_anchor.add_child(tip_top)

	# Radiant cyan OmniLight3D
	capacitor_light = OmniLight3D.new()
	capacitor_light.name = "CapacitorLight"
	capacitor_light.light_color = Color(0.25, 0.9, 1.0, 1.0)
	capacitor_light.light_energy = 2.4
	capacitor_light.omni_range = 6.5
	capacitor_light.omni_attenuation = 1.6
	capacitor_light.position = Vector3(0.0, 0.35, 0.0)
	add_child(capacitor_light)

func _build_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioPlayer"
	audio_player.bus = "Master"
	add_child(audio_player)
	var sound_path = "res://assets/audio/sfx/sfx_part_pickup.wav"
	if ResourceLoader.exists(sound_path):
		audio_player.stream = ResourceLoader.load(sound_path)

func _build_prompt() -> void:
	prompt_label = Label3D.new()
	var tier_name = "MK II" if upgrade_level_target == 2 else "MK III"
	prompt_label.text = "[E] UPGRADE EMP DISCHARGER\n[ Dielectric Capacitor Core %s ]" % tier_name
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 20
	prompt_label.modulate = Color(0.3, 0.9, 1.0, 0.95)
	prompt_label.outline_modulate = Color(0.02, 0.15, 0.25, 0.95)
	prompt_label.outline_size = 6
	prompt_label.position = Vector3(0.0, 0.75, 0.0)
	prompt_label.visible = false
	add_child(prompt_label)

func _process(delta: float) -> void:
	if collected:
		return
	var t = Time.get_ticks_msec() / 1000.0
	position.y = start_y + sin(t * 2.5) * 0.06
	rotate_y(delta * 1.5)

	if capacitor_light:
		capacitor_light.light_energy = 2.2 + sin(t * 4.0) * 0.5

func interact(player: CharacterBody3D = null) -> void:
	if collected:
		return
	collect(player)

func collect(player: CharacterBody3D = null) -> void:
	if collected:
		return
	collected = true
	print("[EmpUpgradePickup] Dielectric Capacitor collected! Target MK: ", upgrade_level_target)

	var p = player
	if not p and is_inside_tree() and get_tree().root:
		p = get_tree().root.find_child("RoxyVance", true, false) as CharacterBody3D

	var new_lvl = upgrade_level_target
	if p and p.has_method("upgrade_emp"):
		new_lvl = p.upgrade_emp(upgrade_level_target)
	elif is_inside_tree() and has_node("/root/LevelManager"):
		get_node("/root/LevelManager").emp_upgrade_level = upgrade_level_target

	# HUD message
	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		var roman = "II"
		var stats_desc = "Dielectric Core | Cooldown: 5.5s | Radius: 11.0m"
		match upgrade_level_target:
			2:
				roman = "II"
				stats_desc = "Dielectric Core | Cooldown: 5.5s | Radius: 11.0m"
			3:
				roman = "III"
				stats_desc = "Singularity Core | Cooldown: 3.5s | Radius: 14.5m"
			4:
				roman = "IV"
				stats_desc = "Sub-Harmonic Inductor | Cooldown: 2.2s | Radius: 18.0m"
			5:
				roman = "V"
				stats_desc = "Zero-Point Resonant Core | Cooldown: 1.2s | Radius: 22.0m"
		hud.display_overseer_message(
			"[ EMP DISCHARGER UPGRADED: MK %s ]\n%s" % [roman, stats_desc],
			"overseer_emp_upgraded"
		)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		var ov = get_node("/root/TheOverseer")
		if upgrade_level_target == 4:
			ov.trigger_dialogue("emp_mk4")
		elif upgrade_level_target == 5:
			ov.trigger_dialogue("emp_mk5")
		else:
			ov.trigger_dialogue("emp_upgraded")

	if audio_player and audio_player.stream:
		audio_player.play()

	upgrade_collected.emit(new_lvl)
	hide()
	if is_inside_tree() and get_tree():
		get_tree().create_timer(1.2).timeout.connect(func():
			queue_free()
		)
	else:
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
