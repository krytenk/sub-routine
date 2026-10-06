extends Node3D
class_name Level06Sector

# Sector 06: Deep Server Sub-Basement (The Deep Server Vault)
# Labyrinthine data catacombs preserved in cryogenic fluid and corrupted code.
# Features:
# - Claustrophobic server rack aisles stalked by CyberHusks (re-animated cybernetic corpses)
# - Scavengeable EMP Capacitor Core (Upgrades EMP to MK II)
# - CRT Central Server Console with Memory Parity Cipher
# - Backtrack portal to Sector 05 (Sub-Core Tram Hub)
# - High-Security Transit Bulkhead to Sector 07 (Stack Overflow Vault)

const CRTTerminalProp = preload("res://scenes/props/crt_terminal_prop.gd")

var is_vault_unlocked: bool = false

@onready var vault_terminal: Node3D = find_child("VaultCompilationTerminal", true, false)
@onready var exit_gate: Node3D = find_child("TransitExitGate", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var exit_trigger: Area3D = find_child("Sector07ExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_06] Deep Server Sub-Basement initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Explore Deep Server Vault. Scavenge EMP Capacitor & compile terminal cipher.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("server_vault")

	# Connect Vault Terminal
	if vault_terminal:
		if vault_terminal.has_signal("terminal_accessed"):
			vault_terminal.connect("terminal_accessed", _on_terminal_accessed)
		elif vault_terminal.has_signal("interacted"):
			vault_terminal.connect("interacted", _on_terminal_accessed)

func unlock_sector_07_transit() -> void:
	if is_vault_unlocked:
		return
	is_vault_unlocked = true
	print("[Level_06] Deep Server Vault Cipher Compiled! Sector 07 Transit Gate UNLOCKED.")

	if exit_door_mesh:
		var tween = create_tween()
		tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 3.8, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ CIPHER COMPILED: PARITY VALIDATED ]\nHigh-Security Blast Bulkhead opened to Sector 07.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through High-Security Blast Bulkhead to Sector 07.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"puzzle_solved",
			"Parity validated. Sector 07 blast door unlocked. But the deeper you delve, Roxy, the less human you'll find."
		)

func _on_terminal_accessed(_user_data = null) -> void:
	unlock_sector_07_transit()
