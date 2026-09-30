extends PuzzleBase
class_name CircuitBreakerPuzzle

# Subterranean Circuit Breaker Power Grid Puzzle
# Player must toggle server breakers or dereference the memory register cipher

@export var generated_code: String = ""
var entered_code: String = ""
var breaker_states: Array[bool] = []
var target_states: Array[bool] = []

func _ready() -> void:
    super._ready()
    _setup_breakers()
    generate_new_cipher()

func generate_new_cipher() -> void:
    var key_len = 4
    if has_node("/root/DifficultyManager"):
        key_len = get_node("/root/DifficultyManager").get_cipher_key_length()
    
    var chars = "0123456789ABCDEF"
    generated_code = ""
    for i in range(key_len):
        generated_code += chars[randi() % chars.length()]
    print("[CircuitBreaker] Target memory cipher: ", generated_code)

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

func input_character(c: String) -> void:
    if is_completed:
        return
    entered_code += c
    if entered_code.length() == generated_code.length():
        if entered_code == generated_code:
            complete_puzzle()
        else:
            fail_puzzle()
            entered_code = ""

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

func complete_puzzle() -> void:
    for i in range(breaker_states.size()):
        breaker_states[i] = true
    super.complete_puzzle()
