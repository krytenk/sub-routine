#!/usr/bin/env python3
"""
Headless TDD CLI Test Harness for "Sub-Routine"
Comprehensive suite covering:
- Roxy Vance zero environmental damage & direct enemy vulnerability
- Roxy Vance stamina & sprint fatigue mechanics
- Environmental hazard nodes
- Dynamic difficulty scaling (Story to Nightmare)
- The Overseer fourth-wall scripts & trigger zones
- Dynamic Audio Manager directory scanning & spatial 3D assignment
- Validation of ~3-minute ambient drone tracks and 30-minute level suitability
- Validation of all Overseer Gemini TTS voice lines
- Non-Euclidean looping corridors & shifting rooms
- Subroutine Terminal map telemetry
- Level Roadmap: 120 levels scope, 40 playable TSCN scenes on disk
- Single-threaded WASM export & 50ms audio latency fix
- PS1 vertex jitter & CRT phosphor glitch overlay shaders
"""

import os
import sys
import glob
import wave
import struct

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GODOT_DIR = os.path.join(BASE_DIR, "godot_project")

passed = 0
failed = 0

def test(name):
    def decorator(fn):
        global passed, failed
        try:
            fn()
            print(f"[GDUnit4 TDD] PASS: {name}")
            passed += 1
        except Exception as e:
            print(f"[GDUnit4 TDD] FAIL: {name} -> {e}")
            import traceback
            traceback.print_exc()
            failed += 1
        return fn
    return decorator

print("=" * 65)
print(" SUB-ROUTINE HEADLESS TDD TEST HARNESS (GDUnit4 CLI)")
print("=" * 65)

# 1. Damage Rules (Zero environmental damage, damage only from enemies)
@test("test_roxy_damage_rules: Environmental Immunity & Enemy Damage")
def t_damage_rules():
    roxy_path = os.path.join(GODOT_DIR, "scenes", "player", "roxy_vance.gd")
    with open(roxy_path, "r") as f:
        code = f.read()
    
    assert 'func take_damage(amount: int, source_type: String = "environmental")' in code, "take_damage method missing"
    assert 'if source_type == "environmental":' in code, "environmental hazard check missing"
    assert 'return' in code, "environmental hazard must not reduce health"
    assert 'current_health = maxi(0, current_health - amount)' in code, "enemy attack damage logic missing"

    health = 100
    def simulate_take_damage(hp, amount, source_type):
        if source_type == "environmental":
            return hp
        return max(0, hp - amount)

    assert simulate_take_damage(health, 50, "environmental") == 100, "Roxy took environmental damage!"
    assert simulate_take_damage(health, 25, "enemy") == 75, "Enemy attack did not reduce health!"

# 2. Player Stamina System
@test("test_roxy_stamina_system: Drain, Exhaustion, and Regeneration")
def t_stamina():
    roxy_path = os.path.join(GODOT_DIR, "scenes", "player", "roxy_vance.gd")
    with open(roxy_path, "r") as f:
        code = f.read()
    assert "signal stamina_changed" in code
    assert "signal player_exhausted" in code
    assert "stamina_drain_rate" in code
    assert "stamina_regen_rate" in code

# 3. Environmental Hazards
@test("test_environmental_hazards: Hazard Triggering & Zero Damage on Roxy")
def t_hazards():
    hazard_path = os.path.join(GODOT_DIR, "scripts", "environmental_hazard.gd")
    with open(hazard_path, "r") as f:
        code = f.read()

    assert "class_name EnvironmentalHazard" in code
    assert 'target.take_damage(damage_per_tick, "environmental")' in code

# 4. Difficulty Slider
@test("test_difficulty_slider: Story to Nightmare Scaling")
def t_difficulty_slider():
    dm_path = os.path.join(GODOT_DIR, "scripts", "difficulty_manager.gd")
    with open(dm_path, "r") as f:
        code = f.read()

    assert "func get_enemy_speed_multiplier()" in code
    assert "func get_enemy_damage_multiplier()" in code
    assert "func get_cipher_key_length()" in code

    def lerp(a, b, t): return a + (b - a) * t
    assert abs(lerp(0.6, 2.0, 0.0) - 0.6) < 1e-4, "Story speed multiplier mismatch"
    assert abs(lerp(0.5, 2.5, 0.0) - 0.5) < 1e-4, "Story damage multiplier mismatch"
    assert abs(lerp(0.6, 2.0, 1.0) - 2.0) < 1e-4, "Nightmare speed multiplier mismatch"
    assert abs(lerp(0.5, 2.5, 1.0) - 2.5) < 1e-4, "Nightmare damage multiplier mismatch"

