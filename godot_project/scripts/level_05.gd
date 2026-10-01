extends Node3D
class_name Level05Sector

# Sector 05: Executive Overlook & Sub-Core Tram Hub
# Architectural Hub connecting Sector 04 (via Elevator Hoist) to Sector 06 (via MagLev Tram).
# Features:
# - Executive Observation Gallery overlooking the abyss
# - Bio-Synthetic Research Bay with Stasis Pods, Glitch Walker stalker, and Stealth Locker
# - Environmental casualties (Executive Director Sterling & Lead Researcher Dr. Mercer)
# - Tram departure decryption mechanics leading to Sector 06

const TramDepartureConsoleProp = preload("res://scenes/props/tram_departure_console_prop.gd")

var is_tram_decrypted: bool = false

@onready var tram_console = find_child("TramDepartureConsole", true, false)
@onready var decryption_terminal: Node3D = find_child("TramDecryptionTerminal", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_05] Executive Overlook & Sub-Core Tram Hub initialized.")
	
	# Initial Overseer greeting and objective
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Explore Executive Overlook. Decrypt Tram Override in Bio-Synthetic Research Bay.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"level_05_arrival",
			"Sector 05: Executive Overlook. The highest tier of the Sub-Routine facility... and the quietest cemetery."
		)

	# Connect Decryption Terminal
	if decryption_terminal and decryption_terminal.has_signal("terminal_accessed"):
		decryption_terminal.connect("terminal_accessed", _on_terminal_accessed)
	elif decryption_terminal and decryption_terminal.has_signal("interacted"):
		decryption_terminal.connect("interacted", _on_terminal_accessed)

func decrypt_tram_departure() -> void:
	if is_tram_decrypted:
		return
	is_tram_decrypted = true
	print("[Level_05] Tram departure sequence DECRYPTED!")

	if not tram_console:
		tram_console = find_child("TramDepartureConsole", true, false)
	if tram_console:
		tram_console.authorize_departure()

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ TRAM OVERRIDE DECRYPTED: 704-DELTA ]\nMagLev Tram 01 authorized for departure to Sector 06.",
			"overseer_generator_restored"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Board Escape Tram at Sub-Core Tram Hub (North Station).")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"tram_decrypted",
			"Decryption acknowledged. The tram clamps have disengaged. Now get to the departure platform before the Glitch Walkers sever the tracks."
		)

func _on_terminal_accessed(_user_data = null) -> void:
	decrypt_tram_departure()
