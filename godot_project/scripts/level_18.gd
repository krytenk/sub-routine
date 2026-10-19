extends Node3D
class_name Level18Sector

# Sector 18: Vance Manor — Grand Atrium & Portrait Gallery (Act III Gothic Estate)
# Situated directly above the Clinical Sanatorium Wing and the buried subterranean server core.
# Features:
# - High-Pressure Puzzle A (West Portrait Gallery & Grandfather Clock 45s Midnight Lockdown):
#   Taking the Gilded Raven Half-Crest from the West Gallery plinth triggers a 45-second
#   Grandfather Clock Midnight Chime Countdown and Portrait Gaze alert. Roxy must recover the
#   Lead Apothecary Weight and disarm the Grandfather Clock Pendulum Mechanism [E]!
# - High-Pressure Puzzle B (Cross-Sector Relic Payoff in East Conservatory & Secret Study):
#   1. Use the 440Hz Clinical Tuning Fork (from Sector 17) on the Grand Piano [E] to slide open
#      the Movable Bookcase into Julian Vance's Secret Study.
#   2. Use the Bottle of Silver Nitrate Developer (from Sector 17) on the Daguerreotype Glass Plate [E]
#      in the Secret Study to reveal the Crest Alignment Cipher.
#   3. Unite the Serpent Half-Crest (from Sector 17) + Raven Half-Crest (from Sector 18) at the
#      South Ballroom Crest Doors [E] to unseal the Grand Ballroom!

const CLOCK_LOCKDOWN_DURATION: float = 45.0

var has_silver_nitrate: bool = false
var has_tuning_fork: bool = false
var has_serpent_crest: bool = false
var has_raven_crest: bool = false
var has_lead_counterweight: bool = false

var is_clock_lockdown_active: bool = false
var is_clock_lockdown_disarmed: bool = false
var is_piano_chord_played: bool = false
var is_daguerreotype_developed: bool = false
var is_ballroom_unlocked: bool = false
var clock_countdown_timer: float = CLOCK_LOCKDOWN_DURATION
var midnight_tolls_triggered: int = 0

@onready var grandfather_clock_console: Node3D = find_child("GrandfatherClockConsole", true, false)
@onready var grand_piano_console: Node3D = find_child("GrandPianoConsole", true, false)
@onready var daguerreotype_console: Node3D = find_child("DaguerreotypePlateConsole", true, false)
@onready var ballroom_doors_terminal: Node3D = find_child("BallroomCrestDoorsTerminal", true, false)
@onready var movable_bookcase_mesh: Node3D = find_child("MovableBookcaseDoor", true, false)
@onready var clock_chime_light: OmniLight3D = find_child("Light_GrandfatherClock", true, false)
@onready var exit_door_mesh: Node3D = find_child("ExitBallroomCrestDoors", true, false)
@onready var exit_trigger: Area3D = find_child("Sector18BallroomExitTrigger", true, false)

func _ready() -> void:
	_init_level()

