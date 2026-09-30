extends Node3D
class_name PuzzleBase

# Base class for Sub-Routine subterranean server puzzles
# Scales complexity dynamically via DifficultyManager.

signal puzzle_solved
signal puzzle_failed
signal puzzle_interacted

@export var puzzle_id: String = "PUZZLE_01"
@export var puzzle_name: String = "Server Memory Register"
@export var is_completed: bool = false
@export var base_required_steps: int = 3

var current_step: int = 0
var required_steps: int = 3

func _ready() -> void:
    _recalculate_complexity()
    if has_node("/root/DifficultyManager"):
        get_node("/root/DifficultyManager").difficulty_changed.connect(_on_difficulty_changed)

func _on_difficulty_changed(_val: float, _name: String) -> void:
    if not is_completed:
        _recalculate_complexity()

func _recalculate_complexity() -> void:
    if has_node("/root/DifficultyManager"):
        var mult = get_node("/root/DifficultyManager").get_puzzle_complexity_multiplier()
        required_steps = maxi(1, int(round(base_required_steps * mult)))
    else:
        required_steps = base_required_steps
    print("[PuzzleBase] ", puzzle_id, " (", puzzle_name, ") required steps scaled to: ", required_steps)

func interact(player: CharacterBody3D) -> void:
    if is_completed:
        print("[PuzzleBase] ", puzzle_id, " is already solved.")
        return

    puzzle_interacted.emit()
    _handle_player_input(player)

func _handle_player_input(_player: CharacterBody3D) -> void:
    current_step += 1
    print("[PuzzleBase] Progress on ", puzzle_id, ": ", current_step, "/", required_steps)
    if current_step >= required_steps:
        complete_puzzle()

func complete_puzzle() -> void:
    if is_completed:
        return
    is_completed = true
    puzzle_solved.emit()
    print("[PuzzleBase] PUZZLE COMPLETE: ", puzzle_id, " (", puzzle_name, ")")

func fail_puzzle() -> void:
    current_step = 0
    puzzle_failed.emit()
    print("[PuzzleBase] Puzzle failed! Resetting register: ", puzzle_id)
    if has_node("/root/TheOverseer"):
        get_node("/root/TheOverseer").report_sequence_break(puzzle_id)
