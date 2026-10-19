extends Node3D
class_name Level17Sector

# Sector 17: Clinical Behavioral Sanatorium Wing (Act III Surface Transition)
# Closes off the subterranean server facility forever (Collapsed Elevator Shaft at North)
# and plunges Roxy into a blindingly lit clinical behavioral sanatorium.
# Features:
# - High-Pressure One-Way Mirror & X-Ray Lightbox Autopsy Puzzle:
#   Collect 3 Radiograph X-Ray Plates (Cranium, Thorax, Pelvis), mount them on the X-Ray Lightbox
#   to decode the Surgical Bone-Pin Sequence (4-9-2-7), and switch OFF the Lightbox before
#   Subject 04 smashes through the One-Way Observation Mirror (20s fracture countdown)!
# - Cross-Sector Persistent Item Foresight (Required in Sector 18 Vance Manor):
#   1. Bottle of Silver Nitrate Developer (silver_nitrate_developer) in Darkroom Storage
#   2. 440Hz Clinical Tuning Fork (clinical_tuning_fork_440) in Auditory Isolation Booths
#   3. Tarnished Serpent Half-Crest (serpent_half_crest) in Triage Patient Locker

const MIRROR_FRACTURE_DURATION: float = 20.0

var collected_xrays: Dictionary = {
	"xray_cranium": false,
	"xray_thorax": false,
	"xray_pelvis": false
}
var collected_manor_relics: Dictionary = {
	"silver_nitrate_developer": false,
	"clinical_tuning_fork_440": false,
	"serpent_half_crest": false
}

var is_subterranean_sealed_forever: bool = true
var is_lightbox_illuminated: bool = false
var is_bone_pin_code_decoded: bool = false
var is_mirror_shattered: bool = false
var is_oak_doors_unlatched: bool = false
var mirror_fracture_timer: float = MIRROR_FRACTURE_DURATION

@onready var collapsed_shaft_terminal: Node3D = find_child("CollapsedElevatorShaftTerminal", true, false)
@onready var xray_lightbox_console: Node3D = find_child("XRayLightboxConsole", true, false)
@onready var lightbox_kill_switch: Node3D = find_child("LightboxKillSwitch", true, false)
@onready var oak_doors_terminal: Node3D = find_child("SanatoriumOakDoorsTerminal", true, false)
@onready var one_way_mirror_mesh: MeshInstance3D = find_child("OneWayMirrorGlass", true, false)
@onready var lightbox_glow_light: OmniLight3D = find_child("Light_XRayLightbox", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitOakDoubleDoors", true, false)
@onready var exit_trigger: Area3D = find_child("Sector18ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_17] Clinical Behavioral Sanatorium Wing initialized. Subterranean shaft SEALED FOREVER.")

	# Sync any already-held surface relics from LevelManager
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("has_surface_relic"):
			for k in collected_xrays.keys():
				if lm.has_surface_relic(k):
					collected_xrays[k] = true
			for k in collected_manor_relics.keys():
				if lm.has_surface_relic(k):
					collected_manor_relics[k] = true

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("SUBTERRANEAN SHAFT COLLAPSED. Search the Clinic for 3 X-Ray Plates (0/3) & 3 Personal Artifacts (0/3).")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec17")

	# Connect all relic pickups
	var pickups_node = find_child("Pickups", true, false)
	if pickups_node:
		for child in pickups_node.get_children():
			if child.has_signal("relic_collected") and not child.is_connected("relic_collected", _on_relic_collected):
				child.connect("relic_collected", _on_relic_collected)

	if collapsed_shaft_terminal:
		if collapsed_shaft_terminal.has_signal("terminal_accessed") and not collapsed_shaft_terminal.is_connected("terminal_accessed", _on_collapsed_shaft_inspected):
			collapsed_shaft_terminal.connect("terminal_accessed", _on_collapsed_shaft_inspected)
		elif collapsed_shaft_terminal.has_signal("interacted") and not collapsed_shaft_terminal.is_connected("interacted", _on_collapsed_shaft_inspected):
			collapsed_shaft_terminal.connect("interacted", _on_collapsed_shaft_inspected)

	if xray_lightbox_console:
		if xray_lightbox_console.has_signal("terminal_accessed") and not xray_lightbox_console.is_connected("terminal_accessed", _on_xray_lightbox_interacted):
			xray_lightbox_console.connect("terminal_accessed", _on_xray_lightbox_interacted)
		elif xray_lightbox_console.has_signal("interacted") and not xray_lightbox_console.is_connected("interacted", _on_xray_lightbox_interacted):
			xray_lightbox_console.connect("interacted", _on_xray_lightbox_interacted)

	if lightbox_kill_switch:
		if lightbox_kill_switch.has_signal("relay_cycled") and not lightbox_kill_switch.is_connected("relay_cycled", _on_lightbox_kill_switch_pulled):
			lightbox_kill_switch.connect("relay_cycled", _on_lightbox_kill_switch_pulled)

	if oak_doors_terminal:
		if oak_doors_terminal.has_signal("terminal_accessed") and not oak_doors_terminal.is_connected("terminal_accessed", _on_oak_doors_terminal_accessed):
			oak_doors_terminal.connect("terminal_accessed", _on_oak_doors_terminal_accessed)
		elif oak_doors_terminal.has_signal("interacted") and not oak_doors_terminal.is_connected("interacted", _on_oak_doors_terminal_accessed):
			oak_doors_terminal.connect("interacted", _on_oak_doors_terminal_accessed)

func _process(delta: float) -> void:
	if is_lightbox_illuminated and not is_mirror_shattered and not is_oak_doors_unlatched:
		mirror_fracture_timer -= delta
		if mirror_fracture_timer <= 0.0:
			_trigger_mirror_breach()

func _on_collapsed_shaft_inspected(_user_data = null) -> void:
	print("[Level_17] Inspected collapsed subterranean elevator shaft.")
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ SUBTERRANEAN HOIST COLLAPSED — SEALED FOREVER ]\nThe hoist cables snapped at ground level. Sectors 01-16 are buried beneath 40 tons of bedrock. You can only move forward.",
			""
		)

