# Sub-Routine: Audio Generation & Implementation Guide

This guide provides exact prompts and instructions for generating Voiceovers (VO) and Ambient Music tracks using **Google AI Studio / Gemini Web Interface** without needing live API keys.

---

## 1. Directory Structure

Drop all generated `.ogg` or `.wav` files directly into these directories:

- **Voiceovers (The Overseer)**:  
  `/godot_project/assets/audio/vo/`

- **Ambient Drone & Environmental Music**:  
  `/godot_project/assets/audio/ambient/`

> **Note**: `audio_manager.gd` dynamically scans these directories on engine startup and binds the streams to spatial `AudioStreamPlayer3D` nodes automatically.

---

## 2. Spoken Text (TTS) for "The Overseer"

In **Google AI Studio** or **Gemini (Advanced)**, use the following voice personality directive:

> **System Prompt / Tone Directive**:  
> *"You are The Overseer, a rogue, self-aware development AI in a PS1 survival horror game. Speak in a cold, cynical, monotone developer voice with subtle digital compression and robotic cadence. You treat the protagonist (Roxy) like a QA tester who keeps breaking the game engine."*

### Key Script Lines & File Names

| Filename | Spoken Script | In-Game Trigger |
| :--- | :--- | :--- |
| `overseer_navmesh_warning.wav` | *"Roxy, the nav-mesh doesn't even extend over there. Turn around and get back to the designated corridor before I delete your save file."* | Player touches navmesh boundary or out-of-bounds trigger zone. |
| `overseer_speedrun_warning.wav` | *"Are you trying to speed-run this? I haven't even finished rendering the next room. Slow down."* | Player reaches checkpoint in under 60 seconds. |
| `overseer_savefile_threat.wav` | *"Critical Exception: Player coordinates outside scene bounding box. Returning entity to last valid checkpoint."* | Player falls off level floor. |
| `overseer_dimension_shift.wav` | *"Did you really think the hallway behind you was static? Non-Euclidean garbage collection in progress."* | Player turns 180° in a Shifting Room. |
| `overseer_sequence_break.wav` | *"Sequence break error in node register. Execute the correct subroutine order, Roxy."* | Player interacts with locked door before solving circuit puzzle. |
| `overseer_puzzle_solved.wav` | *"Pointer dereferenced. Corridor gate unlocked. Don't get cocky, the Glitch Walkers hear your footsteps."* | Player successfully completes a puzzle. |

---

## 3. Ambient Drone Music Generation

In **Gemini Experimental Audio / Music Generation Tools**, use these prompts:

### Track 1: Subterranean Server Drone (`ambient_drone_subterranean.wav`)
> *"Dark subterranean industrial drone, PS1 survival horror style, 55Hz deep sub-bass vibration, muffled server cooling fans echoing in concrete tunnels, eerie analog tape hiss, subtle metallic resonance, claustrophobic brutalist atmosphere, seamless loop."*

### Track 2: Server Rack Electric Hum (`ambient_server_hum.wav`)
> *"Hypnotic 60Hz electrical hum, high-voltage server busbars buzzing, distant data transmission beeps, low-frequency rumble, decaying reverb, psychological dread."*

---

## 4. Verification

After dropping the files in:
1. Run `./godot_project/run_tests.sh` to confirm `audio_manager.gd` indexes all audio files.
2. Launch the game in Next.js PWA or Godot to hear 3D spatial audio playback.
