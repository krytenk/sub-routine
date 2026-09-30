extends RefCounted

# Subroutine Terminal Unit Tests
# Validates full 16-key hex keypad (0-F), buffer appending, backspace/clear,
# and successful cipher dereferencing.

func test_hex_keypad_buttons_exist() -> bool:
	var terminal_scene = load("res://scenes/ui/subroutine_terminal.tscn")
	if not terminal_scene:
		push_error("Failed to load subroutine_terminal.tscn")
		return false
	var term = terminal_scene.instantiate()
	var keypad = term.find_child("KeypadGrid", true, false)
	if not keypad:
		push_error("KeypadGrid not found in subroutine_terminal")
		term.free()
		return false

	var expected_keys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
	for k in expected_keys:
		var btn = keypad.get_node_or_null("Btn" + k)
		if not btn:
			push_error("Missing keypad button for hex key: " + k)
			term.free()
			return false
	
	term.free()
	return true

func test_buffer_entry_and_clear() -> bool:
	var terminal_scene = load("res://scenes/ui/subroutine_terminal.tscn")
	var term = terminal_scene.instantiate()
	term.current_target_cipher = "ABCD"
	term.input_buffer = ""
	
	term._append_char("A")
	term._append_char("B")
	if term.input_buffer != "AB":
		push_error("Buffer append failed. Expected 'AB', got: " + term.input_buffer)
		term.free()
		return false

	term._on_backspace()
	if term.input_buffer != "A":
		push_error("Backspace failed. Expected 'A', got: " + term.input_buffer)
		term.free()
		return false

	term._on_clear_pressed()
	if term.input_buffer != "":
		push_error("Clear failed. Buffer not empty.")
		term.free()
		return false

	term.free()
	return true

func test_cipher_dereferencing() -> bool:
	var terminal_scene = load("res://scenes/ui/subroutine_terminal.tscn")
	var term = terminal_scene.instantiate()
	term.current_target_cipher = "E46A"
	term.input_buffer = "E46A"
	
	term._on_dereference_pressed()
	if not term.is_unlocked:
		push_error("Dereference failed to set is_unlocked to true for matching cipher.")
		term.free()
		return false

	term.free()
	return true
