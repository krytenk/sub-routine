extends Area3D
class_name NaniteMedkitProp

# Nanite Medical Syringe / Health Replenishment Prop
# Survival horror consumable found in side rooms to restore Roxy's health.

signal medkit_collected(heal_amount: int)

@export var heal_amount: int = 50
@onready var model_node: Node3D = $Model

var hover_phase: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	hover_phase += delta * 3.0
	if model_node:
		model_node.rotate_y(2.4 * delta)
		model_node.position.y = 0.4 + sin(hover_phase) * 0.08

func _on_body_entered(body: Node3D) -> void:
	if body is RoxyVance or body.has_method("heal"):
		print("[NaniteMedkit] Medical injector retrieved! Restoring ", heal_amount, " HP.")
		if body.has_method("heal"):
			body.heal(heal_amount)
		medkit_collected.emit(heal_amount)

		_play_inject_sound()

		if is_inside_tree():
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud and hud.has_method("display_overseer_message"):
				hud.display_overseer_message("NANITE INJECTOR: +%d HP [Cell Integrity Restored]" % heal_amount, "")

		queue_free()

func _play_inject_sound() -> void:
	if not is_inside_tree():
		return
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var freq = lerpf(600.0, 1200.0, float(i) / num_samples)
		var val = sin(t * freq * TAU) * 0.35 * (1.0 - float(i) / num_samples)
		data[i] = int(clampf(val * 127.0 + 128.0, 0, 255))
	wav.data = data
	var player = AudioStreamPlayer.new()
	player.stream = wav
	player.volume_db = -8.0
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
