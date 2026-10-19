extends Node3D
class_name Level12Sector

# Sector 12: Sub-Routine Core Threshold & Kernel Rotunda (Act I Boss Encounter)
# Climactic multi-phase boss arena where Roxy Vance confronts the Kernel Warden (Overseer Avatar).
# Features:
# - Central Overseer Kernel Rotunda flanked by West, East, and South-Central Harmonic Cooling Pylon Alcoves
# - Multi-Phase Boss Fight: Overload 3 Harmonic Cooling Pylons [E] to shatter the Warden's Phase-Shield,
#   then unleash MK V Zero-Point EMP Pulses [F] to destroy its exposed Kernel Core!
# - Automatic purge of remaining arena escort threads upon Kernel Collapse
# - South Surface Ascension Lift unlocking Act I completion & Roll Credits

var overloaded_pylons: Dictionary = {
	"pylon_west": false,
	"pylon_east": false,
	"pylon_south": false
}
var is_boss_defeated: bool = false
var is_ascension_unlocked: bool = false
var phase2_announced: bool = false

@onready var kernel_warden: CharacterBody3D = find_child("KernelWardenBoss", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector12AscensionExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_12] Sub-Routine Core Threshold (Act I Boss Arena) initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("BOSS: Overload 3 Harmonic Cooling Pylons [E] (0/3) to shatter the Kernel Warden's Phase-Shield!")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec12")

	var pylons = [
		find_child("HarmonicPylon_West", true, false),
		find_child("HarmonicPylon_East", true, false),
		find_child("HarmonicPylon_South", true, false)
	]
	for p in pylons:
		if p:
			if p.has_signal("relay_cycled") and not p.is_connected("relay_cycled", _on_pylon_overloaded):
				p.connect("relay_cycled", _on_pylon_overloaded)
			elif p.has_signal("relay_synchronized") and not p.is_connected("relay_synchronized", _on_pylon_overloaded):
				p.connect("relay_synchronized", _on_pylon_overloaded)

	if kernel_warden:
		if kernel_warden.has_signal("boss_defeated"):
			if not kernel_warden.is_connected("boss_defeated", _on_boss_defeated):
				kernel_warden.connect("boss_defeated", _on_boss_defeated)
		if kernel_warden.has_signal("phase_shield_shattered"):
			if not kernel_warden.is_connected("phase_shield_shattered", _on_phase_shield_shattered):
				kernel_warden.connect("phase_shield_shattered", _on_phase_shield_shattered)

func _on_pylon_overloaded(pylon_id: String) -> void:
	if overloaded_pylons.get(pylon_id, false):
		return
	overloaded_pylons[pylon_id] = true
	var count = get_overloaded_pylon_count()
	print("[Level_12] Harmonic Cooling Pylon OVERLOADED: ", pylon_id, " (", count, "/3)")

	if kernel_warden and is_instance_valid(kernel_warden) and kernel_warden.has_method("apply_pylon_overload_surge"):
		kernel_warden.apply_pylon_overload_surge()

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not phase2_announced:
		phase2_announced = true
		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("boss_phase2")

	if count < 3:
		if hud and hud.has_method("update_objective"):
			hud.update_objective("Harmonic Cooling Pylons Overloaded (%d/3)! Overload remaining pylons to shatter Phase-Shield." % count)
	else:
		_on_phase_shield_shattered()

func get_overloaded_pylon_count() -> int:
	var c = 0
	for k in overloaded_pylons.keys():
		if overloaded_pylons[k]:
			c += 1
	return c

func _on_phase_shield_shattered() -> void:
	print("[Level_12] Kernel Warden Phase-Shield shattered! Boss vulnerable to full MK V EMP resonance!")
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ PHASE-SHIELD SHATTERED! ]\nKernel Core exposed! Discharge MK V EMP Pulses [F] near the Kernel Warden to destroy it!",
			""
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("PHASE-SHIELD DOWN! Discharge MK V EMP Pulses [F] into the Kernel Warden to destroy it!")

func _on_boss_defeated() -> void:
	if is_boss_defeated:
		return
	is_boss_defeated = true
	is_ascension_unlocked = true
	print("[Level_12] KERNEL WARDEN DEFEATED! Unlocking South Surface Ascension Lift.")

	# Purge remaining security minions in the rotunda from the core collapse shockwave
	var enemies_node = find_child("Enemies", true, false)
	if enemies_node:
		for child in enemies_node.get_children():
			if child != kernel_warden and is_instance_valid(child):
				if child.has_method("take_damage"):
					child.take_damage(999, "superweapon")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.4, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ KERNEL WARDEN OBLITERATED ]\nPrimary Overseer Avatar collapsed! South Surface Ascension Lift unlocked.",
			"overseer_boss_defeated"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter the South Surface Ascension Lift to complete Act I!")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("boss_defeated")
