extends Node

# Sub-Routine Dynamic Audio Manager
# Scans res://assets/audio/vo/ and res://assets/audio/ambient/ for .ogg and .wav files
# Dynamically parses WAV headers (sample rate, channels, bit depth), assigns streams to 2D
# and spatial AudioStreamPlayer3D nodes, and manages continuous seamless ambient looping.

signal audio_scanned(vo_count: int, ambient_count: int)
signal ambient_track_started(track_name: String, duration: float)

const VO_DIR_PATH = "res://assets/audio/vo"
const AMBIENT_DIR_PATH = "res://assets/audio/ambient"
const SFX_DIR_PATH = "res://assets/audio/sfx"

const KNOWN_VO_CLIPS: Array[String] = [
    "overseer_art_showcase",
    "overseer_backtrack_hint",
    "overseer_breaker_power",
    "overseer_cannon_assembled",
    "overseer_cannon_burnout",
    "overseer_casualty_inspect",
    "overseer_cctv_stalker_reveal",
    "overseer_cyberhusk_alert",
    "overseer_darkness_whisper",
    "overseer_dead_end_trap",
    "overseer_deadlock_unlocked",
    "overseer_decision_choice",
    "overseer_dimension_shift",
    "overseer_duct_crawl",
    "overseer_emp_mk4",
    "overseer_emp_mk5",
    "overseer_emp_success",
    "overseer_emp_upgraded",
    "overseer_enemy_killed",
    "overseer_escape_taunt",
    "overseer_fall_damage",
    "overseer_generator_need_parts",
    "overseer_generator_restored",
    "overseer_jumpscare",
    "overseer_medkit_used",
    "overseer_multi_threat",
    "overseer_navmesh_warning",
    "overseer_puzzle_solved",
    "overseer_reprieve_taunt",
    "overseer_savefile_threat",
    "overseer_sequence_break",
    "overseer_server_vault",
    "overseer_speedrun_warning",
    "overseer_stairs_ascent",
    "overseer_stealth_hint",
    "overseer_stealth_locker",
    "overseer_sub_basement_horror",
    "overseer_titan_warning",
    "overseer_welcome_sec2",
    "overseer_welcome_sec3",
    "overseer_welcome_sec7",
    "overseer_welcome_sec8",
    "overseer_welcome_sec9",
    "overseer_wirehound_alert"
]

const KNOWN_AMBIENT_TRACKS: Array[String] = [
    "ambient_drone_subterranean",
    "ambient_server_hum"
]

const KNOWN_SFX_FILES: Array[String] = [
    "camera_click",
    "camera_servo_pan",
    "cctv_static",
    "sfx_capacitor_hum",
    "sfx_electric_spark",
    "sfx_fall_impact",
    "sfx_generator_start",
    "sfx_glitch_growl",
    "sfx_heartbeat",
    "sfx_hound_attack",
    "sfx_hound_bark",
    "sfx_hound_trot",
    "sfx_jump",
    "sfx_jumpscare_sting",
    "sfx_ladder_climb",
    "sfx_medkit_respawn",
    "sfx_metal_footstep",
    "sfx_part_install",
    "sfx_part_pickup",
    "sfx_stealth_enter",
    "sfx_stealth_exit",
    "sfx_steam_hiss",
    "stalker_shadow_whisper"
]

var vo_streams: Dictionary = {}        # name -> AudioStream
var ambient_streams: Dictionary = {}   # name -> AudioStream
var sfx_streams: Dictionary = {}       # name -> AudioStream
var ambient_playlist: Array[String] = []
var current_ambient_index: int = 0

var ambient_player: AudioStreamPlayer
var ambient_fade_tween: Tween
var vo_player: AudioStreamPlayer
var spatial_players: Array[AudioStreamPlayer3D] = []

var _audio_unlocked: bool = false

