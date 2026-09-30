extends PuzzleBase
class_name ParityCheckPuzzle

# Memory Leak Parity Check Purge
# Player purges memory blocks until the corrupted parity bit matches zero

var corrupted_blocks: int = 4

func _ready() -> void:
    super._ready()
    corrupted_blocks = required_steps

func purge_block() -> void:
    if is_completed:
        return
    corrupted_blocks = maxi(0, corrupted_blocks - 1)
    print("[ParityCheck] Purged memory block. Remaining corrupt blocks: ", corrupted_blocks)
    if corrupted_blocks == 0:
        complete_puzzle()

func _handle_player_input(_player: CharacterBody3D) -> void:
    purge_block()
