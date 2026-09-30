extends Node3D
class_name BrokenElectronicsLight

# Atmospheric Horror Electronics Lighting Controller
# Simulates short-circuiting server racks, sparking fuse boxes, buzzing cathode tubes,
# and dying fluorescent tubes with dynamic shadow casting for tension and creature silhouettes.

enum LightMode {
	SPARK_BURST,          # Electric blue/white arcs, sudden violent flashes, casts fleeting sharp shadows
	PHOSPHOR_BUZZ,        # Sickly CRT green/cyan scanline jitter with subtle high-freq micro-flicker
	AMBER_VACUUM,         # Deep orange/amber breathing glow from floor vacuum tubes and power inverters
	FLUORESCENT_STUTTER   # Industrial overhead tube ballast stuttering and dying with brownouts
}

@export var mode: LightMode = LightMode.SPARK_BURST
@export var base_color: Color = Color(0.35, 0.75, 1.0, 1.0)
@export var base_energy: float = 0.8
@export var peak_energy: float = 3.8
@export var light_range: float = 9.0
@export var enable_shadows: bool = true
@export var min_spark_interval: float = 2.5
@export var max_spark_interval: float = 6.0

@onready var omni_light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null
@onready var spark_particles: CPUParticles3D = $SparkParticles if has_node("SparkParticles") else null
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D if has_node("AudioStreamPlayer3D") else null

var time_passed: float = 0.0
var spark_timer: float = 0.0
var is_sparking: bool = false
var spark_burst_frames_left: int = 0
var noise_seed: float = 0.0

func _ready() -> void:
	noise_seed = randf() * 1000.0
	spark_timer = randf_range(min_spark_interval * 0.5, min_spark_interval)

	if not omni_light:
		omni_light = OmniLight3D.new()
		omni_light.name = "OmniLight3D"
		add_child(omni_light)

	omni_light.light_color = base_color
	omni_light.light_energy = base_energy
	omni_light.omni_range = light_range
	omni_light.omni_attenuation = 1.6
	omni_light.shadow_enabled = enable_shadows
	if enable_shadows:
		omni_light.shadow_bias = 0.08
		omni_light.shadow_normal_bias = 1.0

	# Ensure particle sparks are present for spark burst modes
	if mode == LightMode.SPARK_BURST and not spark_particles:
		_setup_spark_particles()

	# Audio configuration
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioStreamPlayer3D"
		audio_player.max_distance = 12.0
		audio_player.unit_size = 3.0
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(audio_player)

	if mode == LightMode.AMBER_VACUUM or mode == LightMode.PHOSPHOR_BUZZ:
		var hum_stream = load("res://assets/audio/sfx/sfx_capacitor_hum.wav")
		if hum_stream and audio_player:
			audio_player.stream = hum_stream
			audio_player.volume_db = -18.0
			audio_player.pitch_scale = randf_range(0.95, 1.05)
			audio_player.play()

func _setup_spark_particles() -> void:
	spark_particles = CPUParticles3D.new()
	spark_particles.name = "SparkParticles"
	spark_particles.emitting = false
	spark_particles.one_shot = true
	spark_particles.amount = 18
	spark_particles.lifetime = 0.4
	spark_particles.explosiveness = 0.95
	spark_particles.direction = Vector3(0, -1, 0)
	spark_particles.spread = 65.0
	spark_particles.initial_velocity_min = 2.0
	spark_particles.initial_velocity_max = 5.5
	spark_particles.gravity = Vector3(0, -9.8, 0)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = base_color
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = 4.0

	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	sphere.material = mat
	spark_particles.mesh = sphere
	add_child(spark_particles)

func _process(delta: float) -> void:
	time_passed += delta

	if not omni_light:
		return

	match mode:
		LightMode.SPARK_BURST:
			_process_spark_burst(delta)
		LightMode.PHOSPHOR_BUZZ:
			_process_phosphor_buzz(delta)
		LightMode.AMBER_VACUUM:
			_process_amber_vacuum(delta)
		LightMode.FLUORESCENT_STUTTER:
			_process_fluorescent_stutter(delta)

func _process_spark_burst(delta: float) -> void:
	if is_sparking:
		spark_burst_frames_left -= 1
		if spark_burst_frames_left > 0:
			# Violent jitter between zero and peak energy
			var jitter = randf()
			if jitter > 0.4:
				omni_light.light_energy = randf_range(peak_energy * 0.7, peak_energy)
			else:
				omni_light.light_energy = base_energy * 0.2
		else:
			is_sparking = false
			omni_light.light_energy = base_energy
			spark_timer = randf_range(min_spark_interval, max_spark_interval)
	else:
		spark_timer -= delta
		# Low residual resting flicker
		var rest_flicker = sin(time_passed * 12.0 + noise_seed) * 0.08
		omni_light.light_energy = maxf(0.05, base_energy + rest_flicker)

		if spark_timer <= 0.0:
			_trigger_spark_event()

func _trigger_spark_event() -> void:
	is_sparking = true
	spark_burst_frames_left = randi_range(6, 14)
	omni_light.light_energy = peak_energy

	if spark_particles:
		spark_particles.restart()
		spark_particles.emitting = true

	if audio_player:
		var spark_stream = load("res://assets/audio/sfx/sfx_electric_spark.wav")
		if spark_stream:
			audio_player.stream = spark_stream
			audio_player.volume_db = -8.0
			audio_player.pitch_scale = randf_range(0.85, 1.25)
			audio_player.play()

func _process_phosphor_buzz(delta: float) -> void:
	# Subtle 60Hz cathode buzz with random micro-dropouts
	var hf_buzz = sin(time_passed * 120.0 * PI) * 0.08
	var scan_drift = sin(time_passed * 3.5 + noise_seed) * 0.15
	var dropout = 0.0
	if randf() < 0.02:
		dropout = -0.35
	omni_light.light_energy = clampf(base_energy + hf_buzz + scan_drift + dropout, 0.1, peak_energy)

func _process_amber_vacuum(delta: float) -> void:
	# Organic warmth breathing like hot vacuum tube filaments
	var slow_pulse = sin(time_passed * 2.2 + noise_seed) * 0.25
	var filament_flicker = (randf() - 0.5) * 0.08
	omni_light.light_energy = clampf(base_energy + slow_pulse + filament_flicker, 0.1, peak_energy)

func _process_fluorescent_stutter(delta: float) -> void:
	# Aging fluorescent fixture with periodic brownout stutters
	var main_wave = sin(time_passed * 8.0) * 0.12
	var r = randf()
	if r < 0.015:
		# Brief total cutout
		omni_light.light_energy = 0.0
	elif r < 0.06:
		# Half voltage ballast stutter
		omni_light.light_energy = base_energy * 0.35
	else:
		omni_light.light_energy = clampf(base_energy + main_wave, 0.2, peak_energy)
