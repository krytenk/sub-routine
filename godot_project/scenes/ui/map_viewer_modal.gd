extends Control
class_name MapViewerModal

# Sub-Routine Diegetic Architectural Blueprint Viewer
# Full-screen retro CAD schematic viewer displaying high-detail sector floor plans.

signal map_opened(sector_index: int)
signal map_closed

const SECTOR_INFO = {
	1: {
		"title": "SECTOR 01: SUBTERRANEAN BIOS BOOT",
		"desc": "Cold Boot Chamber, Primary Bus Corridor, and Coolant Pump Bay. Starting sector."
	},
	2: {
		"title": "SECTOR 02: CORRUPTED CACHE TRENCH",
		"desc": "Suspended Gantry Catwalks, Sunken Trench Floor, and Auxiliary Substation Breaker."
	},
	3: {
		"title": "SECTOR 03: PRIMARY BUS CHASM & ASCENSION CORE",
		"desc": "Flooded Ground Sump Basin, Multi-Flight Ascension Stairs, and Upper Pedestal Deck."
	},
	4: {
		"title": "SECTOR 04: L1 CACHE LABYRINTH & CONCOURSE",
		"desc": "Grand Octagonal Concourse, Non-Euclidean Portal Rotunda, Kennel Sub-Tunnel, and Elevator."
	},
	5: {
		"title": "SECTOR 05: EXECUTIVE OVERLOOK & TRAM HUB",
		"desc": "Panoramic Observation Balcony, Central Atrium, Bio-Synthetic Lab, and MagLev Tram Platform."
	},
	6: {
		"title": "SECTOR 06: DEEP SERVER SUB-BASEMENT & VAULT",
		"desc": "Cryogenic Server Aisle Labyrinth, Coolant Fluid Manifolds, and High-Security Blast Bulkhead."
	},
	7: {
		"title": "SECTOR 07: STACK OVERFLOW VAULT & THE PROVING GROUNDS",
		"desc": "Sunken Assembly Trench, Overhead Ventilation Duct Network, Ordnance Proving Lab, and Blast Core."
	},
	8: {
		"title": "SECTOR 08: NULL POINTER CORRIDOR & STERILE WARD",
		"desc": "False Reprieve Decontamination Lounge, Lockdown Concourse, Surveillance CCTV Hub, and Overload Lab."
	},
	9: {
		"title": "SECTOR 09: THREAD LOCK ABYSS & MULTI-THREAD CORE",
		"desc": "Suspended Catwalk Abyss, Multi-Thread Deadlock Ring, Induction Observation Deck, and Core Gate."
	}
}

var current_sector_index: int = 1
var is_open: bool = false

@onready var texture_rect: TextureRect = find_child("BlueprintDisplay", true, false)
@onready var title_label: Label = find_child("SectorTitleLabel", true, false)
@onready var desc_label: Label = find_child("SectorDescLabel", true, false)
@onready var prev_btn: Button = find_child("PrevBtn", true, false)
@onready var next_btn: Button = find_child("NextBtn", true, false)
@onready var close_btn: Button = find_child("CloseBtn", true, false)

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	if prev_btn:
		prev_btn.pressed.connect(_on_prev_pressed)
	if next_btn:
		next_btn.pressed.connect(_on_next_pressed)
	if close_btn:
		close_btn.pressed.connect(close_map)

func open_map(sector_idx: int = -1) -> void:
	if sector_idx > 0:
		current_sector_index = clampi(sector_idx, 1, 9)
	else:
		var lm = get_node_or_null("/root/LevelManager")
		if lm:
			current_sector_index = clampi(lm.current_level_index, 1, 9)
		else:
			current_sector_index = 1

	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_display()
	map_opened.emit(current_sector_index)
	print("[MapViewer] Opened Sector ", current_sector_index, " blueprint.")

func close_map() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	map_closed.emit()
	print("[MapViewer] Blueprint viewer closed.")

func toggle_map() -> void:
	if is_open:
		close_map()
	else:
		open_map()

func _update_display() -> void:
	var path = "res://assets/textures/maps/sector_%02d_map.jpg" % current_sector_index
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path) as Texture2D
		if texture_rect:
			texture_rect.texture = tex

	var info = SECTOR_INFO.get(current_sector_index, {
		"title": "SECTOR %02d ARCHITECTURAL SCHEMATIC" % current_sector_index,
		"desc": "Subterranean Research Complex Facility Node"
	})

	if title_label:
		title_label.text = info["title"]
	if desc_label:
		desc_label.text = info["desc"]

func _on_prev_pressed() -> void:
	current_sector_index = 9 if current_sector_index <= 1 else (current_sector_index - 1)
	_update_display()

func _on_next_pressed() -> void:
	current_sector_index = 1 if current_sector_index >= 9 else (current_sector_index + 1)
	_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		if event.is_action_pressed("toggle_map"):
			toggle_map()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_map") or event.is_action_pressed("pause_game") or event.is_action_pressed("interact"):
		close_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
