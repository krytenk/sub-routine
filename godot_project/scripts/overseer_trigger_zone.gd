extends Area3D
class_name OverseerTriggerZone

# Dedicated Trigger Zone for The Overseer's Fourth-Wall Interventions
# Catches navmesh breaches, speedrunners, and sequence-breaking attempts.

enum TriggerType {
    NAVMESH_BOUNDARY,
    SPEEDRUN_CHECKPOINT,
    INVISIBLE_WALL,
    SEQUENCE_BREAK
}

@export var trigger_type: TriggerType = TriggerType.NAVMESH_BOUNDARY
@export var speedrun_minimum_time_seconds: float = 60.0
@export var required_puzzle: Node = null
@export var custom_dialogue_override: String = ""

var triggered: bool = false
var sector_start_time: float = 0.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    sector_start_time = Time.get_ticks_msec() / 1000.0

func _on_body_entered(body: Node3D) -> void:
    if not (body is RoxyVance):
        return

    var overseer = get_node_or_null("/root/TheOverseer")
    if not overseer:
        return

    match trigger_type:
        TriggerType.NAVMESH_BOUNDARY:
            overseer.report_navmesh_boundary_hit()

        TriggerType.SPEEDRUN_CHECKPOINT:
            var current_time = Time.get_ticks_msec() / 1000.0
            var elapsed = current_time - sector_start_time
            if elapsed < speedrun_minimum_time_seconds:
                overseer.report_speedrun_detected()

        TriggerType.INVISIBLE_WALL:
            overseer.report_invisible_wall_hit()

        TriggerType.SEQUENCE_BREAK:
            if required_puzzle and required_puzzle.has_method("is_completed"):
                if not required_puzzle.is_completed:
                    overseer.report_sequence_break(required_puzzle.name)
            elif not custom_dialogue_override.is_empty():
                overseer.trigger_dialogue("sequence_break", custom_dialogue_override)
