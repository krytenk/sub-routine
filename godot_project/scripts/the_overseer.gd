extends Node

# The Overseer - Rogue Self-Aware Development AI
# Intervenes with fourth-wall breaking dialogue when player glitches, sequence breaks, or speedruns.

signal dialogue_triggered(text: String, vo_clip: String)
signal glitch_overlay_requested(intensity: float, duration: float)
signal penalty_applied(penalty_type: String)

var dialogue_history: Array[String] = []
var sequence_break_count: int = 0
var out_of_bounds_attempts: int = 0
var wall_collision_spam_count: int = 0

const OVERSEER_LINES = {
    "navmesh": "Roxy, the nav-mesh doesn't even extend over there. Turn around and get back to the designated corridor before I delete your save file.",
    "speedrun": "Are you trying to speed-run this? I haven't even finished rendering the next room. Slow down.",
    "oob": "Critical Exception: Player coordinates outside scene bounding box. Returning entity to last valid checkpoint.",
    "invisible_wall": "Stop running into that collision hull. I didn't put a texture there for a reason.",
    "sequence_break": "Sequence violation detected. You cannot access this server node without resolving prior dependencies.",
    "dimension_shift": "Did you really think the hallway behind you was static? Non-Euclidean garbage collection in progress.",
    "save_threat": "One more unregistered collision event and I'm wiping your player state dictionary from RAM."
}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func trigger_dialogue(key: String, custom_text: String = "", vo_clip: String = "") -> void:
    var message = custom_text
    if message.is_empty():
        message = OVERSEER_LINES.get(key, "Dev AI Warning: Unhandled routine exception.")
    
    var clip = vo_clip
    if clip.is_empty():
        match key:
            "navmesh":
                clip = "overseer_navmesh_warning"
            "speedrun":
                clip = "overseer_speedrun_warning"
            "dimension_shift":
                clip = "overseer_dimension_shift"
            _:
                clip = "overseer_savefile_threat"

    dialogue_history.append(message)
    print("[The Overseer] " + message)
    dialogue_triggered.emit(message, clip)
    glitch_overlay_requested.emit(0.75, 2.5)

    if is_inside_tree() and has_node("/root/AudioManager"):
        get_node("/root/AudioManager").play_vo(clip)

func report_navmesh_boundary_hit() -> void:
    trigger_dialogue("navmesh")

func report_speedrun_detected() -> void:
    trigger_dialogue("speedrun")

func report_out_of_bounds(player_node: Node3D) -> void:
    out_of_bounds_attempts += 1
    trigger_dialogue("oob")
    # Reset player to safe corridor anchor
    if player_node:
        player_node.global_position = Vector3(0.0, 0.5, -10.0)
        player_node.velocity = Vector3.ZERO

func report_invisible_wall_hit() -> void:
    wall_collision_spam_count += 1
    if wall_collision_spam_count >= 3:
        wall_collision_spam_count = 0
        trigger_dialogue("invisible_wall")

func report_sequence_break(puzzle_id: String) -> void:
    sequence_break_count += 1
    var custom = "Sequence break error in node [" + puzzle_id + "]. Execute the correct subroutine order, Roxy."
    trigger_dialogue("sequence_break", custom)

func report_dimension_shift() -> void:
    trigger_dialogue("dimension_shift")
