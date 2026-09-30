extends Node3D
class_name BlastDoorProp

# Subterranean Hydraulic Bulkhead Security Gate Prop
# Blocks corridors until register puzzles are solved or keys collected

signal door_opened
signal door_closed

@export var is_open: bool = false
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

var door_frame: Node3D = null
var door_leaf_l: Node3D = null
var door_leaf_r: Node3D = null

var initial_leaf_l_x: float = -0.75
var initial_leaf_r_x: float = 0.75
var door_tween: Tween = null

func _ready() -> void:
	door_frame = find_child("DoorFrame", true, false) as Node3D
	door_leaf_l = find_child("DoorLeaf_L", true, false) as Node3D
	door_leaf_r = find_child("DoorLeaf_R", true, false) as Node3D
	
	if door_leaf_l:
		initial_leaf_l_x = door_leaf_l.position.x
	if door_leaf_r:
		initial_leaf_r_x = door_leaf_r.position.x
	
	if is_open:
		open_door(true)
	else:
		_update_status_lamp(false)

func open_door(immediate: bool = false) -> void:
	if is_open and not immediate:
		return
	is_open = true
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	_update_status_lamp(true)
	_play_hydraulic_sound()
	
	if immediate:
		if door_leaf_l:
			door_leaf_l.position.x = initial_leaf_l_x - 1.5
		if door_leaf_r:
			door_leaf_r.position.x = initial_leaf_r_x + 1.5
	else:
		if door_tween and door_tween.is_valid():
			door_tween.kill()
		door_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if door_leaf_l:
			door_tween.tween_property(door_leaf_l, "position:x", initial_leaf_l_x - 1.5, 1.2)
		if door_leaf_r:
			door_tween.tween_property(door_leaf_r, "position:x", initial_leaf_r_x + 1.5, 1.2)
	
	door_opened.emit()
	print("[BlastDoor] Bulkhead blast door unlocked. Heavy leaves retracted into frame pockets.")

func close_door(immediate: bool = false) -> void:
	is_open = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	_update_status_lamp(false)
	
	if immediate:
		if door_leaf_l:
			door_leaf_l.position.x = initial_leaf_l_x
		if door_leaf_r:
			door_leaf_r.position.x = initial_leaf_r_x
	else:
		if door_tween and door_tween.is_valid():
			door_tween.kill()
		door_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		if door_leaf_l:
			door_tween.tween_property(door_leaf_l, "position:x", initial_leaf_l_x, 0.8)
		if door_leaf_r:
			door_tween.tween_property(door_leaf_r, "position:x", initial_leaf_r_x, 0.8)
			
	door_closed.emit()
	print("[BlastDoor] Bulkhead blast door sealed.")

func _update_status_lamp(unlocked: bool) -> void:
	var lamp = find_child("status_lamp", true, false)
	if not lamp:
		lamp = find_child("DoorFrame", true, false)
	if lamp and lamp is MeshInstance3D:
		var mat = lamp.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission = Color(0.1, 1.0, 0.3) if unlocked else Color(1.0, 0.1, 0.1)

func _play_hydraulic_sound() -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.35
	var player = AudioStreamPlayer3D.new()
	player.stream = gen
	player.unit_size = 12.0
	add_child(player)
	player.play()
	var pb = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb:
		var frames = int(gen.mix_rate * 0.3)
		for i in range(frames):
			var t = float(i) / gen.mix_rate
			var noise = (randf() * 2.0 - 1.0) * (1.0 - t / 0.3) * 0.2
			var hum = sin(t * 120.0 * TAU) * 0.15 * (1.0 - t / 0.3)
			pb.push_frame(Vector2(noise + hum, noise + hum))
	get_tree().create_timer(0.4).timeout.connect(player.queue_free)
