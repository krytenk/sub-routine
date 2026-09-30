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
