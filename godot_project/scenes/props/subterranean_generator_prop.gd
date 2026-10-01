extends Node3D
class_name SubterraneanGeneratorProp

# Sub-Routine Multi-Component Puzzle: Subterranean Auxiliary Generator
# Heavy industrial dynamo that requires three distinct components to restore power:
# 1. Transformer Relay (generator_part_relay)
# 2. Coolant Compression Cell (generator_part_coolant)
# 3. Heavy Magnetic Fuse (generator_part_fuse)
#
# When repaired, spools up with industrial turbine audio, shifts status lights green,
# powers secondary blast locks, and activates ascension lifts.

signal component_inserted(part_key: String, count: int)
signal generator_powered

@export var generator_id: String = "aux_generator_primary"
@export var target_door: Node3D = null # BlastDoor to unlock on power restoration

var REQUIRED_PARTS = ["generator_part_relay", "generator_part_coolant", "generator_part_fuse"]
var installed_parts: Array[String] = []
var direct_inventory: Array = []
var is_running: bool = false
var is_in_range: bool = false

var audio_install: AudioStreamPlayer = null
var audio_spool: AudioStreamPlayer = null
var prompt_label: Label3D = null
var status_light: OmniLight3D = null

func _ready() -> void:
	# Load generator model
	var glb_path = "res://assets/models/subterranean_generator.glb"
	if ResourceLoader.exists(glb_path):
		var scene_res = ResourceLoader.load(glb_path)
		if scene_res is PackedScene:
			var inst = scene_res.instantiate()
			inst.name = "GeneratorModel"
			add_child(inst)

	audio_install = AudioStreamPlayer.new()
	audio_install.name = "InstallAudio"
	audio_install.bus = "Master"
	add_child(audio_install)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_part_install.wav"):
		audio_install.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_part_install.wav")

	audio_spool = AudioStreamPlayer.new()
	audio_spool.name = "SpoolAudio"
	audio_spool.bus = "Master"
	add_child(audio_spool)
	if ResourceLoader.exists("res://assets/audio/sfx/sfx_generator_start.wav"):
		audio_spool.stream = ResourceLoader.load("res://assets/audio/sfx/sfx_generator_start.wav")

	prompt_label = Label3D.new()
	prompt_label.text = "[E] AUXILIARY GENERATOR (OFFLINE)"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.font_size = 22
	prompt_label.modulate = Color(1.0, 0.4, 0.2, 0.9)
	prompt_label.position = Vector3(0.0, 2.3, 0.6)
	prompt_label.visible = false
	add_child(prompt_label)

	status_light = OmniLight3D.new()
	status_light.light_color = Color(1.0, 0.15, 0.1) # Red offline
	status_light.light_energy = 1.2
	status_light.omni_range = 6.0
	status_light.position = Vector3(0.0, 1.4, 0.8)
	add_child(status_light)

	# Check persistent state in LevelManager
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if "installed_generator_parts" in lm:
			installed_parts.clear()
			var raw_parts = lm.get("installed_generator_parts")
			if raw_parts is Array:
				for p in raw_parts:
					installed_parts.append(str(p))
		if "is_generator_running" in lm and lm.get("is_generator_running"):
			_power_on(true)

	var area = find_child("InteractArea", true, false) as Area3D
	if area:
		area.body_entered.connect(_on_player_entered)
		area.body_exited.connect(_on_player_exited)

func _on_player_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = true
		_update_prompt()
		if prompt_label:
			prompt_label.visible = true

func _on_player_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name == "RoxyVance":
		is_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _update_prompt() -> void:
	if not prompt_label:
		return
	if is_running:
		prompt_label.text = "AUXILIARY TURBINE ONLINE (100% POWER)"
		prompt_label.modulate = Color(0.2, 1.0, 0.4, 0.9)
	else:
		prompt_label.text = "[E] INSTALL COMPONENTS (%d/3 INSTALLED)" % installed_parts.size()
		prompt_label.modulate = Color(1.0, 0.6, 0.2, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if is_in_range and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if is_running:
		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message("[ AUXILIARY GENERATOR: ACTIVE ]\nPower output nominal. Heavy blast door conduits energized.", "overseer_generator_restored")
		return

	# Check player inventory in direct_inventory or LevelManager
	var inventory: Array = []
	if direct_inventory.size() > 0:
		inventory = direct_inventory
	elif is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if "generator_parts" in lm:
			inventory = lm.get("generator_parts")

	# Find any uninstalled part in inventory
	var part_to_install = ""
	for part in REQUIRED_PARTS:
		if not installed_parts.has(part) and inventory.has(part):
			part_to_install = part
			break

	if not part_to_install.is_empty():
		# Install one part
		installed_parts.append(part_to_install)
		inventory.erase(part_to_install)
		if direct_inventory.size() > 0:
			direct_inventory = inventory
		
		# Persist to LevelManager
		if is_inside_tree() and has_node("/root/LevelManager"):
			var lm = get_node("/root/LevelManager")
			lm.set("installed_generator_parts", installed_parts)
			lm.set("generator_parts", inventory)

		if audio_install and audio_install.stream:
			audio_install.play()

		component_inserted.emit(part_to_install, installed_parts.size())
		
		var clean_name = part_to_install.replace("generator_part_", "").capitalize()
		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("update_objective"):
			hud.update_objective("Installed %s (%d/3 Components)" % [clean_name, installed_parts.size()])

		_update_prompt()

		# Check if now complete!
		if installed_parts.size() >= REQUIRED_PARTS.size():
			_power_on(false)
	else:
		# Player doesn't have the required missing parts
		var missing_names: Array[String] = []
		for part in REQUIRED_PARTS:
			if not installed_parts.has(part):
				missing_names.append(part.replace("generator_part_", "").capitalize())

		var hud = null
		if is_inside_tree() and get_tree() and get_tree().root:
			hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			var msg = "[ AUXILIARY TURBINE: OFFLINE ]\nRequires %d more component(s):\n%s" % [missing_names.size(), ", ".join(missing_names)]
			hud.display_overseer_message(msg, "overseer_generator_need_parts")
		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("generator_need_parts")

func _power_on(silent: bool = false) -> void:
	is_running = true
	if is_inside_tree() and has_node("/root/LevelManager"):
		get_node("/root/LevelManager").set("is_generator_running", true)

	if status_light:
		status_light.light_color = Color(0.1, 0.95, 0.35) # Bright emerald green
		status_light.light_energy = 2.4

	_update_prompt()

	if not silent:
		if audio_spool and audio_spool.stream:
			audio_spool.play()

		# Camera trauma shake on turbine rumble
		if is_inside_tree() and get_tree() and get_tree().root:
			var player = get_tree().root.find_child("RoxyVance", true, false)
			if player and player.has_method("apply_trauma"):
				player.apply_trauma(0.45)

		if is_inside_tree() and has_node("/root/TheOverseer"):
			get_node("/root/TheOverseer").trigger_dialogue("generator_restored")

	# Unlock blast door if connected
	if target_door and target_door.has_method("unlock_door"):
		target_door.unlock_door()
	elif target_door and "is_locked" in target_door:
		target_door.is_locked = false

	generator_powered.emit()
