extends Area3D
class_name NonEuclideanCorridor

const RoxyVance = preload("res://scenes/player/roxy_vance.gd")

# Non-Euclidean Looping Corridor
# Teleports player seamlessly across hallway thresholds until puzzle requirement is met.

signal loop_traversed(loop_count: int)
signal corridor_unlocked

@export var exit_anchor: Marker3D
@export var entry_anchor: Marker3D
@export var puzzle_target: Node = null
@export var is_unlocked: bool = false

var loop_counter: int = 0

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    if puzzle_target and puzzle_target.has_signal("puzzle_solved"):
        puzzle_target.puzzle_solved.connect(_on_puzzle_solved)

func _on_puzzle_solved() -> void:
    is_unlocked = true
    corridor_unlocked.emit()
    print("[NonEuclideanCorridor] Puzzle solved! Corridor loop opened to next sector.")

func _on_body_entered(body: Node3D) -> void:
    if not (body is RoxyVance or body.has_method("take_damage")):
        return

    if is_unlocked:
        print("[NonEuclideanCorridor] Player passed through unlocked corridor.")
        return

    # Non-Euclidean looping: warp player seamlessly back to entry anchor
    loop_counter += 1
    loop_traversed.emit(loop_counter)
    
    if entry_anchor:
        var player = body
        var relative_offset = player.global_position - global_position
        var target_pos = entry_anchor.global_position if (entry_anchor.is_inside_tree() and entry_anchor.global_position != Vector3.ZERO) else entry_anchor.position
        var new_pos = target_pos + Vector3(relative_offset.x, 0.0, 0.0)
        player.global_position = new_pos
        player.position = new_pos
        print("[NonEuclideanCorridor] Looping player back to entry. Loop count: ", loop_counter)

    if loop_counter == 1:
        if is_inside_tree() and has_node("/root/TheOverseer"):
            get_node("/root/TheOverseer").trigger_dialogue(
                "dimension_shift",
                "Non-Euclidean security loop active. The blast door is locked until you retrieve the Memory Core and enter its cipher into the CRT Terminal."
            )
    elif loop_counter >= 3:
        if is_inside_tree() and has_node("/root/TheOverseer"):
            get_node("/root/TheOverseer").trigger_dialogue(
                "dimension_shift",
                "You cannot bypass this security blast door. Locate the glowing Memory Core on the server racks and interface with the CRT Terminal [E]."
            )
