extends Node

# Sub-Routine Persistent Save & Checkpoint Manager
# Handles saving and loading player state, sector progression, inventory, and EMP tier.
# In HTML5/Web exports, user:// maps automatically to browser IndexedDB,
# enabling game progress to persist across browser refreshes.

signal game_saved(checkpoint_name: String)
signal game_loaded(level_index: int)
signal checkpoint_cleared

const SAVE_PATH: String = "user://subroutine_save.json"

var is_loading_save: bool = false
var last_saved_checkpoint: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(checkpoint_name: String = "") -> bool:
	var level_idx = 1
	var lm = get_node_or_null("/root/LevelManager")
	if lm:
		level_idx = lm.current_level_index

	var player = null
	if is_inside_tree() and get_tree().root:
		player = get_tree().root.find_child("RoxyVance", true, false)

	var hp = 100
	var max_hp = 100
	var stamina = 100.0
	var emp_lvl = 1

	if player:
		hp = player.current_health
		max_hp = player.max_health
		stamina = player.current_stamina
		emp_lvl = player.emp_upgrade_level
	elif lm and "emp_upgrade_level" in lm:
		emp_lvl = lm.emp_upgrade_level

	var gen_parts = []
	var sing_parts = []
	if lm:
		gen_parts = lm.generator_parts.duplicate()
		sing_parts = lm.singularity_parts.duplicate()

	var cp_name = checkpoint_name
	if cp_name == "":
		cp_name = "Sector %02d Checkpoint" % level_idx
	last_saved_checkpoint = cp_name

	var save_dict = {
		"version": 1,
		"level_index": level_idx,
		"checkpoint_name": cp_name,
		"health": hp,
		"max_health": max_hp,
		"stamina": stamina,
		"emp_upgrade_level": emp_lvl,
		"generator_parts": gen_parts,
		"singularity_parts": sing_parts,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open save file for writing: " + SAVE_PATH)
		return false

	var json_str = JSON.stringify(save_dict, "  ")
	file.store_string(json_str)
	file.close()

	print("[SaveManager] Checkpoint SAVED successfully: ", cp_name, " (Sector ", level_idx, ")")
	game_saved.emit(cp_name)
	_show_hud_save_toast(cp_name)
	return true

func load_game() -> bool:
	if not has_save_file():
		print("[SaveManager] No save file found.")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_str = file.get_as_text()
	file.close()

	var test_json = JSON.new()
	var err = test_json.parse(json_str)
	if err != OK:
		push_error("[SaveManager] Failed to parse save file JSON.")
		return false

	var data = test_json.data
	if not (data is Dictionary):
		return false

	is_loading_save = true
	var target_lvl = int(data.get("level_index", 1))
	var lm = get_node_or_null("/root/LevelManager")
	if lm:
		lm.emp_upgrade_level = int(data.get("emp_upgrade_level", 1))
		lm.generator_parts = data.get("generator_parts", [])
		lm.singularity_parts = data.get("singularity_parts", [])
		lm.load_level(target_lvl)

	var tree = get_tree()
	if tree and tree.root:
		var player = tree.root.find_child("RoxyVance", true, false)
		if player:
			player.current_health = int(data.get("health", 100))
			player.max_health = int(data.get("max_health", 100))
			player.current_stamina = float(data.get("stamina", 100.0))
			if player.has_method("set_emp_upgrade_level"):
				player.set_emp_upgrade_level(int(data.get("emp_upgrade_level", 1)))

	is_loading_save = false
	print("[SaveManager] Game LOADED successfully: Sector ", target_lvl)
	game_loaded.emit(target_lvl)
	return true

func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_PATH)
		last_saved_checkpoint = ""
		checkpoint_cleared.emit()
		print("[SaveManager] Save file deleted.")

func _show_hud_save_toast(checkpoint_name: String) -> void:
	if is_inside_tree() and get_tree().root:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ CHECKPOINT SAVED ]\n%s preserved in local memory." % checkpoint_name,
				""
			)
