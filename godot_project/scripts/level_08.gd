extends Node3D
class_name Level08Sector

# Sector 08: Null Pointer Corridor & The Sterile Ward
# Survival horror level featuring a "False Reprieve" opening, psychological surveillance stalking,
# high enemy volume (Glitch Walkers, Wire Hounds, CyberHusks), EMP MK IV upgrade, and concourse lockdown override.

var is_lockdown_triggered: bool = false
var is_exit_unlocked: bool = false
var has_keycard: bool = false

@onready var foyer_door_mesh: Node3D = find_child("FoyerLockdownDoor", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBulkheadDoor", true, false)
@onready var terminal: Node3D = find_child("ConcourseOverrideTerminal", true, false)
@onready var cctv_wall: Node3D = find_child("CCTVMonitorWall", true, false)
@onready var keycard_pickup: Node3D = find_child("NullPointerKeyPickup", true, false)
@onready var lockdown_trigger: Area3D = find_child("LockdownTrigger", true, false)
@onready var lounge_lights: Node3D = find_child("LoungeLights", true, false)
@onready var emergency_lights: Node3D = find_child("EmergencyLights", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_08] Null Pointer Corridor & Sterile Ward initialized.")

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Decontamination Ward: Safe Haven. Rest and gather supplies before proceeding.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec8")

	if lockdown_trigger:
		lockdown_trigger.body_entered.connect(_on_lockdown_trigger_entered)

	if keycard_pickup and keycard_pickup.has_signal("keycard_collected"):
		keycard_pickup.connect("keycard_collected", func(): has_keycard = true)

	if terminal:
		if terminal.has_signal("terminal_accessed"):
			terminal.connect("terminal_accessed", _on_terminal_accessed)
		elif terminal.has_signal("interacted"):
			terminal.connect("interacted", _on_terminal_accessed)

func _on_lockdown_trigger_entered(body: Node3D) -> void:
	if is_lockdown_triggered:
		return
	if not (body is CharacterBody3D or body.name == "RoxyVance" or body.is_in_group("player")):
		return

	trigger_lockdown()

func trigger_lockdown() -> void:
	if is_lockdown_triggered:
		return
	is_lockdown_triggered = true
	print("[Level_08] FALSE REPRIEVE COLLAPSED: Concourse Lockdown Initiated!")

	# Dim or kill sterile lounge lighting
	if lounge_lights:
		for light in lounge_lights.get_children():
			if light is Light3D:
				light.light_energy = 0.15

	# Energize flashing amber emergency lights
	if emergency_lights:
		emergency_lights.visible = true

	# Slam foyer blast door shut behind player
	if foyer_door_mesh:
		var tween = create_tween()
		if tween:
			tween.tween_property(foyer_door_mesh, "position:y", 1.8, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ NULL POINTER LOCKDOWN ACTIVE ]\nFalse Reprieve collapsed. Heavy glitch activity detected ahead.",
			"overseer_reprieve_taunt"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Concourse Lockdown: Scavenge Null Pointer Keycard to unseal Sector 09.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("reprieve_taunt")

func _on_terminal_accessed(_user_data = null) -> void:
	var lm = get_node_or_null("/root/LevelManager")
	var has_key = has_keycard
	if lm and lm.has_method("has_singularity_part") and lm.has_singularity_part("null_pointer_keycard"):
		has_key = true

	if has_key:
		unlock_exit()
	else:
		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ ACCESS DENIED: NULL ADDRESS EXCEPTION ]\nInsert Null Address Pointer Keycard (Located in Clinical Overload Lab).",
				"overseer_puzzle_hint"
			)

func unlock_exit() -> void:
	if is_exit_unlocked:
		return
	is_exit_unlocked = true
	print("[Level_08] Concourse Terminal Overridden! Sector 09 Transit Bulkhead UNLOCKED.")

	if exit_door_mesh:
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.2, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ CONCOURSE TRANSIT UNSEALED ]\nPointer resolved. Proceed through Blast Bulkhead to Sector 09.",
			"overseer_puzzle_solved"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Proceed through Blast Bulkhead to Sector 09: Thread Lock Abyss.")
