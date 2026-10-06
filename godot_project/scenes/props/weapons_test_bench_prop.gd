extends Node3D
class_name WeaponsTestBenchProp

# Weapons Test-Bench Prop - Sector 07 Ordnance Proving Bay
# Multi-module assembly station for the Hyper-Flux Singularity Cannon prototype.
# Requires: Magnetron Emitter Core, Cryo-Stabilizer Capsule, Targeting Matrix Key.

signal weapon_assembled

var installed_parts: Array = []
var is_weapon_armed: bool = false
var status_label: Label3D = null
var bench_light: OmniLight3D = null

func _ready() -> void:
	_build_visuals()
	_update_status_display()
	add_to_group("interactive_props")
	add_to_group("test_benches")

func _build_visuals() -> void:
	# Heavy industrial workbench table
	var table_body = StaticBody3D.new()
	table_body.collision_layer = 5
	table_body.collision_mask = 0
	add_child(table_body)

	var table_shape = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(2.4, 0.9, 1.4)
	table_shape.shape = box_col
	table_shape.position = Vector3(0.0, 0.45, 0.0)
	table_body.add_child(table_shape)

	var table_mesh = MeshInstance3D.new()
	var box_m = BoxMesh.new()
	box_m.size = Vector3(2.4, 0.9, 1.4)
	table_mesh.mesh = box_m
	var mat_table = StandardMaterial3D.new()
	mat_table.albedo_color = Color(0.18, 0.2, 0.24, 1.0)
	mat_table.metallic = 0.85
	mat_table.roughness = 0.4
	table_mesh.material_override = mat_table
	table_mesh.position = Vector3(0.0, 0.45, 0.0)
	table_body.add_child(table_mesh)

	# Cannon mounting cradle & weapon chassis
	var cannon_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.16
	cyl.height = 1.6
	cannon_mesh.mesh = cyl
	var mat_gun = StandardMaterial3D.new()
	mat_gun.albedo_color = Color(0.8, 0.45, 0.1, 1.0)
	mat_gun.metallic = 0.95
	mat_gun.roughness = 0.15
	cannon_mesh.material_override = mat_gun
	cannon_mesh.rotation.z = deg_to_rad(90.0)
	cannon_mesh.position = Vector3(0.0, 1.05, 0.0)
	add_child(cannon_mesh)

	# OmniLight3D
	bench_light = OmniLight3D.new()
	bench_light.light_color = Color(1.0, 0.65, 0.15, 1.0)
	bench_light.light_energy = 2.0
	bench_light.omni_range = 6.0
	bench_light.position = Vector3(0.0, 1.3, 0.0)
	add_child(bench_light)

	# Status billboard
	status_label = Label3D.new()
	status_label.font_size = 20
	status_label.outline_size = 6
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.position = Vector3(0.0, 1.7, 0.0)
	add_child(status_label)

func _update_status_display() -> void:
	if not status_label:
		return
	if is_weapon_armed:
		status_label.text = "« HYPER-FLUX SINGULARITY CANNON »\n[ WEAPON ARMED & PRIMED FOR DISCHARGE ]"
		status_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
		if bench_light:
			bench_light.light_color = Color(1.0, 0.85, 0.2, 1.0)
			bench_light.light_energy = 4.0
	else:
		var count = installed_parts.size()
		status_label.text = "« WEAPONS PROVING TEST-BENCH »\nModules Linked: [%d/3]\n[E] INSTALL SCAVENGED COMPONENTS" % count
		status_label.modulate = Color(0.3, 0.85, 1.0, 1.0)

func interact(player: CharacterBody3D = null) -> void:
	if is_weapon_armed:
		return

	var lm = null
	if is_inside_tree() and has_node("/root/LevelManager"):
		lm = get_node("/root/LevelManager")

	var available_parts = []
	if lm and "singularity_parts" in lm:
		available_parts = lm.singularity_parts

	var required = ["singularity_magnetron", "singularity_cryo", "singularity_key"]
	var installed_any = false

	for part in required:
		if available_parts.has(part) and not installed_parts.has(part):
			installed_parts.append(part)
			installed_any = true
			print("[WeaponsTestBench] Installed component: ", part)

	if installed_parts.size() >= 3 and not is_weapon_armed:
		_complete_assembly(player)
	else:
		_update_status_display()
		if not installed_any:
			var hud = null
			if is_inside_tree() and get_tree().root:
				hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("display_overseer_message"):
				var missing = 3 - installed_parts.size()
				hud.display_overseer_message(
					"[ TEST-BENCH OFFLINE: MISSING %d MODULES ]\nExplore Laser Lab, Cryo-Sump, and Research Corpses via air ducts." % missing
				)

func _complete_assembly(player: CharacterBody3D = null) -> void:
	is_weapon_armed = true
	_update_status_display()
	print("[WeaponsTestBench] SINGULARITY CANNON ASSEMBLY COMPLETE!")

	var p = player
	if not p and is_inside_tree() and get_tree().root:
		p = get_tree().root.find_child("RoxyVance", true, false) as CharacterBody3D

	if p and p.has_method("equip_superweapon"):
		p.equip_superweapon()

	var hud = null
	if is_inside_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ PROTOTYPE SUPERWEAPON PRIMED ]\nHyper-Flux Singularity Cannon armed! Ready to penetrate Goliath Core.",
			"overseer_emp_success"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter Central Blast Core. Destroy Arch-Compiler Goliath with Singularity Cannon.")

	weapon_assembled.emit()
