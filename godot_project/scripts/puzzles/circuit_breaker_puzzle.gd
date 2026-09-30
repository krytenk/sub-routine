extends PuzzleBase
class_name CircuitBreakerPuzzle

# Subterranean Circuit Breaker Power Grid Puzzle
# Player must toggle server breakers into the target binary power configuration

var breaker_states: Array[bool] = []
var target_states: Array[bool] = []

func _ready() -> void:
    super._ready()
    _setup_breakers()

func _setup_breakers() -> void:
    breaker_states.clear()
    target_states.clear()
    for i in range(required_steps):
        breaker_states.append(false)
        target_states.append(true)

func toggle_breaker(index: int) -> void:
    if is_completed or index < 0 or index >= breaker_states.size():
        return
    breaker_states[index] = not breaker_states[index]
    print("[CircuitBreaker] Toggled breaker ", index, " -> ", breaker_states[index])
    _check_solution()

func _handle_player_input(_player: CharacterBody3D) -> void:
    # Toggle next unset breaker
    for i in range(breaker_states.size()):
        if not breaker_states[i]:
            toggle_breaker(i)
            return

func _check_solution() -> void:
    for i in range(breaker_states.size()):
        if breaker_states[i] != target_states[i]:
            return
    complete_puzzle()
