extends Node3D
class_name Level13Sector

# Sector 13: Floating Point Void & Mantissa Islands
# Suspended data islands above a bottomless sub-core void.
# Features:
# - West Mantissa Platform, Central Exponent Hub, and East Radix Platform connected by narrow void spans
# - 3 Mantissa Stabilizer Relays + IEEE-754 Precision Cipher recovery puzzle
# - High-density patrols (Glitch Walkers, Wire Hounds, CyberHusks) + Stalker Cameras & Shadows
# - Wall Map Panel (Sector 13 Blueprint) & Backtrack gate to Sector 12

var stabilized_mantissas: Dictionary = {
	"mantissa_west": false,
	"mantissa_central": false,
	"mantissa_east": false
}
var has_ieee_cipher: bool = false
var is_void_anchored: bool = false

@onready var exponent_terminal: Node3D = find_child("ExponentConsensusTerminal", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector14ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_13] Floating Point Void & Mantissa Islands initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Calibrate 3 Mantissa Stabilizers (0/3) across the Void Islands & recover IEEE-754 Cipher.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec13")

	var relays = [
		find_child("MantissaRelay_West", true, false),
		find_child("MantissaRelay_Central", true, false),
		find_child("MantissaRelay_East", true, false)
	]
	for r in relays:
		if r:
			if r.has_signal("relay_cycled") and not r.is_connected("relay_cycled", _on_mantissa_stabilized):
				r.connect("relay_cycled", _on_mantissa_stabilized)
			elif r.has_signal("relay_synchronized") and not r.is_connected("relay_synchronized", _on_mantissa_stabilized):
				r.connect("relay_synchronized", _on_mantissa_stabilized)

	var cipher = find_child("IEEEPrecisionCipher", true, false)
	if cipher and cipher.has_signal("cipher_collected"):
		if not cipher.is_connected("cipher_collected", _on_cipher_collected):
			cipher.connect("cipher_collected", _on_cipher_collected)

	if exponent_terminal:
		if exponent_terminal.has_signal("terminal_accessed"):
			if not exponent_terminal.is_connected("terminal_accessed", _on_exponent_terminal_accessed):
				exponent_terminal.connect("terminal_accessed", _on_exponent_terminal_accessed)
		elif exponent_terminal.has_signal("interacted"):
			if not exponent_terminal.is_connected("interacted", _on_exponent_terminal_accessed):
				exponent_terminal.connect("interacted", _on_exponent_terminal_accessed)

func _on_mantissa_stabilized(r_id: String) -> void:
	stabilized_mantissas[r_id] = true
	var count = get_stabilized_count()
	print("[Level_13] Mantissa Stabilizer calibrated: ", r_id, " (", count, "/3)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("Mantissa Stabilizers Calibrated (%d/3). Watch your footing on the void bridges." % count)
		elif not has_ieee_cipher:
			hud.update_objective("All 3 Stabilizers Calibrated! Recover IEEE-754 Cipher on East Radix Platform.")
		else:
			hud.update_objective("IEEE-754 Precision Ready! Interface with Exponent Terminal [E] at South Airlock.")

func _on_cipher_collected(_c_id: String = "") -> void:
	has_ieee_cipher = true
	print("[Level_13] IEEE-754 Precision Cipher recovered!")

	var count = get_stabilized_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("IEEE-754 Cipher acquired! Calibrate remaining Mantissa Stabilizers (%d/3)." % count)
		else:
			hud.update_objective("IEEE-754 Precision Ready! Interface with Exponent Terminal [E] at South Airlock.")

func get_stabilized_count() -> int:
	var c = 0
	for k in stabilized_mantissas.keys():
		if stabilized_mantissas[k]:
			c += 1
	return c

func _on_exponent_terminal_accessed(_user_data = null) -> void:
	if is_void_anchored:
		return

	var count = get_stabilized_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 3 or not has_ieee_cipher:
		print("[Level_13] Exponent Terminal rejected: Stabilizers (", count, "/3), Cipher: ", has_ieee_cipher)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ FLOATING POINT UNDERFLOW ]\nCalibrate all 3 Mantissa Stabilizers (%d/3) and acquire IEEE-754 Cipher (%s) to unlock Sector 14." % [count, "READY" if has_ieee_cipher else "MISSING"],
				""
			)
		return

	unlock_sector_14_airlock()

func unlock_sector_14_airlock() -> void:
	if is_void_anchored:
		return
	is_void_anchored = true
	print("[Level_13] Floating Point Void anchored! Sector 14 Instruction Pipeline Airlock UNLOCKED.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ IEEE-754 PRECISION RESTORED ]\nSouth Pipeline Airlock disengaged. Proceed to Sector 14: Instruction Pipeline Trench.",
			"overseer_mantissa_locked"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through South Airlock into Sector 14: Instruction Pipeline Trench.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("mantissa_locked")
