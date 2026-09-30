extends Node3D
class_name SecurityKeypadProp

# Wall-Mounted Facility Security Keypad
# Controls blast doors; requires code found in auxiliary sector rooms.

signal keypad_interacted

@export var door_path: NodePath
@export var is_unlocked: bool = false

@onready var status_led: OmniLight3D = $StatusLED
@onready var led_mesh: MeshInstance3D = $KeypadBox/LedMesh

func _ready() -> void:
	add_to_group("interactive_props")
	_update_led_state()

func interact(player: CharacterBody3D = null) -> void:
	print("[SecurityKeypad] Player interacted with gate keypad.")
	keypad_interacted.emit()

	if is_unlocked:
		if is_inside_tree():
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("display_overseer_message"):
				hud.display_overseer_message("SECURITY GATE: ACCESS GRANTED [Door Armed]", "")
		return

	# Open the Subroutine Terminal keypad interface
	if is_inside_tree():
		var terminal = get_tree().root.find_child("SubroutineTerminal", true, false)
		if terminal and terminal.has_method("show_terminal"):
			terminal.show_terminal()

func unlock_gate() -> void:
	is_unlocked = true
	_update_led_state()

	if door_path and not door_path.is_empty():
		var door = get_node_or_null(door_path)
		if door and door.has_method("open_door"):
			door.open_door()
	else:
		var parent = get_parent()
		if parent:
			var door = parent.find_child("BlastDoor", true, false)
			if door and door.has_method("open_door"):
				door.open_door()

func _update_led_state() -> void:
	if status_led:
		status_led.light_color = Color(0.2, 1.0, 0.3) if is_unlocked else Color(1.0, 0.2, 0.2)
		status_led.light_energy = 1.6
	if led_mesh and led_mesh.material_override is StandardMaterial3D:
		var mat = led_mesh.material_override as StandardMaterial3D
		mat.emission = Color(0.2, 1.0, 0.3) if is_unlocked else Color(1.0, 0.2, 0.2)