func _init_level() -> void:
	print("[Level_18] Vance Manor — Grand Atrium & Portrait Gallery initialized.")

	# Pull cross-sector relics carried over from Sector 17 via LevelManager
	_sync_from_level_manager()

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("VANCE MANOR: Tune the East Grand Piano [E], develop the Secret Study Daguerreotype, & claim the Raven Half-Crest.")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("welcome_sec18")

	var pickups_node = find_child("Pickups", true, false)
	if pickups_node:
		for child in pickups_node.get_children():
			if child.has_signal("relic_collected") and not child.is_connected("relic_collected", _on_relic_collected):
				child.connect("relic_collected", _on_relic_collected)

	if grandfather_clock_console:
		if grandfather_clock_console.has_signal("terminal_accessed") and not grandfather_clock_console.is_connected("terminal_accessed", _on_grandfather_clock_interacted):
			grandfather_clock_console.connect("terminal_accessed", _on_grandfather_clock_interacted)
		elif grandfather_clock_console.has_signal("interacted") and not grandfather_clock_console.is_connected("interacted", _on_grandfather_clock_interacted):
			grandfather_clock_console.connect("interacted", _on_grandfather_clock_interacted)

	if grand_piano_console:
		if grand_piano_console.has_signal("terminal_accessed") and not grand_piano_console.is_connected("terminal_accessed", _on_grand_piano_interacted):
			grand_piano_console.connect("terminal_accessed", _on_grand_piano_interacted)
		elif grand_piano_console.has_signal("interacted") and not grand_piano_console.is_connected("interacted", _on_grand_piano_interacted):
			grand_piano_console.connect("interacted", _on_grand_piano_interacted)

	if daguerreotype_console:
		if daguerreotype_console.has_signal("terminal_accessed") and not daguerreotype_console.is_connected("terminal_accessed", _on_daguerreotype_interacted):
			daguerreotype_console.connect("terminal_accessed", _on_daguerreotype_interacted)
		elif daguerreotype_console.has_signal("interacted") and not daguerreotype_console.is_connected("interacted", _on_daguerreotype_interacted):
			daguerreotype_console.connect("interacted", _on_daguerreotype_interacted)

	if ballroom_doors_terminal:
		if ballroom_doors_terminal.has_signal("terminal_accessed") and not ballroom_doors_terminal.is_connected("terminal_accessed", _on_ballroom_doors_interacted):
			ballroom_doors_terminal.connect("terminal_accessed", _on_ballroom_doors_interacted)
		elif ballroom_doors_terminal.has_signal("interacted") and not ballroom_doors_terminal.is_connected("interacted", _on_ballroom_doors_interacted):
			ballroom_doors_terminal.connect("interacted", _on_ballroom_doors_interacted)

func _sync_from_level_manager() -> void:
	if is_inside_tree() and has_node("/root/LevelManager"):
		var lm = get_node("/root/LevelManager")
		if lm.has_method("has_surface_relic"):
			if lm.has_surface_relic("silver_nitrate_developer"):
				has_silver_nitrate = true
			if lm.has_surface_relic("clinical_tuning_fork_440"):
				has_tuning_fork = true
			if lm.has_surface_relic("serpent_half_crest"):
				has_serpent_crest = true
			if lm.has_surface_relic("raven_half_crest"):
				has_raven_crest = true
			if lm.has_surface_relic("lead_apothecary_weight"):
				has_lead_counterweight = true

func grant_sector17_relics_for_testing() -> void:
	has_silver_nitrate = true
	has_tuning_fork = true
	has_serpent_crest = true

func _process(delta: float) -> void:
	if is_clock_lockdown_active and not is_clock_lockdown_disarmed and not is_ballroom_unlocked:
		clock_countdown_timer -= delta
		if clock_countdown_timer <= 0.0:
			_trigger_midnight_toll()

func _on_relic_collected(r_id: String) -> void:
	match r_id:
		"raven_half_crest":
			has_raven_crest = true
			_start_clock_lockdown_trap()
		"lead_apothecary_weight":
			has_lead_counterweight = true
			print("[Level_18] Lead Apothecary Counterweight collected!")
		"silver_nitrate_developer":
			has_silver_nitrate = true
		"clinical_tuning_fork_440":
			has_tuning_fork = true
		"serpent_half_crest":
			has_serpent_crest = true
	_refresh_hud_objective()

func _start_clock_lockdown_trap() -> void:
	if is_clock_lockdown_disarmed:
		return
	is_clock_lockdown_active = true
	clock_countdown_timer = CLOCK_LOCKDOWN_DURATION
	print("[Level_18] RAVEN HALF-CREST LIFTED! Grandfather Clock 45s Midnight Lockdown triggered!")
	if clock_chime_light:
		clock_chime_light.light_color = Color(1.0, 0.18, 0.15, 1.0)
		clock_chime_light.light_energy = 4.0

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ PLINTH PRESSURE TRAP TRIGGERED! ]\nThe Grandfather Clock has begun its 45s Midnight Lockdown! Grab the Lead Apothecary Weight and disarm the Grandfather Clock [E]!",
			"overseer_clock_chime_trap"
		)
	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("clock_chime_trap")

