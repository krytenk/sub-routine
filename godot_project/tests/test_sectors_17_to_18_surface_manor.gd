extends Node
class_name TestSectors17To18SurfaceManor

# Unit Test Suite for Act III Surface Transition:
# - Sector 17: Clinical Behavioral Sanatorium Wing (Permanent closure of subterranean levels,
#   One-Way Mirror & X-Ray Lightbox pressure puzzle, and Cross-Sector Relic scavenging)
# - Sector 18: Vance Manor — Grand Atrium & Portrait Gallery (Grandfather Clock 45s Midnight Lockdown,
#   Grand Piano 440Hz Tuning Fork puzzle, Secret Study Silver Nitrate Daguerreotype, & Ballroom Crests)

const Level17Scene = preload("res://scenes/levels/level_17.tscn")
const Level18Scene = preload("res://scenes/levels/level_18.tscn")
const MapViewerModalScene = preload("res://scenes/ui/map_viewer_modal.tscn")

# 1. Test Sector 17: Permanent Subterranean Closure, One-Way Mirror X-Ray Lightbox Puzzle & Cross-Sector Relics
func test_sector_17_clinical_sanatorium_and_xray_mirror_puzzle() -> bool:
	var lvl = Level17Scene.instantiate()
	lvl._ready()

	# Verify subterranean facility is permanently closed off (no backtrack trigger to Sector 16)
	assert(lvl.is_subterranean_sealed_forever == true, "FAILED: Sector 17 must permanently seal off subterranean levels")
	var backtrack_node = lvl.find_child("Sector16BacktrackTrigger", true, false)
	assert(backtrack_node == null, "FAILED: Sector 17 must NOT allow backtracking into the collapsed subterranean shaft")

	var map_panel = lvl.find_child("WallMapPanel", true, false)
	assert(map_panel != null and map_panel.sector_index == 17, "FAILED: Sector 17 must contain WallMapPanel with sector_index 17")

	# Premature Lightbox and Oak Door interactions must reject
	lvl._on_xray_lightbox_interacted()
	assert(lvl.is_bone_pin_code_decoded == false, "FAILED: Lightbox must not decode Bone-Pin sequence before 3 X-Ray Plates are collected")

	# Collect all 3 Radiograph X-Ray Plates
	var xray1 = lvl.find_child("XRayPlate_Cranium", true, false)
	var xray2 = lvl.find_child("XRayPlate_Thorax", true, false)
	var xray3 = lvl.find_child("XRayPlate_Pelvis", true, false)
	assert(xray1 != null and xray2 != null and xray3 != null, "FAILED: Sector 17 must contain 3 X-Ray Plates")

	xray1.interact()
	xray2.interact()
	xray3.interact()
	assert(lvl.get_xray_plate_count() == 3, "FAILED: All 3 X-Ray Plates must register collected")

	# Turn ON X-Ray Lightbox -> decodes bone-pin code and starts 20s One-Way Mirror fracture countdown!
	lvl._on_xray_lightbox_interacted()
	assert(lvl.is_lightbox_illuminated == true, "FAILED: Lightbox must illuminate once all 3 X-Ray Plates are mounted")
	assert(lvl.is_bone_pin_code_decoded == true, "FAILED: Illuminating Lightbox must decode Surgical Bone-Pin sequence")

	# Simulate 5 seconds of glass fracture pressure, then shut off Lightbox before 20s breach
	lvl._process(5.0)
	assert(lvl.mirror_fracture_timer < 20.0 and lvl.is_mirror_shattered == false, "FAILED: Mirror fracture timer must count down while Lightbox is on")
	lvl._on_lightbox_kill_switch_pulled()
	assert(lvl.is_lightbox_illuminated == false, "FAILED: Kill switch must turn off Lightbox and restore One-Way Mirror")
	assert(lvl.is_mirror_shattered == false, "FAILED: Shutting off Lightbox in time must prevent One-Way Mirror breach")

	# Premature Oak Doors check (missing the 3 cross-sector Manor relics)
	lvl._on_oak_doors_terminal_accessed()
	assert(lvl.is_oak_doors_unlatched == false, "FAILED: Oak Doors must require the 3 Cross-Sector Relics before leaving the Clinic")

	# Scavenge the 3 Cross-Sector Relics needed in Sector 18 Vance Manor
	var relic_silver = lvl.find_child("Relic_SilverNitrate", true, false)
	var relic_fork = lvl.find_child("Relic_TuningFork", true, false)
	var relic_serpent = lvl.find_child("Relic_SerpentHalfCrest", true, false)
	assert(relic_silver != null and relic_fork != null and relic_serpent != null, "FAILED: Sector 17 must contain Silver Nitrate, Tuning Fork, and Serpent Half-Crest")

	relic_silver.interact()
	relic_fork.interact()
	relic_serpent.interact()
	assert(lvl.has_all_cross_sector_relics() == true, "FAILED: All 3 Cross-Sector Relics must register collected")

	# Now unlock the South Oak Double Doors into Sector 18 Vance Manor
	lvl._on_oak_doors_terminal_accessed()
	assert(lvl.is_oak_doors_unlatched == true, "FAILED: Sanatorium Oak Double Doors must unlatch once Bone-Pin Code and all 3 Relics are ready")

	lvl.queue_free()
	print("[PASS] test_sector_17_clinical_sanatorium_and_xray_mirror_puzzle: Subterranean closure, One-Way Mirror X-Ray Lightbox pressure puzzle, and Cross-Sector Relics validated.")
	return true