func _on_relic_collected(r_id: String) -> void:
	if collected_xrays.has(r_id):
		collected_xrays[r_id] = true
		print("[Level_17] X-Ray Plate collected: ", r_id, " (", get_xray_plate_count(), "/3)")
	elif collected_manor_relics.has(r_id):
		collected_manor_relics[r_id] = true
		print("[Level_17] Cross-Sector Manor Relic collected: ", r_id, " (", get_manor_relic_count(), "/3)")

	# Also ensure LevelManager stores it even in unit tests outside SceneTree
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("add_surface_relic"):
			lm.add_surface_relic(r_id)

	_refresh_hud_objective()

func get_xray_plate_count() -> int:
	var c = 0
	for k in collected_xrays.keys():
		if collected_xrays[k]:
			c += 1
	return c

func get_manor_relic_count() -> int:
	var c = 0
	for k in collected_manor_relics.keys():
		if collected_manor_relics[k]:
			c += 1
	return c

func has_all_cross_sector_relics() -> bool:
	return get_manor_relic_count() >= 3

func _on_xray_lightbox_interacted(_user_data = null) -> void:
	var xcount = get_xray_plate_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if xcount < 3:
		print("[Level_17] X-Ray Lightbox requires 3 Radiograph Plates (currently ", xcount, "/3).")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ X-RAY AUTOPSY LIGHTBOX ]\n%d / 3 Radiograph Plates mounted. Collect Cranium (Triage), Thorax (Darkroom), and Pelvis (Auditory Booths)." % xcount,
				""
			)
		return

	if not is_lightbox_illuminated:
		set_lightbox_illuminated(true)
	else:
		set_lightbox_illuminated(false)

func _on_lightbox_kill_switch_pulled(_relay_id: String = "") -> void:
	set_lightbox_illuminated(false)

