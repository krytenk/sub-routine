extends Control
class_name SubroutineTerminal

# PS1 Vector Phosphor Subroutine Map, Telemetry Terminal & Register Hacking Minigame
# Toggled via 'toggle_map' action or TAB/M key or interacting with CRTTerminalProp.
# Allows interactive input of register hex ciphers (0-9, A-F) to dereference pointers and unlock sector gates.

signal terminal_opened
signal terminal_closed
signal pointer_dereferenced

@onready var sector_title: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Header/SectorTitle
@onready var topology_status: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Grid/TopologyStatus
@onready var register_status: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Grid/RegisterStatus
@onready var threat_status: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Grid/ThreatStatus
@onready var cipher_display: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/PuzzleSection/CipherDisplay
@onready var entered_display: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/PuzzleSection/EnteredDisplay
@onready var keypad_grid: GridContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/PuzzleSection/KeypadGrid
@onready var btn_dereference: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/PuzzleSection/ActionContainer/BtnDereference
@onready var btn_clear: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/PuzzleSection/ActionContainer/BtnClear
@onready var dev_notes: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/NotesPanel/DevNotes
@onready var close_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton

var current_target_cipher: String = "1400"
var input_buffer: String = ""
var is_unlocked: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if btn_dereference:
		btn_dereference.pressed.connect(_on_dereference_pressed)
	if btn_clear:
		btn_clear.pressed.connect(_on_clear_pressed)

	# Connect all keypad buttons in KeypadGrid (0-9, A-F)
	if keypad_grid:
		for btn in keypad_grid.get_children():
			if btn is Button and btn.name.begins_with("Btn"):
				var char_val = btn.text
				btn.pressed.connect(func(): _append_char(char_val))

	# Listen for level loading to automatically reset terminal for the new sector
	if has_node("/root/LevelManager"):
		get_node("/root/LevelManager").level_loaded.connect(_on_level_loaded)

func _on_level_loaded(_level_index: int, _level_node: Node = null) -> void:
	reset_terminal()

func reset_terminal() -> void:
	input_buffer = ""
	is_unlocked = false
	if btn_dereference:
		btn_dereference.text = "[ DEREFERENCE MEMORY POINTER ]"
	if entered_display:
		entered_display.remove_theme_color_override("font_color")
	refresh_telemetry()

func _input(event: InputEvent) -> void:
	if not visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_TAB:
				toggle_terminal()
				get_viewport().set_input_as_handled()
		return

	# When terminal is visible, capture all keyboard inputs with priority
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_TAB or event.keycode == KEY_X:
			toggle_terminal()
			get_viewport().set_input_as_handled()
			return

		# Direct keyboard typing of hex characters:
		var unicode_char = char(event.unicode).to_upper()
		if "0123456789ABCDEF".contains(unicode_char) and unicode_char != "":
			_append_char(unicode_char)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_BACKSPACE:
			_on_backspace()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_dereference_pressed()
			get_viewport().set_input_as_handled()
			return

func _append_char(c: String) -> void:
	# If terminal was marked unlocked from a previous sector, typing a character resets it for the new entry!
	if is_unlocked:
		input_buffer = ""
		is_unlocked = false
		if btn_dereference:
			btn_dereference.text = "[ DEREFERENCE MEMORY POINTER ]"
		if entered_display:
			entered_display.remove_theme_color_override("font_color")

	if input_buffer.length() < current_target_cipher.length():
		input_buffer += c
		_play_beep(880.0, 0.04)
		_update_buffer_display()
		if input_buffer.length() == current_target_cipher.length():
			_check_auto_dereference()

func _on_backspace() -> void:
	if is_unlocked:
		is_unlocked = false
		if btn_dereference:
			btn_dereference.text = "[ DEREFERENCE MEMORY POINTER ]"
		if entered_display:
			entered_display.remove_theme_color_override("font_color")

	if input_buffer.length() > 0:
		input_buffer = input_buffer.substr(0, input_buffer.length() - 1)
		_play_beep(550.0, 0.04)
		_update_buffer_display()

func _on_clear_pressed() -> void:
	input_buffer = ""
	is_unlocked = false
	if btn_dereference:
		btn_dereference.text = "[ DEREFERENCE MEMORY POINTER ]"
	if entered_display:
		entered_display.remove_theme_color_override("font_color")
	_play_beep(440.0, 0.06)
	_update_buffer_display()

func _update_buffer_display() -> void:
	if entered_display:
		var display_str = ""
		for i in range(current_target_cipher.length()):
			if i < input_buffer.length():
				display_str += input_buffer[i] + " "
			else:
				display_str += "_ "
		entered_display.text = "INPUT REGISTER BUFFER: [ %s]" % display_str

func _check_auto_dereference() -> void:
	if input_buffer == current_target_cipher:
		_on_dereference_pressed()