# 2. Test Sector 18: Vance Manor Grandfather Clock Lockdown & Cross-Sector Relic Puzzles
func test_sector_18_vance_manor_puzzles_and_relic_payoff() -> bool:
	var lvl = Level18Scene.instantiate()
	lvl._ready()

	var map_panel = lvl.find_child("WallMapPanel", true, false)
	assert(map_panel != null and map_panel.sector_index == 18, "FAILED: Sector 18 must contain WallMapPanel with sector_index 18")

	# Without Sector 17's relics, Grand Piano and Daguerreotype must reject
	lvl._on_grand_piano_interacted()
	assert(lvl.is_piano_chord_played == false, "FAILED: Grand Piano must require 440Hz Clinical Tuning Fork from Sector 17")

	# Grant the 3 relics carried over from Sector 17
	lvl.grant_sector17_relics_for_testing()

	# Step 1: Use 440Hz Tuning Fork on Grand Piano -> slides open Movable Bookcase to Secret Study
	lvl._on_grand_piano_interacted()
	assert(lvl.is_piano_chord_played == true, "FAILED: Grand Piano must play 440Hz resonant chord and open Secret Study")

	# Step 2: Use Silver Nitrate Developer on Unexposed Daguerreotype Plate in Secret Study
	lvl._on_daguerreotype_interacted()
	assert(lvl.is_daguerreotype_developed == true, "FAILED: Silver Nitrate Developer must develop the 1931 Vance Family Daguerreotype")

	# Step 3: Collect Raven Half-Crest in West Portrait Gallery -> triggers 45s Grandfather Clock Midnight Lockdown!
	var raven = lvl.find_child("Relic_RavenHalfCrest", true, false)
	var weight = lvl.find_child("Relic_LeadCounterweight", true, false)
	assert(raven != null and weight != null, "FAILED: Sector 18 must contain Raven Half-Crest and Lead Apothecary Weight")

	raven.interact()
	assert(lvl.has_raven_crest == true, "FAILED: Raven Half-Crest must register collected")
	assert(lvl.is_clock_lockdown_active == true, "FAILED: Lifting Raven Half-Crest must trigger Grandfather Clock 45s Midnight Lockdown")

	# Simulate 10s of countdown pressure, then collect Lead Apothecary Weight and disarm Grandfather Clock
	lvl._process(10.0)
	assert(lvl.clock_countdown_timer < 45.0, "FAILED: Grandfather Clock timer must count down while active")
	weight.interact()
	assert(lvl.has_lead_counterweight == true, "FAILED: Lead Apothecary Weight must register collected")

	lvl._on_grandfather_clock_interacted()
	assert(lvl.is_clock_lockdown_disarmed == true, "FAILED: Grandfather Clock must disarm once Lead Apothecary Weight is installed")
	assert(lvl.is_clock_lockdown_active == false, "FAILED: Disarming Grandfather Clock must stop the Midnight Lockdown")

	# Step 4: Unite Serpent & Raven Half-Crests at the South Ballroom Crest Doors
	lvl._on_ballroom_doors_interacted()
	assert(lvl.is_ballroom_unlocked == true, "FAILED: South Ballroom Crest Doors must unlock once all relics and puzzles are complete")

	lvl.queue_free()
	print("[PASS] test_sector_18_vance_manor_puzzles_and_relic_payoff: Vance Manor Grandfather Clock trap, Grand Piano bookcase, Daguerreotype, and Crest Doors validated.")
	return true

# 3. Test Map Viewer Blueprints for Sectors 17 and 18
func test_map_viewer_sectors_17_and_18() -> bool:
	for sec in [17, 18]:
		var path = "res://assets/textures/maps/sector_%02d_map.jpg" % sec
		assert(ResourceLoader.exists(path) or FileAccess.file_exists(path), "FAILED: Missing map blueprint " + path)

	var modal = MapViewerModalScene.instantiate()
	modal._ready()
	modal.open_map(17)
	assert(modal.current_sector_index == 17, "FAILED: MapViewerModal must open Sector 17")
	assert(modal.title_label.text.contains("SECTOR 17"), "FAILED: MapViewerModal must show Sector 17 title")

	modal._on_next_pressed()
	assert(modal.current_sector_index == 18, "FAILED: Next button must advance to Sector 18")
	assert(modal.title_label.text.contains("SECTOR 18"), "FAILED: MapViewerModal must show Sector 18 Vance Manor title")

	modal.queue_free()
	print("[PASS] test_map_viewer_sectors_17_and_18: Blueprints and navigation for Sectors 17-18 validated.")
	return true
