extends Area3D
class_name ClimbableLadderProp

# Climbable Ladder Prop for Vertical Elevator Shaft & Gantry Maintenance
# Engages ladder climb physics in RoxyVance when within the ladder volume.

signal player_climbed_ladder(height_reached: float)

@export var ladder_height: float = 18.0
var active_climber: RoxyVance = null
var climb_sfx_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_rungs()

func _build_rungs() -> void:
	var rung_mat = StandardMaterial3D.new()
	rung_mat.albedo_color = Color(0.8, 0.85, 0.9, 1.0)
	rung_mat.metallic = 0.85
	rung_mat.roughness = 0.35
	rung_mat.emission_enabled = true
	rung_mat.emission = Color(0.2, 0.6, 0.8, 1.0)
	rung_mat.emission_energy_multiplier = 0.5

	var rung_mesh = BoxMesh.new()
	rung_mesh.size = Vector3(0.68, 0.04, 0.04)
	rung_mesh.material = rung_mat

	var num_rungs = int(ladder_height * 2.0)
	for i in range(1, num_rungs):
		var rung = MeshInstance3D.new()
		rung.name = "Rung_%d" % i
		rung.mesh = rung_mesh
		rung.position = Vector3(0.0, float(i) * 0.5, 0.0)
		add_child(rung)

func _on_body_entered(body: Node3D) -> void:
	if body is RoxyVance or body.has_method("set_on_ladder"):
		active_climber = body as RoxyVance
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(true, self)
		print("[ClimbableLadder] Roxy Vance mounted vertical maintenance ladder.")
		if is_inside_tree():
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("display_overseer_message"):
				hud.display_overseer_message("[LADDER] [W] Climb Up / [S] Climb Down", "")

func _on_body_exited(body: Node3D) -> void:
	if body == active_climber:
		if body.has_method("set_on_ladder"):
			body.set_on_ladder(false, null)
		player_climbed_ladder.emit(body.global_position.y)
		print("[ClimbableLadder] Roxy Vance dismounted ladder at Y = ", body.global_position.y)
		active_climber = null

func _process(delta: float) -> void:
	if active_climber and is_instance_valid(active_climber):
		if abs(active_climber.velocity.y) > 0.3:
			climb_sfx_timer -= delta
			if climb_sfx_timer <= 0.0:
				_play_climb_sound()
				climb_sfx_timer = 0.38

func _play_climb_sound() -> void:
	if not is_inside_tree() or not ResourceLoader.exists("res://assets/audio/sfx/sfx_ladder_climb.wav"):
		return
	var p = AudioStreamPlayer3D.new()
	p.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_ladder_climb.wav")
	p.volume_db = -8.0
	p.max_distance = 16.0
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
