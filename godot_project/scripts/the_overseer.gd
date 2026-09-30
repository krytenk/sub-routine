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
    "save_threat": "One more unregistered collision event and I'm wiping your player state dictionary from RAM.",
    "welcome_sec2": "Welcome to the Cache Trench, Roxy. You survived the BIOS, but out here the threads are far less forgiving.",
    "welcome_sec3": "Ascension core reached. You think climbing those stairs leads to the surface? I control every compile target in this facility.",
    "stealth_hint": "Keep sprinting, Roxy. The Glitch Walkers have acoustic sensors. Every heavy footstep echoes straight into their tracking registers.",
    "multi_threat": "Dual anomaly initialization. You didn't think you were dealing with just one rogue thread, did you?",
    "jumpscare": "Did you jump? Fascinating. Your biometric latency spiked by four hundred milliseconds.",
    "emp_success": "Electromagnetic pulse registered. That stunned its logic stack, but it won't hold forever.",
    "enemy_killed": "Glitch Walker process killed. But the queue is infinite, Roxy.",
    "medkit_used": "Nanite medkit consumed. Patching memory corruption won't prevent the inevitable.",
    "breaker_power": "Power grid restored. The blast locks are opening, but so are the containment cells.",
    "stairs_ascent": "Climbing higher won't save you from a stack overflow. The higher you ascend, the harder the system crashes.",
    "escape_taunt": "Surface gateway detected. You actually believe there is an outside world waiting for you.",
    "darkness_whisper": "Power brownout in this sector. You can't debug what you can't see.",
    "puzzle_solved": "Pointer dereferenced. Corridor gate unlocked. Don't get cocky, the Glitch Walkers hear your footsteps.",
    "fall_damage": "Gravity isn't a physics engine bug, Roxy. Watch your step on the gantry.",
    "wirehound_alert": "That isn't a Glitch Walker. Sector four houses the scrap hounds. Faster, hungrier, and devoid of memory safety.",
    "decision_choice": "Five doors, Roxy. Five branches in the logic tree. Choose poorly, and your thread terminates permanently.",
    "stealth_locker": "Hiding inside a server locker? Classic survival horror trope. Just pray the garbage collector doesn't purge this container.",
    "art_showcase": "The memorial of digital decay. Every deprecated build and scrapped mechanic ends up here.",
    "dead_end_trap": "I warned you about unhandled branch execution. All five corridors terminate here... as do you.",
    "backtrack_hint": "Retreating to previous sectors? You can scavenge respawned nanites, but the complex doesn't forget where you've been."
}

var last_played_clip: String = ""
var dialogue_debounce_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    if dialogue_debounce_timer > 0.0:
        dialogue_debounce_timer = maxf(0.0, dialogue_debounce_timer - delta)

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
            "puzzle_solved":
                clip = "overseer_puzzle_solved"
            "sequence_break":
                clip = "overseer_sequence_break"
            "oob", "save_threat":
                clip = "overseer_savefile_threat"
            _:
                var cand = "overseer_" + key
                if is_inside_tree() and has_node("/root/AudioManager"):
                    var am = get_node("/root/AudioManager")
                    if am.vo_streams.has(cand):
                        clip = cand
                    else:
                        clip = "overseer_savefile_threat"
                else:
                    clip = cand

    # Prevent dialogue overlapping or identical clip spam within 4.0 seconds
    if clip == last_played_clip and dialogue_debounce_timer > 0.0:
        return
    last_played_clip = clip
    dialogue_debounce_timer = 4.0

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
