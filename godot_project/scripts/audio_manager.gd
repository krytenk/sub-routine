extends Node

# Sub-Routine Dynamic Audio Manager
# Scans res://assets/audio/vo/ and res://assets/audio/ambient/ for .ogg and .wav files
# Dynamically parses WAV headers (sample rate, channels, bit depth), assigns streams to 2D
# and spatial AudioStreamPlayer3D nodes, and manages continuous seamless ambient looping.

signal audio_scanned(vo_count: int, ambient_count: int)
signal ambient_track_started(track_name: String, duration: float)

const VO_DIR_PATH = "res://assets/audio/vo"
const AMBIENT_DIR_PATH = "res://assets/audio/ambient"

var vo_streams: Dictionary = {}        # name -> AudioStream
var ambient_streams: Dictionary = {}   # name -> AudioStream
var ambient_playlist: Array[String] = []
var current_ambient_index: int = 0

var ambient_player: AudioStreamPlayer
var ambient_fade_tween: Tween
var vo_player: AudioStreamPlayer
var spatial_players: Array[AudioStreamPlayer3D] = []

# Ambient pacing configuration for 30-minute levels
@export var ambient_volume_db: float = -6.0
@export var enable_playlist_cycling: bool = true
@export var silence_breather_seconds: float = 3.5

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    ambient_player = AudioStreamPlayer.new()
    ambient_player.name = "AmbientMusicPlayer"
    ambient_player.bus = "Master"
    ambient_player.finished.connect(_on_ambient_finished)
    add_child(ambient_player)
    
    vo_player = AudioStreamPlayer.new()
    vo_player.name = "OverseerVOPlayer"
    vo_player.bus = "Master"
    add_child(vo_player)

    scan_audio_directories()
    for arg in OS.get_cmdline_args():
        if arg == "--headless" or arg.ends_with("gdunit4_cli_runner.gd"):
            return
    start_ambient_drone()

func scan_audio_directories() -> void:
    vo_streams.clear()
    ambient_streams.clear()
    ambient_playlist.clear()
    
    _scan_folder(VO_DIR_PATH, vo_streams)
    # Ambient tracks should not loop internally when playlist cycling is enabled; they cycle after full playback
    _scan_folder(AMBIENT_DIR_PATH, ambient_streams, false)
    
    for key in ambient_streams.keys():
        if not key.ends_with(".wav") and not key.ends_with(".ogg"):
            if not ambient_playlist.has(key):
                ambient_playlist.append(key)
    
    print("[AudioManager] Scanned audio assets: ", vo_streams.size(), " VO clips, ", ambient_streams.size(), " ambient tracks.")
    print("[AudioManager] Ambient Playlist: ", ambient_playlist)
    audio_scanned.emit(vo_streams.size(), ambient_streams.size())

func _scan_folder(path: String, target_dict: Dictionary, is_ambient: bool = false) -> void:
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir():
                var lower_name = file_name.to_lower()
                if lower_name.ends_with(".ogg") or lower_name.ends_with(".wav"):
                    var file_path = path.path_join(file_name)
                    var stream = load_audio_file(file_path, is_ambient)
                    if stream:
                        # Clean up double extensions (e.g. .wav.wav)
                        var clean_id = file_name
                        while clean_id.ends_with(".wav") or clean_id.ends_with(".ogg"):
                            clean_id = clean_id.get_basename()

                        target_dict[clean_id] = stream
                        target_dict[file_name] = stream
                        target_dict[clean_id + ".wav"] = stream
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
    var path = "res://assets/audio/sfx/" + clean + ".wav"
    if ResourceLoader.exists(path):
        var s = ResourceLoader.load(path)
        if s is AudioStream:
            var p = AudioStreamPlayer.new()
            p.bus = "Master"
            p.stream = s
            add_child(p)
            p.play()
            p.finished.connect(p.queue_free)

func play_vo(clip_name: String) -> void:
    if vo_streams.has(clip_name):
        vo_player.stream = vo_streams[clip_name]
        vo_player.volume_db = 0.0
        vo_player.play()
        print("[AudioManager] Playing Overseer VO: ", clip_name)
    else:
        push_warning("[AudioManager] VO clip not found: " + clip_name)

func get_vo_duration(clip_name: String) -> float:
    var clean = clip_name.trim_suffix(".wav").trim_suffix(".ogg")
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
    if vo_streams.has(clip_name):
        spatial_node.stream = vo_streams[clip_name]
        return true
    elif ambient_streams.has(clip_name):
        spatial_node.stream = ambient_streams[clip_name]
        return true
    else:
        push_warning("[AudioManager] Stream not found for spatial assignment: " + clip_name)
        return false

func create_spatial_player(pos: Vector3) -> AudioStreamPlayer3D:
    var sp = AudioStreamPlayer3D.new()
    sp.position = pos
    sp.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    sp.unit_size = 10.0
    sp.max_distance = 50.0
    sp.finished.connect(func(): sp.queue_free())
    add_child(sp)
    return sp
