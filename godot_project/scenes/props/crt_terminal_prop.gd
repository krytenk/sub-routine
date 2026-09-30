extends Node3D
class_name CRTTerminalProp

# Interactive Subroutine CRT Terminal Prop
# Displays crt_terminal.glb and emits interaction trigger to open Subroutine Terminal UI

signal terminal_accessed

@onready var interaction_area: Area3D = $InteractionArea
@onready var prompt_label: Label3D = $PromptLabel

var is_player_in_range: bool = false

func _ready() -> void:
	add_to_group("terminals")
	add_to_group("interactive_props")
	if prompt_label:
		prompt_label.visible = false
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if is_player_in_range and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		is_player_in_range = true
		if prompt_label:
			prompt_label.visible = true
		print("[CRTTerminal] Player entered terminal console range.")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.has_method("take_damage"):
		is_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func interact(_player: CharacterBody3D = null) -> void:
	print("[CRTTerminal] Subroutine Terminal opened by player.")
	terminal_accessed.emit()
	var term = null
	if is_inside_tree():
		if has_node("/root/Main/SubroutineTerminal"):
			term = get_node("/root/Main/SubroutineTerminal")
		else:
			term = get_tree().root.find_child("SubroutineTerminal", true, false)

	if term:
		if term.has_method("show_terminal"):
			term.show_terminal()
		else:
			term.visible = true
