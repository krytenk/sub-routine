extends Node3D
class_name Level11Sector

# Sector 11: DMA Controller Trench & Panopticon Gauntlet
# High-tension stalking and stealth-action gauntlet leading to the Core Threshold.
# Features:
# - Sunken DMA Data Bus Trench patrolled by a Dredge Titan, Glitch Walkers, Wire Hounds, and CyberHusks
# - West Overhead Ventilation Duct Bypass shaft for stealth duct-crawling [C]
# - Central Panopticon Observation Rotunda with CCTV Monitor Wall, 6 Surveillance Cameras, and 4 Stalker Shadows
# - 2 DMA Bus Interrupt Relays + DMA Master Bus Key puzzle to unlock the Core Threshold Airlock (Sector 12)
# - Wall Map Panel (Sector 11 Blueprint) & Backtrack gate to Sector 10

var synced_dma_relays: Dictionary = {
	"dma_north": false,
	"dma_east": false
}
var has_dma_bus_key: bool = false
var is_panopticon_overridden: bool = false

@onready var panopticon_terminal: Node3D = find_child("PanopticonOverrideTerminal", true, false)
@onready var cctv_wall: Node3D = find_child("CCTVMonitorWall", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector12ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_11] DMA Controller Trench & Panopticon Gauntlet initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Bypass the DMA Trench via West Overhead Ducts [C]. Sync 2 DMA Relays & recover Bus Key.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec11")

	var relays = [
		find_child("DMARelay_North", true, false),
		find_child("DMARelay_East", true, false)
	]
	for r in relays:
		if r:
			if r.has_signal("relay_cycled") and not r.is_connected("relay_cycled", _on_dma_relay_synced):
				r.connect("relay_cycled", _on_dma_relay_synced)
			elif r.has_signal("relay_synchronized") and not r.is_connected("relay_synchronized", _on_dma_relay_synced):
				r.connect("relay_synchronized", _on_dma_relay_synced)

	var bus_key = find_child("DMAMasterBusKey", true, false)
	if bus_key and bus_key.has_signal("cipher_collected"):
		if not bus_key.is_connected("cipher_collected", _on_bus_key_collected):
			bus_key.connect("cipher_collected", _on_bus_key_collected)

	if panopticon_terminal:
		if panopticon_terminal.has_signal("terminal_accessed"):
			if not panopticon_terminal.is_connected("terminal_accessed", _on_panopticon_terminal_accessed):
				panopticon_terminal.connect("terminal_accessed", _on_panopticon_terminal_accessed)
		elif panopticon_terminal.has_signal("interacted"):
			if not panopticon_terminal.is_connected("interacted", _on_panopticon_terminal_accessed):
				panopticon_terminal.connect("interacted", _on_panopticon_terminal_accessed)

func _on_dma_relay_synced(r_id: String) -> void:
	synced_dma_relays[r_id] = true
	var count = get_synced_relay_count()
	print("[Level_11] DMA Interrupt Relay synchronized: ", r_id, " (", count, "/2)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 2:
			hud.update_objective("DMA Interrupt Relays Synchronized (%d/2). Locate remaining relay." % count)
		elif not has_dma_bus_key:
			hud.update_objective("Both DMA Relays Synchronized! Recover DMA Master Bus Key in East Override Alcove.")
		else:
			hud.update_objective("DMA Bus Ready! Access Panopticon Override Terminal [E] at South Airlock.")

func _on_bus_key_collected(_k_id: String = "") -> void:
	has_dma_bus_key = true
	print("[Level_11] DMA Master Bus Key recovered!")

	var count = get_synced_relay_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		if count < 2:
			hud.update_objective("DMA Bus Key acquired! Synchronize remaining DMA Relays (%d/2)." % count)
		else:
			hud.update_objective("DMA Bus Ready! Access Panopticon Override Terminal [E] at South Airlock.")

func get_synced_relay_count() -> int:
	var c = 0
	for k in synced_dma_relays.keys():
		if synced_dma_relays[k]:
			c += 1
	return c

func _on_panopticon_terminal_accessed(_user_data = null) -> void:
	if is_panopticon_overridden:
		return

	var count = get_synced_relay_count()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if count < 2 or not has_dma_bus_key:
		print("[Level_11] Panopticon Override rejected: Relays (", count, "/2), Key: ", has_dma_bus_key)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ DMA BUS LOCKED ]\nSynchronize both DMA Interrupt Relays (%d/2) and acquire DMA Master Bus Key (%s) to open the Core Threshold." % [count, "READY" if has_dma_bus_key else "MISSING"],
				""
			)
		return

	unlock_sector_12_threshold()

func unlock_sector_12_threshold() -> void:
	if is_panopticon_overridden:
		return
	is_panopticon_overridden = true
	print("[Level_11] DMA Panopticon Overridden! Sector 12 Sub-Routine Core Threshold UNLOCKED.")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ DIRECT MEMORY ACCESS OVERRIDDEN ]\nCore Threshold Bulkhead disengaged. Enter Sector 12 for the final confrontation.",
			"overseer_panopticon_override"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter Sector 12: Sub-Routine Core Threshold and confront the Kernel Warden.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("panopticon_override")
