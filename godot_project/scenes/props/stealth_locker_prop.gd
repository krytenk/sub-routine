extends StaticBody3D
class_name StealthLockerProp

# Stealth Locker Prop
# High-tensile server cabinet / utility locker.
# Allows Roxy Vance to conceal herself from stalker AI and evade pursuit.

signal player_entered_locker
signal player_exited_locker

@onready var inside_marker: Marker3D = $InsideAnchor
@onready var exit_marker: Marker3D = $ExitAnchor
@onready var door_leaf: Node3D = $DoorLeaf
@onready var status_light: OmniLight3D = $StatusLight

var occupant: RoxyVance = null
var is_occupied: bool = false
var door_open_angle: float = deg_to_rad(85.0)

func _ready() -> void:
	add_to_group("interactive_props")
	if not inside_marker:
		inside_marker = Marker3D.new()
		inside_marker.name = "InsideAnchor"
		inside_marker.position = Vector3(0, 0, 0)
		add_child(inside_marker)
	if not exit_marker:
		exit_marker = Marker3D.new()
		exit_marker.name = "ExitAnchor"
		exit_marker.position = Vector3(0, 0, 1.2)
		add_child(exit_marker)

func interact(user: Node3D) -> void:
	if not (user is RoxyVance):
		return

	var player = user as RoxyVance

	if not is_occupied:
		_enter_locker(player)
	elif occupant == player:
		_exit_locker()

func _enter_locker(player: RoxyVance) -> void:
	is_occupied = true
	occupant = player
	player.set_hiding(true)
	if not inside_marker:
		inside_marker = find_child("InsideAnchor", true, false) as Marker3D
	var in_pos = inside_marker.global_position if inside_marker else global_position
	player.global_position = in_pos
	if is_inside_tree():
		player.rotation.y = global_rotation.y + PI
	
	if status_light:
		status_light.light_color = Color(0.2, 0.8, 0.3, 1)

	_play_audio("res://assets/audio/sfx/sfx_stealth_enter.wav", -4.0)

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue(
			"stealth_locker",
			"Hiding inside a server locker? Classic survival horror trope. Just pray the garbage collector doesn't purge this container."
		)

	if is_inside_tree():
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message("[CONCEALED] Press [E] to step out of locker", "")

	player_entered_locker.emit()
	print("[StealthLocker] Player concealed within storage locker.")

func _exit_locker() -> void:
	if not occupant:
		return

	var player = occupant
	occupant = null
	is_occupied = false
	player.set_hiding(false)
	if not exit_marker:
		exit_marker = find_child("ExitAnchor", true, false) as Marker3D
	var out_pos = exit_marker.global_position if exit_marker else (global_position + Vector3(0, 0, 1.2))
	player.global_position = out_pos

	if status_light:
		status_light.light_color = Color(0.8, 0.4, 0.1, 1)

	_play_audio("res://assets/audio/sfx/sfx_stealth_exit.wav", -6.0)

	if is_inside_tree():
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message("[EXPOSED] Concealment disengaged", "")

	player_exited_locker.emit()
	print("[StealthLocker] Player exited storage locker.")

func _play_audio(path: String, vol: float = 0.0) -> void:
	if not is_inside_tree() or not ResourceLoader.exists(path):
		return
	var p = AudioStreamPlayer3D.new()
	p.stream = ResourceLoader.load(path)
	p.volume_db = vol
	p.max_distance = 18.0
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