func _on_dereference_pressed() -> void:
	if is_unlocked:
		return
	if input_buffer == current_target_cipher:
		is_unlocked = true
		_play_beep(1200.0, 0.1)
		if entered_display:
			entered_display.text = "POINTER DEREFERENCED! CORRIDOR BLAST DOOR UNLOCKED [ OK ]"
			entered_display.add_theme_color_override("font_color", Color(0.1, 1.0, 0.4, 1.0))
		if btn_dereference:
			btn_dereference.text = "[ STATUS: BLAST DOOR UNLOCKED & ARMED ]"
		pointer_dereferenced.emit()
		print("[SubroutineTerminal] Cipher matched: ", input_buffer, " -> Dereferencing corridor pointers.")
		if is_inside_tree():
			var tree = get_tree()
			if tree:
				tree.create_timer(0.12).timeout.connect(func(): _play_beep(1600.0, 0.18))
				var root = tree.current_scene
				if root:
					var puzzle = root.find_child("PrimaryPuzzle", true, false)
					if puzzle and puzzle.has_method("complete_puzzle"):
						puzzle.complete_puzzle()

					var blast_door = root.find_child("BlastDoor", true, false)
					if blast_door and blast_door.has_method("open_door"):
						blast_door.open_door()

				var hud = tree.root.find_child("HUD", true, false)
				if hud and hud.has_method("update_objective"):
					var lm = get_node_or_null("/root/LevelManager")
					var next_sec = (lm.current_level_index + 1) if lm else 2
					hud.update_objective("Blast Door Unlocked! Proceed forward through corridor to Sector %02d." % next_sec)

			if has_node("/root/TheOverseer"):
				get_node("/root/TheOverseer").trigger_dialogue("puzzle_solved", "Pointer dereferenced. Corridor gate unlocked. Don't get cocky, the Glitch Walkers hear your footsteps.")

	else:
		_play_beep(220.0, 0.25)
		entered_display.text = "FAULT: INVALID CIPHER [ %s ] -> RETRY" % input_buffer
		entered_display.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		input_buffer = ""
		_update_buffer_display()

func toggle_terminal() -> void:
	visible = not visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		refresh_telemetry()
		terminal_opened.emit()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		terminal_closed.emit()

func show_terminal() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_telemetry()
	terminal_opened.emit()

func refresh_telemetry() -> void:
	var lm = get_node_or_null("/root/LevelManager") if is_inside_tree() else null
	var dm = get_node_or_null("/root/DifficultyManager") if is_inside_tree() else null

	var sec_idx = lm.current_level_index if lm else 1
	var info = lm.get_level_info(sec_idx) if lm else {}

	if sector_title:
		sector_title.text = "SECTOR %02d // %s" % [sec_idx, info.get("sector_name", "UNKNOWN SECTOR")]
	if topology_status:
		topology_status.text = "ANOMALY: " + info.get("non_euclidean_feature", "Looping Corridor")
	if register_status:
		register_status.text = "MATRIX: " + info.get("puzzle_type", "Memory Register")
	if threat_status:
		var speed = dm.get_enemy_speed_multiplier() if dm else 1.0
		threat_status.text = "THREAT: %s (Glitch Speed %.1fx)" % [dm.get_difficulty_name() if dm else "Standard", speed]

	# Find target cipher and puzzle state from active scene
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		var root = get_tree().current_scene
		var puzzle = root.find_child("PrimaryPuzzle", true, false)
		if puzzle:
			if "generated_code" in puzzle and puzzle.generated_code != "":
				if current_target_cipher != puzzle.generated_code:
					current_target_cipher = puzzle.generated_code
					input_buffer = ""
					is_unlocked = false
			
			if puzzle.is_completed:
				is_unlocked = true
			else:
				is_unlocked = false

	if is_unlocked:
		if entered_display:
			entered_display.text = "POINTER DEREFERENCED! CORRIDOR BLAST DOOR UNLOCKED [ OK ]"
			entered_display.add_theme_color_override("font_color", Color(0.1, 1.0, 0.4, 1.0))
		if btn_dereference:
			btn_dereference.text = "[ STATUS: BLAST DOOR UNLOCKED & ARMED ]"
	else:
		if btn_dereference:
			btn_dereference.text = "[ DEREFERENCE MEMORY POINTER ]"
		if entered_display:
			entered_display.remove_theme_color_override("font_color")
		_update_buffer_display()

	if cipher_display:
		cipher_display.text = "TARGET MEMORY CIPHER: [ %s ]  <-- (ENTER THIS KEY INTO REGISTER)" % current_target_cipher

	if dev_notes:
		dev_notes.text = "[INSTRUCTION]: Enter hex characters [ %s ] using the on-screen buttons or keyboard, then press ENTER or click Dereference to open the blast door." % current_target_cipher

func _on_close_pressed() -> void:
	toggle_terminal()

func _play_beep(pitch_hz: float = 880.0, duration: float = 0.05) -> void:
	if not is_inside_tree():
		return
	var sample_rate = 22050

	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var val = sin(t * pitch_hz * TAU) * 0.4 * (1.0 - float(i) / num_samples)
		data[i] = int(clampf(val * 127.0 + 128.0, 0, 255))
	wav.data = data
	var player = AudioStreamPlayer.new()
	player.stream = wav
	player.volume_db = -10.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
