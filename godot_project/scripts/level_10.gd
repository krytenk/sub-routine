extends Node3D
class_name Level10Sector

# Sector 10: Clock Cycle Foundry & Oscillator Hall
# High-pressure industrial furnace and quartz timing complex.
# Features:
# - Central Oscillator Piston Hall with three parallel catwalk bridges
# - West Thermal Sync Chamber & East Quartz Timing Chamber
# - Escalated enemy volume: 4 Glitch Walkers, 3 Wire Hounds, 2 CyberHusks
# - Persistent Stalker presence: 4 Surveillance Cameras & 3 Stalker Shadows
# - Multi-node Quartz Oscillator Relay synchronization puzzle + Cipher key recovery
# - Wall Map Panel (Sector 10 Blueprint) & Backtrack gate to Sector 09

var synced_relays: Dictionary = {
	"osc_alpha": false,
	"osc_beta": false,
	"osc_gamma": false
}
var has_quartz_cipher: bool = false
var is_foundry_synced: bool = false

@onready var foundry_terminal: Node3D = find_child("FoundrySyncTerminal", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector11ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_10] Clock Cycle Foundry & Oscillator Hall initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Synchronize 3 Quartz Oscillator Relays (0/3) & recover Quartz Cipher to unlock Sector 11.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec10")

	var relays = [
		find_child("OscillatorRelay_Alpha", true, false),
		find_child("OscillatorRelay_Beta", true, false),
		find_child("OscillatorRelay_Gamma", true, false)
	]
	for r in relays:
		if r:
			if r.has_signal("relay_cycled") and not r.is_connected("relay_cycled", _on_relay_synchronized):
				r.connect("relay_cycled", _on_relay_synchronized)
			elif r.has_signal("relay_synchronized") and not r.is_connected("relay_synchronized", _on_relay_synchronized):
				r.connect("relay_synchronized", _on_relay_synchronized)

	var cipher = find_child("QuartzDividerCipher", true, false)
	if cipher and cipher.has_signal("cipher_collected"):
		if not cipher.is_connected("cipher_collected", _on_cipher_collected):
			cipher.connect("cipher_collected", _on_cipher_collected)

	if foundry_terminal:
		if foundry_terminal.has_signal("terminal_accessed"):
			if not foundry_terminal.is_connected("terminal_accessed", _on_foundry_terminal_accessed):
				foundry_terminal.connect("terminal_accessed", _on_foundry_terminal_accessed)
		elif foundry_terminal.has_signal("interacted"):
			if not foundry_terminal.is_connected("interacted", _on_foundry_terminal_accessed):
				foundry_terminal.connect("interacted", _on_foundry_terminal_accessed)

func _on_relay_synchronized(r_id: String) -> void:
	synced_relays[r_id] = true
	var count = get_synced_relay_count()
	print("[Level_10] Quartz Oscillator Relay synchronized: ", r_id, " (", count, "/3)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("Quartz Oscillator Relays Synchronized (%d/3). Continue across the Foundry." % count)
		elif not has_quartz_cipher:
			hud.update_objective("All 3 Relays Synchronized! Recover Quartz Divider Cipher in East Timing Chamber.")
		else:
			hud.update_objective("All Relays & Cipher ready! Interface with Foundry Sync Terminal [E] at South Bulkhead.")

func _on_cipher_collected(_c_id: String = "") -> void:
	has_quartz_cipher = true
	print("[Level_10] Quartz Divider Cipher recovered!")

	var count = get_synced_relay_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 3:
			hud.update_objective("Quartz Cipher acquired! Synchronize remaining Oscillator Relays (%d/3)." % count)
		else:
			hud.update_objective("All Relays & Cipher ready! Interface with Foundry Sync Terminal [E] at South Bulkhead.")

func get_synced_relay_count() -> int:
	var c = 0
	for k in synced_relays.keys():
		if synced_relays[k]:
			c += 1
	return c

func _on_foundry_terminal_accessed(_user_data = null) -> void:
	if is_foundry_synced:
		return

	var count = get_synced_relay_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 3 or not has_quartz_cipher:
		print("[Level_10] Foundry Sync Terminal rejected: Relays (", count, "/3), Cipher: ", has_quartz_cipher)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ CLOCK PHASE MISMATCH ]\nSynchronize all 3 Quartz Relays (%d/3) and acquire Quartz Cipher (%s) before unlocking Sector 11." % [count, "READY" if has_quartz_cipher else "MISSING"],
				""
			)
		return

	unlock_sector_11_gate()

func unlock_sector_11_gate() -> void:
	if is_foundry_synced:
		return
	is_foundry_synced = true
	print("[Level_10] Clock Cycle Foundry phase-locked! Sector 11 DMA Trench Gate UNLOCKED.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ CLOCK DIVIDER SYNCHRONIZED ]\nSouth Bulkhead disengaged. Direct Memory Access Trench (Sector 11) open.",
			"overseer_foundry_synced"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through South Bulkhead into Sector 11: DMA Controller Trench.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("foundry_synced")