func _trigger_midnight_toll() -> void:
	midnight_tolls_triggered += 1
	clock_countdown_timer = CLOCK_LOCKDOWN_DURATION
	print("[Level_18] GRANDFATHER CLOCK MIDNIGHT TOLL! Acoustic resonance shockwave triggered!")
	if is_inside_tree() and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var p = players[0]
			if p.has_method("apply_trauma"):
				p.apply_trauma(0.5)
			if p.has_method("take_damage"):
				p.take_damage(18, "hazard")

func _on_grandfather_clock_interacted(_user_data = null) -> void:
	_sync_from_level_manager()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not has_lead_counterweight:
		print("[Level_18] Grandfather Clock requires Lead Apothecary Counterweight to disarm.")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ GRANDFATHER PENDULUM CLOCK ]\nThe chime mechanism is missing its counterweight. Find the Lead Apothecary Weight in the West Portrait Gallery!",
				""
			)
		return

	is_clock_lockdown_disarmed = true
	is_clock_lockdown_active = false
	clock_countdown_timer = CLOCK_LOCKDOWN_DURATION
	print("[Level_18] Lead Apothecary Counterweight installed! Grandfather Clock Midnight Lockdown DISARMED.")
	if clock_chime_light:
		clock_chime_light.light_color = Color(1.0, 0.82, 0.45, 1.0)
		clock_chime_light.light_energy = 1.8

	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ GRANDFATHER CLOCK DISARMED ]\nLead Apothecary Weight balanced the pendulum! The Midnight Lockdown and Portrait Gaze traps are neutralized.",
			""
		)
	_refresh_hud_objective()

func _on_grand_piano_interacted(_user_data = null) -> void:
	_sync_from_level_manager()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not has_tuning_fork:
		print("[Level_18] Grand Piano requires 440Hz Clinical Tuning Fork from Sector 17.")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ CONSERVATORY GRAND PIANO ]\nThe strings are detuned. You need the 440Hz Clinical Tuning Fork from Sector 17's Auditory Booths to find the resonant chord!",
				""
			)
		return

	if not is_piano_chord_played:
		is_piano_chord_played = true
		print("[Level_18] 440Hz Clinical Tuning Fork resonated Grand Piano! Movable Bookcase sliding open to Secret Study!")
		if movable_bookcase_mesh and is_inside_tree():
			var tween = create_tween()
			if tween:
				tween.tween_property(movable_bookcase_mesh, "position:x", movable_bookcase_mesh.position.x + 3.2, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		elif movable_bookcase_mesh:
			movable_bookcase_mesh.position.x += 3.2

		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ 440Hz RESONANT CHORD PLAYED ]\nThe Grand Piano's acoustic lock clicked! The Movable Bookcase slid open, revealing Julian Vance's Secret Study!",
				""
			)
	_refresh_hud_objective()

func _on_daguerreotype_interacted(_user_data = null) -> void:
	_sync_from_level_manager()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	if not is_piano_chord_played:
		print("[Level_18] Secret Study bookcase is still closed! Play the Grand Piano with the 440Hz Tuning Fork first.")
		return

	if not has_silver_nitrate:
		print("[Level_18] Daguerreotype plate requires Bottle of Silver Nitrate Developer from Sector 17.")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ UNEXPOSED GLASS DAGUERREOTYPE ]\nRequires Silver Nitrate Developer from Sector 17's Darkroom to reveal the hidden image.",
				""
			)
		return

	if not is_daguerreotype_developed:
		is_daguerreotype_developed = true
		print("[Level_18] Silver Nitrate poured! 1931 Vance Family Daguerreotype developed—Crest Alignment Cipher revealed!")
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ DAGUERREOTYPE DEVELOPED: 1931 VANCE FAMILY PORTRAIT ]\nThe silver plate reveals the emblem alignment: 'SERPENT AT DAWN (30°), RAVEN AT DUSK (210°)'.",
				""
			)
	_refresh_hud_objective()