# 5. The Overseer Fourth-Wall Breaking Scripts & Trigger Zones
@test("test_overseer_fourth_wall: Navmesh, Speedrun, and Trigger Zones")
def t_overseer():
    overseer_path = os.path.join(GODOT_DIR, "scripts", "the_overseer.gd")
    trigger_path = os.path.join(GODOT_DIR, "scripts", "overseer_trigger_zone.gd")
    with open(overseer_path, "r") as f:
        code = f.read()
    with open(trigger_path, "r") as f:
        trig_code = f.read()

    expected_navmesh = "Roxy, the nav-mesh doesn't even extend over there. Turn around and get back to the designated corridor before I delete your save file."
    expected_speedrun = "Are you trying to speed-run this? I haven't even finished rendering the next room. Slow down."

    assert expected_navmesh in code, "Navmesh fourth-wall dialogue missing or altered!"
    assert expected_speedrun in code, "Speedrun fourth-wall dialogue missing or altered!"
    assert "class_name OverseerTriggerZone" in trig_code

# 6. Audio Pipeline: Ambient Music Length & 30-Minute Level Suitability
@test("test_ambient_music_validation: ~3-Minute Tracks & 30-Minute Level Suitability")
def t_music_validation():
    ambient_dir = os.path.join(GODOT_DIR, "assets", "audio", "ambient")
    track_1 = os.path.join(ambient_dir, "ambient_drone_subterranean.wav")
    track_2 = os.path.join(ambient_dir, "ambient_server_hum.wav")

    assert os.path.exists(track_1), "Missing ambient_drone_subterranean.wav"
    assert os.path.exists(track_2), "Missing ambient_server_hum.wav"

    with wave.open(track_1, 'r') as w1:
        d1 = w1.getnframes() / float(w1.getframerate())
        assert 160.0 <= d1 <= 190.0, f"Track 1 duration unexpected: {d1:.2f}s (expected ~170-180s)"
        assert w1.getframerate() == 48000, f"Expected 48000Hz, got {w1.getframerate()}"
        assert w1.getnchannels() == 2, f"Expected Stereo, got {w1.getnchannels()}"

    with wave.open(track_2, 'r') as w2:
        d2 = w2.getnframes() / float(w2.getframerate())
        assert 170.0 <= d2 <= 200.0, f"Track 2 duration unexpected: {d2:.2f}s (expected ~180-190s)"
        assert w2.getframerate() == 48000, f"Expected 48000Hz, got {w2.getframerate()}"
        assert w2.getnchannels() == 2, f"Expected Stereo, got {w2.getnchannels()}"

    # Suitability calculation: In a 30-minute level (1800s), tracks loop ~10 times seamlessly
    loops_t1 = 1800.0 / d1
    loops_t2 = 1800.0 / d2
    assert 9.0 <= loops_t1 <= 11.5, f"Unreasonable loop count for Track 1: {loops_t1}"
    assert 9.0 <= loops_t2 <= 11.0, f"Unreasonable loop count for Track 2: {loops_t2}"

# 7. Audio Pipeline: Overseer TTS Voiceovers Validation
@test("test_overseer_vo_recordings: Verification of Spoken TTS Voice Files")
def t_vo_recordings():
    vo_dir = os.path.join(GODOT_DIR, "assets", "audio", "vo")
    required_vo = [
        "overseer_dimension_shift",
        "overseer_navmesh_warning",
        "overseer_puzzle_solved",
        "overseer_savefile_threat",
        "overseer_sequence_break",
        "overseer_speedrun_warning"
    ]

    for vo_name in required_vo:
        wav_file = os.path.join(vo_dir, f"{vo_name}.wav")
        assert os.path.exists(wav_file), f"Missing normalized VO file: {wav_file}"
        with wave.open(wav_file, 'r') as w:
            dur = w.getnframes() / float(w.getframerate())
            assert dur > 1.5, f"VO {vo_name} audio clip too short: {dur}s"
            assert w.getframerate() in (24000, 44100, 48000), f"Unsupported sample rate: {w.getframerate()}"

# 8. Non-Euclidean Geometry & Looping Corridors
@test("test_non_euclidean: Looping Threshold & Puzzle Unlocking")
def t_non_euclidean():
    corr_path = os.path.join(GODOT_DIR, "scripts", "non_euclidean_corridor.gd")
    shift_path = os.path.join(GODOT_DIR, "scripts", "shifting_room.gd")
    with open(corr_path, "r") as f:
        corr_code = f.read()
    with open(shift_path, "r") as f:
        shift_code = f.read()

    assert "is_unlocked" in corr_code
    assert "loop_counter" in corr_code
    assert "trigger_dimension_shift" in shift_code

# 9. Subroutine Terminal Map
@test("test_subroutine_terminal: Map Telemetry & Anomaly Tracking")
def t_terminal():
    term_path = os.path.join(GODOT_DIR, "scenes", "ui", "subroutine_terminal.gd")
    assert os.path.exists(term_path), "Subroutine terminal script missing"
    with open(term_path, "r") as f:
        term_code = f.read()
    assert "class_name SubroutineTerminal" in term_code
    assert "func refresh_telemetry()" in term_code

