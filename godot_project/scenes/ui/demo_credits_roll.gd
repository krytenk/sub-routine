extends Control
class_name DemoCreditsRoll

# Sub-Routine Early Access Demo Roll Credits & Feedback Screen
# Displayed upon clearing Sector 09, thanking the player, showing stats,
# and providing feedback links.

@onready var restart_btn: Button = find_child("RestartBtn", true, false)
@onready var checkpoint_btn: Button = find_child("CheckpointBtn", true, false)
@onready var copy_link_btn: Button = find_child("CopyLinkBtn", true, false)
@onready var stats_label: Label = find_child("StatsLabel", true, false)
@onready var status_msg: Label = find_child("StatusMsg", true, false)

const GITHUB_URL = "https://github.com/krytenk/sub-routine"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_populate_stats()

	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if checkpoint_btn:
		checkpoint_btn.pressed.connect(_on_checkpoint_pressed)
	if copy_link_btn:
		copy_link_btn.pressed.connect(_on_copy_link_pressed)

func _populate_stats() -> void:
	var emp_lvl = 5
	var lm = get_node_or_null("/root/LevelManager")
	if lm and "emp_upgrade_level" in lm:
		emp_lvl = lm.emp_upgrade_level

	var stats_text = "SECTORS CONQUERED: 12 / 12 (Act I Complete)\n"
	stats_text += "EMP ARSENAL: MK %s (Zero-Point Resonant Core)\n" % ("V" if emp_lvl >= 5 else "IV")
	stats_text += "MAJOR ANOMALIES SURVIVED: Dredge Titan, Arch-Compiler Goliath, Kernel Warden Avatar\n"
	stats_text += "FACILITY STATUS: Sub-Routine Core Threshold Breached // Act I Complete"

	if stats_label:
		stats_label.text = stats_text

func _on_restart_pressed() -> void:
	print("[Credits] Restarting campaign from Sector 01...")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var lm = get_node_or_null("/root/LevelManager")
	if lm:
		lm.pending_restart_campaign = true
		if lm.has_method("reset_campaign_state"):
			lm.reset_campaign_state()
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_checkpoint_pressed() -> void:
	print("[Credits] Returning to saved Checkpoint...")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var lm = get_node_or_null("/root/LevelManager")
	if lm:
		lm.pending_checkpoint_reload = true
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_copy_link_pressed() -> void:
	DisplayServer.clipboard_set(GITHUB_URL)
	if status_msg:
		status_msg.text = "[ LINK COPIED TO CLIPBOARD! Share your feedback on GitHub. ]"
		status_msg.modulate = Color(0.2, 1.0, 0.4, 1.0)
