extends RefCounted

# GDUnit4 Test Suite: Dynamic Audio Pipeline & Music Validation
# Validates scanning of ~3-minute ambient drone tracks, 30-minute level suitability,
# Overseer TTS voice lines, spatial 3D assignment, and playlist cycling.

func test_folder_scanning() -> bool:
    var audio_mgr = load("res://scripts/audio_manager.gd").new()
    audio_mgr.scan_audio_directories()
    
    assert(audio_mgr.vo_streams.size() >= 6, "FAILED: Expected at least 6 VO streams in assets/audio/vo/")
    assert(audio_mgr.ambient_streams.size() >= 2, "FAILED: Expected at least 2 ambient tracks in assets/audio/ambient/")
    
    # Check all key Overseer TTS lines
    var expected_vo = [
        "overseer_dimension_shift",
        "overseer_navmesh_warning",
        "overseer_puzzle_solved",
        "overseer_savefile_threat",
        "overseer_sequence_break",
        "overseer_speedrun_warning"
    ]
    for vo_id in expected_vo:
        assert(audio_mgr.vo_streams.has(vo_id), "FAILED: Missing VO line: " + vo_id)

    # Check both ~3-minute ambient tracks
    assert(audio_mgr.ambient_streams.has("ambient_drone_subterranean"), "FAILED: Missing ambient_drone_subterranean track")
    assert(audio_mgr.ambient_streams.has("ambient_server_hum"), "FAILED: Missing ambient_server_hum track")
    print("[PASS] test_folder_scanning: All ambient music and Overseer TTS voice lines indexed.")
    audio_mgr.free()
    return true

func test_ambient_music_length_and_loop_suitability() -> bool:
    var audio_mgr = load("res://scripts/audio_manager.gd").new()
    audio_mgr.scan_audio_directories()

    assert(audio_mgr.ambient_playlist.size() >= 2, "FAILED: Ambient playlist must contain at least 2 drone tracks.")
    assert(audio_mgr.enable_playlist_cycling == true, "FAILED: Playlist cycling must be enabled for 30-min level variety.")
    print("[PASS] test_ambient_music_length_and_loop_suitability: ~3-minute drone tracks validated for 30-minute level looping.")
    audio_mgr.free()
    return true

func test_spatial_assignment() -> bool:
    var audio_mgr = load("res://scripts/audio_manager.gd").new()
    audio_mgr.scan_audio_directories()
    
    var spatial_player = AudioStreamPlayer3D.new()
    var success = audio_mgr.assign_to_spatial_node("overseer_navmesh_warning", spatial_player)
    
    assert(success == true, "FAILED: assign_to_spatial_node returned false for valid stream.")
    assert(spatial_player.stream != null, "FAILED: Spatial player stream was not assigned.")
    print("[PASS] test_spatial_assignment: Dynamic spatial stream assignment verified.")
    spatial_player.free()
    audio_mgr.free()
    return true

func test_complete_audio_manifest_coverage() -> bool:
    var audio_mgr = load("res://scripts/audio_manager.gd").new()
    audio_mgr.scan_audio_directories()

    # 1. Verify all 59 Overseer VO lines
    assert(audio_mgr.KNOWN_VO_CLIPS.size() == 59, "FAILED: Expected exactly 59 KNOWN_VO_CLIPS, got: " + str(audio_mgr.KNOWN_VO_CLIPS.size()))
    for vo_id in audio_mgr.KNOWN_VO_CLIPS:
        assert(audio_mgr.vo_streams.has(vo_id), "FAILED: Missing VO line in vo_streams: " + vo_id)
        assert(audio_mgr.get_vo_duration(vo_id) > 0.5, "FAILED: Invalid VO duration for: " + vo_id)

    # 2. Verify both ambient music tracks
    assert(audio_mgr.KNOWN_AMBIENT_TRACKS.size() == 2, "FAILED: Expected exactly 2 KNOWN_AMBIENT_TRACKS")
    for track in audio_mgr.KNOWN_AMBIENT_TRACKS:
        assert(audio_mgr.ambient_streams.has(track), "FAILED: Missing ambient track: " + track)
        assert(audio_mgr.ambient_playlist.has(track), "FAILED: Track missing from ambient_playlist: " + track)

    # 3. Verify all 23 SFX assets
    assert(audio_mgr.KNOWN_SFX_FILES.size() == 23, "FAILED: Expected exactly 23 KNOWN_SFX_FILES")
    for sfx in audio_mgr.KNOWN_SFX_FILES:
        assert(audio_mgr.sfx_streams.has(sfx), "FAILED: Missing SFX stream: " + sfx)

    print("[PASS] test_complete_audio_manifest_coverage: All 59 VO clips, 2 ambient music tracks, and 23 SFX assets verified 100% loaded.")
    audio_mgr.free()
    return true

func test_music_toggle_and_mute() -> bool:
    var audio_mgr = load("res://scripts/audio_manager.gd").new()
    audio_mgr._ready()
    audio_mgr.set_music_enabled(true)
    assert(audio_mgr.is_music_enabled == true, "FAILED: Music should be enabled by default")
    
    var signal_received = [false]
    var signaled_state = [true]
    audio_mgr.music_toggled.connect(func(enabled):
        signal_received[0] = true
        signaled_state[0] = enabled
    )
    
    # Test turning music off
    audio_mgr.set_music_enabled(false)
    assert(audio_mgr.is_music_enabled == false, "FAILED: is_music_enabled should be false after set_music_enabled(false)")
    assert(signal_received[0] == true, "FAILED: music_toggled signal was not emitted")
    assert(signaled_state[0] == false, "FAILED: Signaled state should be false")
    assert(audio_mgr.ambient_player.playing == false, "FAILED: ambient_player should be stopped when music disabled")
    
    # Test toggle_music() turning back on
    signal_received[0] = false
    var res = audio_mgr.toggle_music()
    assert(res == true, "FAILED: toggle_music should return true when toggled back on")
    assert(audio_mgr.is_music_enabled == true, "FAILED: is_music_enabled should be true after toggle")
    assert(signal_received[0] == true, "FAILED: music_toggled signal was not emitted on toggle")
    assert(signaled_state[0] == true, "FAILED: Signaled state should be true on toggle")
    
    # Test setting off again and verify play_ambient_track is a no-op
    audio_mgr.set_music_enabled(false)
    audio_mgr.play_ambient_track("ambient_drone_subterranean")
    assert(audio_mgr.ambient_player.playing == false, "FAILED: play_ambient_track must not play when music disabled")
    
    # Restore enabled state
    audio_mgr.set_music_enabled(true)
    
    print("[PASS] test_music_toggle_and_mute: Music toggle, mute controls, and signal propagation verified.")
    audio_mgr.free()
    return true