func set_lightbox_illuminated(active: bool) -> void:
	is_lightbox_illuminated = active
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if active:
		is_bone_pin_code_decoded = true
		mirror_fracture_timer = MIRROR_FRACTURE_DURATION
		print("[Level_17] X-Ray Lightbox ILLUMINATED! Surgical Bone-Pin Code 4-9-2-7 decoded! One-Way Mirror exposed (20s fracture countdown)!")
		if lightbox_glow_light:
			lightbox_glow_light.light_color = Color(1.0, 0.2, 0.25, 1.0)
			lightbox_glow_light.light_energy = 4.2
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ BONE-PIN CODE DECODED: 4 - 9 - 2 - 7 ]\nWARNING: Lightbox glare exposed the One-Way Mirror! Subject 04 is ramming the glass (20s)—shut off the Lightbox [E] NOW!",
				"overseer_mirror_breach_warning"
			)
		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("mirror_breach_warning")
	else:
		mirror_fracture_timer = MIRROR_FRACTURE_DURATION
		print("[Level_17] X-Ray Lightbox switched OFF! One-Way Mirror reflective state restored.")
		if lightbox_glow_light:
			lightbox_glow_light.light_color = Color(0.75, 0.92, 1.0, 1.0)
			lightbox_glow_light.light_energy = 1.2
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ LIGHTBOX DARKENED — ONE-WAY MIRROR RESTORED ]\nSubject 04 lost visual contact behind the mirror. Use Bone-Pin Code 4-9-2-7 at the South Oak Doors!",
				""
			)
	_refresh_hud_objective()

func _trigger_mirror_breach() -> void:
	if is_mirror_shattered:
		return
	is_mirror_shattered = true
	is_lightbox_illuminated = false
	print("[Level_17] ONE-WAY OBSERVATION MIRROR SHATTERED! Subject 04 breached into the ward!")
	if one_way_mirror_mesh:
		one_way_mirror_mesh.visible = false

	# Release Subject 04 Orderly into the main corridor
	var orderly = find_child("Subject04_SurgicalOrderly", true, false)
	if orderly and orderly is Node3D:
		orderly.position = Vector3(2.0, 0.5, 4.0)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ ONE-WAY MIRROR SHATTERED! ]\nYou left the X-Ray Lightbox on too long! Subject 04 has smashed through the observation glass!",
			""
		)

func _refresh_hud_objective() -> void:
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if not hud or not hud.has_method("update_objective"):
		return

	var xcount = get_xray_plate_count()
	var rcount = get_manor_relic_count()
	if not is_bone_pin_code_decoded:
		hud.update_objective("Collect X-Ray Plates (%d/3) & Manor Artifacts (%d/3), then inspect the X-Ray Lightbox [E]." % [xcount, rcount])
	elif is_lightbox_illuminated:
		hud.update_objective("DANGER: Switch OFF the X-Ray Lightbox [E] before Subject 04 shatters the One-Way Mirror!")
	elif rcount < 3:
		hud.update_objective("Bone-Pin Code 4-9-2-7 Decoded! Collect remaining Manor Artifacts (%d/3) before unsealing Oak Doors." % rcount)
	else:
		hud.update_objective("Code & All 3 Manor Artifacts Ready! Enter Bone-Pin Code at South Oak Double Doors [E].")

func _on_oak_doors_terminal_accessed(_user_data = null) -> void:
	if is_oak_doors_unlatched:
		return

	var rcount = get_manor_relic_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not is_bone_pin_code_decoded or rcount < 3:
		print("[Level_17] Oak Doors locked: Bone-Pin Decoded=", is_bone_pin_code_decoded, ", Manor Relics=", rcount, "/3")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ SANATORIUM OAK DOORS LOCKED ]\nRequires Surgical Bone-Pin Code from X-Ray Lightbox (%s) and all 3 Personal Artifacts (%d/3: Silver Nitrate, 440Hz Tuning Fork, Serpent Half-Crest)." % [
					"DECODED" if is_bone_pin_code_decoded else "LOCKED",
					rcount
				],
				""
			)
		return

	# Automatically shut off lightbox if still active when unlatching doors
	if is_lightbox_illuminated:
		is_lightbox_illuminated = false

	unlock_sector_18_manor_doors()

func unlock_sector_18_manor_doors() -> void:
	if is_oak_doors_unlatched:
		return
	is_oak_doors_unlatched = true
	print("[Level_17] Sanatorium Oak Double Doors UNLATCHED! Entering Sector 18: Vance Manor Grand Atrium.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ SANATORIUM OAK DOORS UNLATCHED ]\nBone-Pin Sequence 4-9-2-7 accepted. Step through the Oak Double Doors into Vance Manor!",
			"overseer_clinic_unsealed"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Step through the South Oak Double Doors into Sector 18: Vance Manor Grand Atrium.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("clinic_unsealed")
