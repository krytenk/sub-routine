extends PuzzleBase
class_name ServerTerminalPuzzle

# Sub-Routine Server Terminal Keypad Puzzle
# Requires player to input correct memory register hex string scaled by difficulty

@export var generated_code: String = ""
var entered_code: String = ""

func _ready() -> void:
    super._ready()
    generate_new_cipher()

func generate_new_cipher() -> void:
    var key_len = 4
    if has_node("/root/DifficultyManager"):
        key_len = get_node("/root/DifficultyManager").get_cipher_key_length()
    
    var chars = "0123456789ABCDEF"
    generated_code = ""
    for i in range(key_len):
        generated_code += chars[randi() % chars.length()]
    print("[ServerTerminal] Target memory cipher: ", generated_code)

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
    # Simulates entering the discovered code on interaction
    input_character(generated_code[entered_code.length()])
