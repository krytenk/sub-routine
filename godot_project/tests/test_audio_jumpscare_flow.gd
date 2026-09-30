extends RefCounted

# GDUnit4 Test Suite: Audio Manager, Jumpscare Triggering, and Overseer Dialogue Timing

func test_ambient_tracks_do_not_abort_loop() -> bool:
	var am = load("res://scripts/audio_manager.gd").new()
	am.scan_audio_directories()
	assert(am.ambient_streams.size() > 0, "FAILED: Ambient streams empty")
	
	for key in am.ambient_streams.keys():
		var stream = am.ambient_streams[key]
		if stream is AudioStreamWAV:
			# Verify loop_mode is LOOP_DISABLED so it doesn't instantly die on frame 0
			assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "FAILED: Expected LOOP_DISABLED on ambient stream: " + key)
			assert(stream.get_length() > 60.0, "FAILED: Expected length > 60s on: " + key)
	
	am.free()
	print("[PASS] test_ambient_tracks_do_not_abort_loop: Verified ambient streams play full length.")
	return true

func test_overseer_jumpscare_duration() -> bool:
	var am = load("res://scripts/audio_manager.gd").new()
	am.scan_audio_directories()
	assert(am.vo_streams.has("overseer_jumpscare"), "FAILED: Missing overseer_jumpscare VO")
	var dur = am.get_vo_duration("overseer_jumpscare")
	# Jumpscare line should be between 5.5s and 8.5s
	assert(dur > 5.5 and dur < 8.5, "FAILED: Expected jumpscare duration between 5.5s and 8.5s, got: " + str(dur))
	am.free()
	print("[PASS] test_overseer_jumpscare_duration: Verified Overseer jumpscare duration is %.2fs." % dur)
	return true

const JumpscareTriggerClass = preload("res://scenes/props/jumpscare_trigger.gd")

func test_jumpscare_one_time_activation() -> bool:
	# Reset static dictionary for testing
	JumpscareTriggerClass.triggered_jumpscares.clear()
	
	var trig1 = JumpscareTriggerClass.new()
	trig1.name = "TestJumpscare"
	trig1.jumpscare_id = "test_sector_corridor_01"
	
	var player = CharacterBody3D.new()
	player.name = "RoxyVance"
	
	trig1._ready()
	assert(trig1.triggered == false, "FAILED: Expected initial triggered state to be false")
	
	# First entry: triggers
	trig1._on_body_entered(player)
	assert(trig1.triggered == true, "FAILED: Expected triggered state to be true after entry")
	assert(JumpscareTriggerClass.triggered_jumpscares.get("test_sector_corridor_01", false) == true, "FAILED: Expected ID in persistent dict")
	
	# Simulate re-instantiation (e.g. backtracking into room or scene reload)
	var trig2 = JumpscareTriggerClass.new()
	trig2.name = "TestJumpscare"
	trig2.jumpscare_id = "test_sector_corridor_01"
	trig2._ready()
	# Must already be marked triggered from persistent dict
	assert(trig2.triggered == true, "FAILED: Expected persistent jumpscare to remain triggered on reload")
	
	trig1.free()
	trig2.free()
	player.free()
	print("[PASS] test_jumpscare_one_time_activation: Jumpscare only triggers once and persists across reloads.")
	return true

func test_overseer_dialogue_debouncing() -> bool:
	var overseer = load("res://scripts/the_overseer.gd").new()
	overseer._ready()
	
	var am = load("res://scripts/audio_manager.gd").new()
	am.scan_audio_directories()
	overseer.audio_manager_override = am
	
	overseer.dialogue_debounce_timer = 0.0
	overseer.last_played_clip = ""
	
	# Trigger jumpscare dialogue
	overseer.trigger_dialogue("jumpscare")
	assert(overseer.dialogue_debounce_timer > 5.0, "FAILED: Expected debounce timer > 5.0s, got: " + str(overseer.dialogue_debounce_timer))
	
	# Attempt immediate clobber with another line while dialogue is active
	var initial_clip = overseer.last_played_clip
	overseer.trigger_dialogue("emp_success")
	# Should be protected by debounce timer (not clobbered)
	assert(overseer.last_played_clip == initial_clip, "FAILED: Dialogue was clobbered while speech was active")
	
	am.free()
	overseer.free()
	print("[PASS] test_overseer_dialogue_debouncing: Verified voice line is protected from being cut off.")
	return true
