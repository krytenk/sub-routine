extends Node3D
class_name Level09Sector

# Sector 09: Thread Lock Abyss & Multi-Thread Core
# Deep industrial chasm featuring suspended catwalks over a bottomless void,
# intense multi-thread enemy swarms, asynchronous Deadlock Relays,
# the apex EMP MK V Zero-Point upgrade, and elusive stalker shadows.

var cycled_relays: Array[String] = []
var has_cipher: bool = false
var is_exit_unlocked: bool = false

@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var core_console: Node3D = find_child("CoreConsensusTerminal", true, false)
@onready var cipher_pickup: Node3D = find_child("ThreadLockCipherPickup", true, false)
@onready var relay_a: Node3D = find_child("DeadlockRelay_A", true, false)
@onready var relay_b: Node3D = find_child("DeadlockRelay_B", true, false)
@onready var relay_c: Node3D = find_child("DeadlockRelay_C", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_09] Thread Lock Abyss initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("De-synchronize Deadlock Relays A, B, and C in the Multi-Thread Ring.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec9")

	if cipher_pickup and cipher_pickup.has_signal("cipher_collected"):
		cipher_pickup.connect("cipher_collected", func(): has_cipher = true)

	_connect_relay(relay_a)
	_connect_relay(relay_b)
	_connect_relay(relay_c)

	if core_console:
		if core_console.has_signal("terminal_accessed"):
			core_console.connect("terminal_accessed", _on_console_accessed)
		elif core_console.has_signal("interacted"):
			core_console.connect("interacted", _on_console_accessed)

func _connect_relay(relay: Node3D) -> void:
	if relay and relay.has_signal("relay_cycled"):
		relay.connect("relay_cycled", _on_relay_cycled)

func _on_relay_cycled(relay_id: String) -> void:
	if not cycled_relays.has(relay_id):
		cycled_relays.append(relay_id)
		print("[Level_09] Deadlock Relay cycled: ", relay_id, " (Total: ", cycled_relays.size(), "/3)")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if cycled_relays.size() >= 3:
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ ALL DEADLOCK RELAYS RELEASED ]\nInput Thread Lock Cipher at the Core Consensus Terminal.",
				"overseer_deadlock_unlocked"
			)
		if hud and hud.has_method("update_objective"):
			hud.update_objective("Input Thread Lock Cipher at the Core Consensus Terminal.")
		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("deadlock_unlocked")
	else:
		if hud and hud.has_method("update_objective"):
			hud.update_objective("Relays De-synchronized: %d/3. Cycle remaining relays." % cycled_relays.size())

func _on_console_accessed(_user_data = null) -> void:
	var lm = get_node_or_null("/root/LevelManager")
	var has_key = has_cipher
	if lm and lm.has_method("has_singularity_part") and lm.has_singularity_part("thread_lock_cipher"):
		has_key = true

	if cycled_relays.size() < 3:
		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ MUTEX DEADLOCK: RELAYS BLOCKED ]\nDe-synchronize all 3 Deadlock Relays in the Multi-Thread Ring (%d/3 done)." % cycled_relays.size(),
				"overseer_puzzle_hint"
			)
		return

	if not has_key:
		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ CIPHER MISSING ]\nRecover the Thread Lock Bypass Cipher from Lead Engineer Silas Ward.",
				"overseer_puzzle_hint"
			)
		return

	unlock_exit()

func unlock_exit() -> void:
	if is_exit_unlocked:
		return
	is_exit_unlocked = true
	print("[Level_09] Thread Lock Resolved! Sector 10 Core Transit Bulkhead UNLOCKED.")

	if exit_door_mesh:
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.5, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ THREAD LOCK BYPASSED: GATE UNSEALED ]\nProceed through Blast Bulkhead to Sector 10 Core Threshold.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through Blast Bulkhead to Sector 10 Core Threshold.")
