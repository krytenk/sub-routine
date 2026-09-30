extends Area3D
class_name SectorExitTrigger

# Sector Transit Exit Trigger
# Detects player passing through the opened blast door into the inter-sector transit corridor.
# Features a brief grace period upon scene load to prevent immediate triggering during backtracking.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

signal player_reached_exit(level_index: int)

@export var grace_period: float = 2.0

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if grace_period > 0.0:
		grace_period -= delta

func _on_body_entered(body: Node3D) -> void:
	if grace_period > 0.0 or has_triggered:
		return
	if not (body is RoxyVance or body.is_in_group("player")):
		return

	has_triggered = true
	print("[SectorExitTrigger] Player entered transit corridor! Advancing sector...")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"puzzle_solved",
			"Sector cleared. Thread escalating to next processing depth."
		)

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		player_reached_exit.emit(lm.current_level_index)
		get_tree().create_timer(0.5).timeout.connect(func():
			if lm.has_method("complete_current_level"):
				lm.complete_current_level()
		)