# Ambient pacing configuration for 30-minute levels
@export var ambient_volume_db: float = -2.0
@export var enable_playlist_cycling: bool = true
@export var silence_breather_seconds: float = 3.5

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    ambient_player = AudioStreamPlayer.new()
    ambient_player.name = "AmbientMusicPlayer"
    ambient_player.bus = "Master"
    ambient_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    ambient_player.finished.connect(_on_ambient_finished)
    add_child(ambient_player)
    
    vo_player = AudioStreamPlayer.new()
    vo_player.name = "OverseerVOPlayer"
    vo_player.bus = "Master"
    vo_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    add_child(vo_player)

    scan_audio_directories()
    for arg in OS.get_cmdline_args():
        if arg == "--headless" or arg.ends_with("gdunit4_cli_runner.gd"):
            return
    if not OS.has_feature("web"):
        start_ambient_drone()

func unlock_audio() -> void:
    _audio_unlocked = true
    if OS.has_feature("web"):
        JavaScriptBridge.eval("if (window.resumeAllAudio) { window.resumeAllAudio(); }")
    if ambient_player and not ambient_player.playing:
        start_ambient_drone()

func _input(event: InputEvent) -> void:
    if not _audio_unlocked and (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch):
        if event.is_pressed():
            unlock_audio()


func scan_audio_directories() -> void:
    vo_streams.clear()
    ambient_streams.clear()
    sfx_streams.clear()
    ambient_playlist.clear()
    
    # 1. Dynamic folder scanning (handles local loose dev files & .import/.remap in exported PCK)
    _scan_folder(VO_DIR_PATH, vo_streams)
    _scan_folder(AMBIENT_DIR_PATH, ambient_streams, false)
    _scan_folder(SFX_DIR_PATH, sfx_streams, false)
    
    # 2. Guaranteed manifest registration (ensures 100% indexing in all web/PCK exports)
    for clip_name in KNOWN_VO_CLIPS:
        if not vo_streams.has(clip_name):
            var file_path = VO_DIR_PATH.path_join(clip_name + ".wav")
            var stream = load_audio_file(file_path, false)
            if stream:
                vo_streams[clip_name] = stream
                vo_streams[clip_name + ".wav"] = stream
                var short_id = clip_name.trim_prefix("overseer_")
                vo_streams[short_id] = stream

    for track_name in KNOWN_AMBIENT_TRACKS:
        if not ambient_streams.has(track_name):
            var file_path = AMBIENT_DIR_PATH.path_join(track_name + ".wav")
            var stream = load_audio_file(file_path, false)
            if stream:
                ambient_streams[track_name] = stream
                ambient_streams[track_name + ".wav"] = stream

    for sfx_name in KNOWN_SFX_FILES:
        if not sfx_streams.has(sfx_name):
            var file_path = SFX_DIR_PATH.path_join(sfx_name + ".wav")
            var stream = load_audio_file(file_path, false)
            if stream:
                sfx_streams[sfx_name] = stream
                sfx_streams[sfx_name + ".wav"] = stream

    for key in ambient_streams.keys():
        if not key.ends_with(".wav") and not key.ends_with(".ogg"):
            if not ambient_playlist.has(key):
                ambient_playlist.append(key)
    
    print("[AudioManager] Scanned audio assets: ", vo_streams.size(), " VO entries (44 clips), ", ambient_streams.size(), " ambient tracks, ", sfx_streams.size(), " SFX streams.")
    print("[AudioManager] Ambient Playlist: ", ambient_playlist)
    audio_scanned.emit(vo_streams.size(), ambient_streams.size())

func _scan_folder(path: String, target_dict: Dictionary, is_ambient: bool = false) -> void:
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir():
                # In exported PCK builds, files have .import or .remap appended
                var clean_file = file_name.trim_suffix(".import").trim_suffix(".remap")
                var lower_name = clean_file.to_lower()
                if lower_name.ends_with(".ogg") or lower_name.ends_with(".wav"):
                    var clean_id = clean_file
                    while clean_id.ends_with(".wav") or clean_id.ends_with(".ogg"):
                        clean_id = clean_id.get_basename()

                    if not target_dict.has(clean_id):
                        var file_path = path.path_join(clean_file)
                        var stream = load_audio_file(file_path, is_ambient)
                        if stream:
                            target_dict[clean_id] = stream
                            target_dict[clean_file] = stream
                            target_dict[clean_id + ".wav"] = stream
                            if clean_id.begins_with("overseer_"):
                                target_dict[clean_id.trim_prefix("overseer_")] = stream
                            print("[AudioManager] Indexed stream: '", clean_id, "' from ", file_path)
            file_name = dir.get_next()
        dir.list_dir_end()
    else:
        push_warning("[AudioManager] Failed to open directory: " + path)

