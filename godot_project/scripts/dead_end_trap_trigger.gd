extends Area3D
class_name DeadEndTrapTrigger

# Room 1: Chamber of Five Dead Ends - Lethal Trap Trigger
# Detects player entering the 5th dead-end sub-cell, sealing blast doors and triggering containment purge.

signal trap_sprung
signal player_purged

@export var trap_damage: int = 120
var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if has_triggered:
		return
	if not (body is RoxyVance or body.is_in_group("player")):
		return

	has_triggered = true
	print("[DeadEndTrap] Final dead end reached! Containment purge sequence initiated.")
	trap_sprung.emit()

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"dead_end_trap",
			"I warned you about unhandled branch execution. All five corridors terminate here... as do you."
		)

	if is_inside_tree():
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message("[CRITICAL CONTAINMENT FAILURE] Lethal Decontamination Purge Active", "")

	# Execute purge damage after dramatic 2.0s delay
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(trap_damage, "trap")
			player_purged.emit()
	)