func _refresh_hud_objective() -> void:
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if not hud or not hud.has_method("update_objective"):
		return

	if is_clock_lockdown_active and not is_clock_lockdown_disarmed:
		hud.update_objective("URGENT (45s): Grab Lead Apothecary Weight in West Gallery & disarm Grandfather Clock [E]!")
	elif not is_piano_chord_played:
		hud.update_objective("Use 440Hz Tuning Fork on East Grand Piano [E] to open the Secret Study Bookcase.")
	elif not is_daguerreotype_developed:
		hud.update_objective("Use Silver Nitrate Developer on the Glass Daguerreotype Plate [E] inside the Secret Study.")
	elif not has_raven_crest or not is_clock_lockdown_disarmed:
		hud.update_objective("Claim the Raven Half-Crest in the West Portrait Gallery & disarm the Grandfather Clock [E].")
	else:
		hud.update_objective("All Relics & Alignment Ready! Unite Serpent & Raven Crests at South Ballroom Doors [E].")

func _on_ballroom_doors_interacted(_user_data = null) -> void:
	if is_ballroom_unlocked:
		return

	_sync_from_level_manager()
	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)

	var ready_to_open = (
		has_serpent_crest and
		has_raven_crest and
		is_piano_chord_played and
		is_daguerreotype_developed and
		is_clock_lockdown_disarmed
	)

	if not ready_to_open:
		print("[Level_18] Ballroom Crest Doors locked: Serpent=", has_serpent_crest, " Raven=", has_raven_crest, " Piano=", is_piano_chord_played, " Daguerreotype=", is_daguerreotype_developed, " ClockDisarmed=", is_clock_lockdown_disarmed)
		if hud and hud.has_method("display_overseer_message"):
			hud.display_overseer_message(
				"[ SOUTH BALLROOM CREST DOORS LOCKED ]\nRequires: Serpent Crest (%s), Raven Crest (%s), Clock Disarmed (%s), Piano Tuned (%s), & Daguerreotype Developed (%s)." % [
					"OK" if has_serpent_crest else "MISSING",
					"OK" if has_raven_crest else "MISSING",
					"OK" if is_clock_lockdown_disarmed else "LOCKED",
					"OK" if is_piano_chord_played else "LOCKED",
					"OK" if is_daguerreotype_developed else "LOCKED"
				],
				""
			)
		return

	unlock_grand_ballroom()

func unlock_grand_ballroom() -> void:
	if is_ballroom_unlocked:
		return
	is_ballroom_unlocked = true
	is_clock_lockdown_active = false
	print("[Level_18] Serpent & Raven Crests united! Vance Manor Grand Ballroom UNLOCKED!")

	if exit_door_mesh and is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(exit_door_mesh, "position:y", exit_door_mesh.position.y + 4.4, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var hud = null
	if is_inside_tree() and get_tree() and get_tree().root:
		hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("display_overseer_message"):
		hud.display_overseer_message(
			"[ VANCE ESTATE SEAL UNITED ]\nSerpent and Raven Crests aligned! The South Grand Ballroom Doors have swung open.",
			"overseer_manor_ballroom_unlocked"
		)
	if hud and hud.has_method("update_objective"):
		hud.update_objective("Enter the South Grand Ballroom Doors to complete the Vance Manor chapter!")

	if is_inside_tree() and has_node("/root/TheOverseer"):
		get_node("/root/TheOverseer").trigger_dialogue("manor_ballroom_unlocked")