func load_audio_file(file_path: String, loop_enabled: bool = false) -> AudioStream:
    if ResourceLoader.exists(file_path):
        var res = ResourceLoader.load(file_path)
        if res is AudioStream:
            if loop_enabled:
                if res is AudioStreamWAV:
                    res.loop_mode = AudioStreamWAV.LOOP_FORWARD
                    res.loop_begin = 0
                    if res.loop_end <= 0:
                        var frames = int(res.get_length() * res.mix_rate)
                        res.loop_end = frames if frames > 0 else -1
                elif res is AudioStreamOggVorbis:
                    res.loop = true
            else:
                if res is AudioStreamWAV:
                    res.loop_mode = AudioStreamWAV.LOOP_DISABLED
                elif res is AudioStreamOggVorbis:
                    res.loop = false
            return res
            
    # Direct binary loading fallback for runtime drop-ins
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        if file:
            var file_length = file.get_length()
            var bytes = file.get_buffer(file_length)
            file.close()

            var lower = file_path.to_lower()
            if lower.ends_with(".wav") or lower.ends_with(".wav.wav"):
                return _parse_wav_buffer(bytes, loop_enabled)
            elif lower.ends_with(".ogg"):
                var ogg = AudioStreamOggVorbis.load_from_buffer(bytes)
                if ogg and loop_enabled:
                    ogg.loop = true
                return ogg
    return null

func _parse_wav_buffer(bytes: PackedByteArray, loop_enabled: bool) -> AudioStreamWAV:
    if bytes.size() < 44:
        return null

    # Validate RIFF header
    var riff = bytes.slice(0, 4).get_string_from_ascii()
    var wave = bytes.slice(8, 12).get_string_from_ascii()
    if riff != "RIFF" or wave != "WAVE":
        return null

    # Parse fmt chunk
    var channels = bytes.decode_u16(22)
    var sample_rate = bytes.decode_u32(24)
    var bits = bytes.decode_u16(34)

    # Find data chunk offset
    var data_offset = 36
    var data_size = 0
    while data_offset < bytes.size() - 8:
        var tag = bytes.slice(data_offset, data_offset + 4).get_string_from_ascii()
        var chunk_sz = bytes.decode_u32(data_offset + 4)
        if tag == "data":
            data_offset += 8
            data_size = chunk_sz
            break
        data_offset += 8 + chunk_sz

    if data_size == 0 or data_offset >= bytes.size():
        data_offset = 44
        data_size = bytes.size() - 44

    var pcm_data = bytes.slice(data_offset, data_offset + data_size)

    var wav = AudioStreamWAV.new()
    wav.data = pcm_data
    wav.mix_rate = sample_rate
    wav.stereo = (channels == 2)
    
    if bits == 16:
        wav.format = AudioStreamWAV.FORMAT_16_BITS
    elif bits == 8:
        wav.format = AudioStreamWAV.FORMAT_8_BITS

    if loop_enabled:
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
        wav.loop_begin = 0
        var bytes_per_frame = (bits / 8) * channels
        if bytes_per_frame > 0:
            wav.loop_end = int(pcm_data.size() / bytes_per_frame)

    return wav

func start_ambient_drone() -> void:
    if ambient_playlist.is_empty():
        return

    current_ambient_index = 0
    var track_name = ambient_playlist[current_ambient_index]
    play_ambient_track(track_name)

func play_ambient_track(track_name: String) -> void:
    if not ambient_streams.has(track_name):
        push_warning("[AudioManager] Ambient track not found: " + track_name)
        return

    var stream = ambient_streams[track_name]
    ambient_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    ambient_player.stream = stream
    ambient_player.volume_db = ambient_volume_db
    ambient_player.play()
    
    var dur = stream.get_length() if stream.has_method("get_length") else 180.0
    print("[AudioManager] Now playing ambient drone: '", track_name, "' (Duration: ", dur, "s)")
    ambient_track_started.emit(track_name, dur)

