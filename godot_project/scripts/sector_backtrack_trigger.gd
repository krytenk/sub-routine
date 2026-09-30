extends Area3D
class_name SectorBacktrackTrigger

# Sector Backtracking Trigger
# Allows player to step backwards into previously cleared sectors to scavenge respawned supplies.
# Features spawn grace period to prevent immediate loop trigger upon loading a sector.

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

@export var target_level_index: int = 1
@export var grace_period: float = 2.5

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
	print("[SectorBacktrackTrigger] Backtracking to Sector ", target_level_index)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"backtrack_hint",
			"Retreating to previous sectors? You can scavenge respawned nanites, but the complex doesn't forget where you've been."
		)

	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		get_tree().create_timer(0.2).timeout.connect(func():
			if lm.has_method("backtrack_to_level"):
				lm.backtrack_to_level(target_level_index)
			else:
				lm.load_level(target_level_index)
		)