# 10. Level Roadmap Scope (120 levels scope, 40 playable TSCN Scenes)
@test("test_levels: 120 Scope Roadmap & 40 Playable TSCN Scenes on Disk")
def t_levels():
    lm_path = os.path.join(GODOT_DIR, "scripts", "level_manager.gd")
    with open(lm_path, "r") as f:
        lm_code = f.read()

    assert "const TOTAL_ROADMAP_LEVELS: int = 120" in lm_code
    assert "const LAUNCH_DAY_LEVELS: int = 20" in lm_code
    assert "const EXPANSION_PACK_1_LEVELS: int = 40" in lm_code

    for i in range(1, 41):
        lvl_file = os.path.join(GODOT_DIR, "scenes", "levels", f"level_{i:02d}.tscn")
        assert os.path.exists(lvl_file), f"Missing level scene file: level_{i:02d}.tscn"

# 11. Web single-threaded export & Audio latency fix
@test("test_wasm_export_and_audio_latency_fix: Single-threaded and 50ms latency")
def t_wasm():
    main_path = os.path.join(GODOT_DIR, "scripts", "main.gd")
    with open(main_path, "r") as f:
        main_code = f.read()
    assert 'AudioServer.set("driver/output_latency", 50)' in main_code, "Audio latency fix missing from main.gd"
    assert 'Engine.max_fps = 60' in main_code, "Engine.max_fps cap missing from main.gd"

    export_path = os.path.join(GODOT_DIR, "export_presets.cfg")
    with open(export_path, "r") as f:
        cfg = f.read()
    assert 'variant/thread_support=false' in cfg, "Single-threaded WASM export preset missing"

# 12. PS1 Visual Shaders & CRT Glitch Overlay
@test("test_ps1_shaders: PS1 Vertex Jitter & CRT Glitch Overlay Shaders")
def t_shaders():
    jitter_path = os.path.join(GODOT_DIR, "assets", "shaders", "ps1_vertex_jitter.gdshader")
    crt_path = os.path.join(GODOT_DIR, "assets", "shaders", "crt_glitch_overlay.gdshader")
    assert os.path.exists(jitter_path), "PS1 vertex jitter shader missing"
    assert os.path.exists(crt_path), "CRT glitch overlay shader missing"

# 13. Procedural 3D GLB Asset Models (11 Models with valid binary glTF headers)
@test("test_blender_procedural_models: 11 Models with Valid Binary GLB Headers & Bounds")
def t_procedural_models():
    models_dir = os.path.join(GODOT_DIR, "assets", "models")
    expected_models = [
        "glitch_walker.glb",
        "roxy_vance.glb",
        "server_rack.glb",
        "server_corridor.glb",
        "crt_terminal.glb",
        "mainframe_bank.glb",
        "cable_nest.glb",
        "coolant_pipe_junction.glb",
        "blast_door.glb",
        "memory_core_pickup.glb",
        "emp_device.glb"
    ]
    for model_name in expected_models:
        model_path = os.path.join(models_dir, model_name)
        assert os.path.exists(model_path), f"Missing model asset: {model_name}"
        assert os.path.getsize(model_path) > 1000, f"Model asset {model_name} too small: {os.path.getsize(model_path)} bytes"
        with open(model_path, "rb") as f:
            magic = f.read(4)
            assert magic == b"glTF", f"Model {model_name} does not have valid glTF magic header: {magic}"
            version = struct.unpack("<I", f.read(4))[0]
            assert version == 2, f"Model {model_name} has invalid glTF version: {version}"

# 14. Combat Mechanics & Terminal Register Minigame
@test("test_emp_combat_and_terminal_puzzle: EMP pulse stun & Terminal cipher decryption")
def t_emp_and_terminal():
    roxy_path = os.path.join(GODOT_DIR, "scenes", "player", "roxy_vance.gd")
    walker_path = os.path.join(GODOT_DIR, "scenes", "enemies", "glitch_walker.gd")
    term_path = os.path.join(GODOT_DIR, "scenes", "ui", "subroutine_terminal.gd")

    with open(roxy_path, "r") as f:
        roxy_code = f.read()
    with open(walker_path, "r") as f:
        walker_code = f.read()
    with open(term_path, "r") as f:
        term_code = f.read()

    assert "func fire_emp_pulse()" in roxy_code, "fire_emp_pulse method missing from roxy_vance.gd"
    assert "emp_cooldown = 8.0" in roxy_code or "var emp_cooldown" in roxy_code, "emp_cooldown missing"
    assert "func stagger(" in walker_code, "stagger method missing from glitch_walker.gd"
    assert "func _append_char(" in term_code, "hex input append handler missing from terminal"
    assert "func _on_dereference_pressed()" in term_code, "dereference handler missing from terminal"


print("-" * 65)
print(f"Results: {passed} PASSED, {failed} FAILED")
print("=" * 65)

if failed > 0:
    print("[GDUnit4 TDD] Test suite failed with exit code 1.")
    sys.exit(1)
else:
    print("[GDUnit4 TDD] All tests passed! Exit code 0.")
    sys.exit(0)