func _on_ambient_finished() -> void:
    print("[AudioManager] Ambient track finished playing.")
    if not enable_playlist_cycling or ambient_playlist.is_empty():
        ambient_player.play()
        return

    # Cycle to next atmospheric track after suspense breather
    current_ambient_index = (current_ambient_index + 1) % ambient_playlist.size()
    var next_track = ambient_playlist[current_ambient_index]
    
    if silence_breather_seconds > 0.0:
        print("[AudioManager] Entering suspense breather gap (", silence_breather_seconds, "s) before next drone...")
        get_tree().create_timer(silence_breather_seconds).timeout.connect(func():
            play_ambient_track(next_track)
        )
    else:
        play_ambient_track(next_track)

func play_sfx(sfx_name: String) -> void:
    var clean = sfx_name.trim_suffix(".wav").trim_suffix(".ogg")
    var stream: AudioStream = null
    if sfx_streams.has(clean):
        stream = sfx_streams[clean]
    else:
        var path = "res://assets/audio/sfx/" + clean + ".wav"
        if ResourceLoader.exists(path):
            var s = ResourceLoader.load(path)
            if s is AudioStream:
                stream = s
                sfx_streams[clean] = stream

    if stream:
        var p = AudioStreamPlayer.new()
        p.bus = "Master"
        p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        p.stream = stream
        add_child(p)
        p.play()
        p.finished.connect(p.queue_free)

func play_vo(clip_name: String) -> void:
    if not _audio_unlocked:
        unlock_audio()
    var cand = clip_name
    if not vo_streams.has(cand) and not cand.begins_with("overseer_"):
        cand = "overseer_" + cand
    if vo_streams.has(cand):
        vo_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        vo_player.stream = vo_streams[cand]
        vo_player.volume_db = 3.0
        vo_player.play()
        print("[AudioManager] Playing Overseer VO: ", cand)
    else:
        var path = "res://assets/audio/vo/" + cand + ".wav"
        if ResourceLoader.exists(path):
            var s = ResourceLoader.load(path)
            if s is AudioStream:
                vo_streams[cand] = s
                vo_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
                vo_player.stream = s
                vo_player.volume_db = 3.0
                vo_player.play()
                print("[AudioManager] Playing Overseer VO (direct load): ", cand)
                return
        push_warning("[AudioManager] VO clip not found: " + clip_name)

func get_vo_duration(clip_name: String) -> float:
    var clean = clip_name.trim_suffix(".wav").trim_suffix(".ogg")
    if not vo_streams.has(clean) and not clean.begins_with("overseer_"):
        clean = "overseer_" + clean
    if vo_streams.has(clean):
        var s = vo_streams[clean]
        if s and s.has_method("get_length"):
            var l = s.get_length()
            if l > 0.1:
                return l
    return 4.5

func play_spatial_vo(clip_name: String, world_pos: Vector3) -> AudioStreamPlayer3D:
    var player = create_spatial_player(world_pos)
    if assign_to_spatial_node(clip_name, player):
        player.play()
    return player

func assign_to_spatial_node(clip_name: String, spatial_node: AudioStreamPlayer3D) -> bool:
    var cand = clip_name
    if not vo_streams.has(cand) and not cand.begins_with("overseer_"):
        cand = "overseer_" + cand
    if vo_streams.has(cand):
        spatial_node.stream = vo_streams[cand]
        return true
    elif ambient_streams.has(clip_name):
        spatial_node.stream = ambient_streams[clip_name]
        return true
    elif sfx_streams.has(clip_name):
        spatial_node.stream = sfx_streams[clip_name]
        return true
    else:
        var path = "res://assets/audio/vo/" + cand + ".wav"
        if ResourceLoader.exists(path):
            var s = ResourceLoader.load(path)
            if s is AudioStream:
                spatial_node.stream = s
                return true
        push_warning("[AudioManager] Stream not found for spatial assignment: " + clip_name)
        return false

func create_spatial_player(pos: Vector3) -> AudioStreamPlayer3D:
    var sp = AudioStreamPlayer3D.new()
    sp.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    sp.position = pos
    sp.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    sp.unit_size = 10.0
    sp.max_distance = 50.0
    sp.finished.connect(func(): sp.queue_free())
    add_child(sp)
    return sp
