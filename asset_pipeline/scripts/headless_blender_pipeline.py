#!/usr/bin/env python3
"""
Sub-Routine: Headless Blender Asset Pipeline (Production Grade)
Generates authentic PS1-era low-poly survival horror 3D models with:
- Multi-material assignments (textured metal, retro plastics, rubber, skin, fabrics)
- Emissive elements isolated strictly to screens, LED bezels, and cores (NO whole-object glowing squares)
- Smart UV projection with closest-neighbor texture filtering
- Vertex noise organic distortion for biological/decaying entities
- Binary glTF 2.0 (.glb) export directly to Godot assets directory
"""

import sys
import os
import math

try:
    import bpy
    import mathutils
except ImportError:
    print("[Headless Blender Pipeline] Note: 'bpy' not found in current Python interpreter.")
    print("This script is designed to run via: blender -b -P asset_pipeline/scripts/headless_blender_pipeline.py")
    sys.exit(0)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEXTURES_DIR = os.path.join(BASE_DIR, "asset_pipeline", "raw_textures")
OUTPUT_MODELS_DIR = os.path.join(BASE_DIR, "godot_project", "assets", "models")
os.makedirs(OUTPUT_MODELS_DIR, exist_ok=True)

def reset_scene():
    """Clear all objects and materials from scene."""
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color=(0.25, 0.25, 0.25, 1.0), roughness=0.7, metallic=0.1):
    """Creates standard PBR material without textures."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Base Color'].default_value = base_color
    node_bsdf.inputs['Roughness'].default_value = roughness
    node_bsdf.inputs['Metallic'].default_value = metallic
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def create_textured_material(name, texture_filename, roughness=0.8, metallic=0.2):
    """Creates Principled BSDF material mapped with texture."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')

    tex_path = os.path.join(TEXTURES_DIR, texture_filename)
    if os.path.exists(tex_path):
        node_tex = nodes.new(type='ShaderNodeTexImage')
        node_tex.image = bpy.data.images.load(tex_path)
        node_tex.interpolation = 'Closest' # PS1 crisp unfiltered texture
        links.new(node_tex.outputs['Color'], node_bsdf.inputs['Base Color'])
    else:
        node_bsdf.inputs['Base Color'].default_value = (0.3, 0.3, 0.3, 1.0)

    node_bsdf.inputs['Roughness'].default_value = roughness
    node_bsdf.inputs['Metallic'].default_value = metallic
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def create_emissive_material(name, emissive_color=(0.15, 0.85, 0.35, 1.0), strength=1.8, base_color=(0.04, 0.08, 0.04, 1.0)):
    """Creates emissive material strictly for screen surfaces or indicator LEDs."""
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    node_bsdf.inputs['Base Color'].default_value = base_color
    node_bsdf.inputs['Emission Color'].default_value = emissive_color
    node_bsdf.inputs['Emission Strength'].default_value = strength
    node_bsdf.inputs['Roughness'].default_value = 0.3
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    return mat

def apply_noise_distortion(mesh_obj, scale=0.1, frequency=2.0):
    """Adds subtle procedural noise distortion to vertices for decaying/glitched biological models."""
    mesh = mesh_obj.data
    for v in mesh.vertices:
        x, y, z = v.co
        noise_val = (
            math.sin(x * frequency * 2.1 + y * 1.3) *
            math.cos(y * frequency * 1.7 + z * 2.3) *
            math.sin(z * frequency * 1.9 + x * 0.9)
        )
        v.co += mathutils.Vector((noise_val * scale, noise_val * scale * 0.8, noise_val * scale * 1.1))
    mesh.update()

def smart_unwrap_object(obj):
    """Perform smart UV project on active object."""
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.02)
    bpy.ops.object.mode_set(mode='OBJECT')

def export_glb(filepath):
    """Exports active scene as a GLB file."""
    bpy.ops.export_scene.gltf(filepath=filepath, export_format='GLB')
    print(f"[Blender] Exported: {filepath}")

def add_part(mesh_type, location, scale=None, rotation=None, radius=None, depth=None, material=None, bevel=0.015, smooth=True):
    """Creates a primitive mesh component with smooth shading and optional bevel modifier."""
    if mesh_type == 'cube':
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    elif mesh_type == 'cylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius if radius else 0.1, depth=depth if depth else 0.5, location=location)
    elif mesh_type == 'sphere':
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=radius if radius else 0.15, location=location)
    elif mesh_type == 'cone':
        bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=radius if radius else 0.1, depth=depth if depth else 0.3, location=location)
    
    obj = bpy.context.active_object
    if scale:
        obj.scale = scale
    if rotation:
        obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=bool(rotation), scale=bool(scale))
    
    if bevel > 0:
        mod = obj.modifiers.new(name="Bevel", type='BEVEL')
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier="Bevel")
    if smooth:
        bpy.ops.object.shade_smooth()
    
    smart_unwrap_object(obj)
    if material:
        obj.data.materials.append(material)
    return obj

def join_objects_and_set_origin(objs, name, origin_point):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    main_obj = bpy.context.active_object
    main_obj.name = name
    bpy.context.scene.cursor.location = origin_point
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return main_obj


# ==============================================================================
# 1. CRT Terminal (Multi-Material: Rusted Metal Desk, Computer Case, Emissive Screen)
# ==============================================================================
def generate_crt_terminal():
    reset_scene()
    mat_desk = create_textured_material("DeskMat", "rusted_metal.jpg", roughness=0.85, metallic=0.4)
    mat_case = create_pbr_material("CaseMat", base_color=(0.28, 0.30, 0.28, 1.0), roughness=0.6, metallic=0.15)
    mat_screen = create_emissive_material("ScreenMat", emissive_color=(0.15, 0.85, 0.35, 1.0), strength=1.5, base_color=(0.02, 0.08, 0.03, 1.0))
    mat_keyboard = create_pbr_material("KeyboardMat", base_color=(0.15, 0.16, 0.16, 1.0), roughness=0.8, metallic=0.1)

    # Desk pedestal
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.375))
    desk = bpy.context.active_object
    desk.scale = (1.2, 0.8, 0.75)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(desk)
    desk.data.materials.append(mat_desk)

    # Keyboard base & keys
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.25, 0.78))
    kb = bpy.context.active_object
    kb.scale = (0.8, 0.3, 0.06)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(kb)
    kb.data.materials.append(mat_keyboard)

    # Monitor outer chassis
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.05, 1.08))
    mon = bpy.context.active_object
    mon.scale = (0.7, 0.6, 0.55)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(mon)
    mon.data.materials.append(mat_case)

    # Screen face ONLY (the only part that emits light!)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.26, 1.08))
    screen = bpy.context.active_object
    screen.scale = (0.52, 0.02, 0.38)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(screen)
    screen.data.materials.append(mat_screen)

    # Join into single model with preserved material slots
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [desk, kb, mon, screen]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = desk
    bpy.ops.object.join()
    desk.name = "CRTTerminal"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "crt_terminal.glb"))

# ==============================================================================
# 2. Mainframe Supercomputer Bank (Multi-Material: Labyrinth Textures, Brushed Blades, Tiny Status LEDs)
# ==============================================================================
def generate_mainframe_bank():
    reset_scene()
    mat_cabinet = create_textured_material("MainframeCabinet", "server_labyrinth.jpg", roughness=0.7, metallic=0.35)
    mat_blade = create_pbr_material("BladeMat", base_color=(0.18, 0.19, 0.22, 1.0), roughness=0.55, metallic=0.6)
    mat_cowl = create_pbr_material("CowlMat", base_color=(0.14, 0.15, 0.18, 1.0), roughness=0.8, metallic=0.3)
    mat_led_blue = create_emissive_material("LedBlue", emissive_color=(0.2, 0.5, 0.9, 1.0), strength=1.8, base_color=(0.05, 0.1, 0.2, 1.0))
    mat_led_amber = create_emissive_material("LedAmber", emissive_color=(0.9, 0.5, 0.1, 1.0), strength=1.8, base_color=(0.2, 0.1, 0.02, 1.0))

    # Main cabinet chassis
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.3))
    chassis = bpy.context.active_object
    chassis.scale = (2.2, 1.0, 2.6)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(chassis)
    chassis.data.materials.append(mat_cabinet)

    # Top exhaust cowl
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.7))
    cowl = bpy.context.active_object
    cowl.scale = (2.35, 1.1, 0.2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(cowl)
    cowl.data.materials.append(mat_cowl)

    parts = [chassis, cowl]

    # 6 rack blade drawer panels with tiny LED indicators
    for b in range(6):
        y_pos = 0.45 + b * 0.36
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.52, y_pos))
        blade = bpy.context.active_object
        blade.scale = (1.9, 0.05, 0.28)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        smart_unwrap_object(blade)
        blade.data.materials.append(mat_blade)
        parts.append(blade)

        # Tiny status LED (alternating blue and amber)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.85, 0.55, y_pos))
        led = bpy.context.active_object
        led.scale = (0.08, 0.02, 0.04)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        smart_unwrap_object(led)
        led.data.materials.append(mat_led_blue if b % 2 == 0 else mat_led_amber)
        parts.append(led)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = chassis
    bpy.ops.object.join()
    chassis.name = "MainframeBank"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "mainframe_bank.glb"))

# ==============================================================================
# 3. Memory Core Pickup (Multi-Material: Green PCB, Gold Contacts, Glowing Core)
# ==============================================================================
def generate_memory_core_pickup():
    reset_scene()
    mat_pcb = create_pbr_material("PCBMat", base_color=(0.08, 0.24, 0.12, 1.0), roughness=0.6, metallic=0.1)
    mat_gold = create_pbr_material("GoldContacts", base_color=(0.85, 0.72, 0.22, 1.0), roughness=0.3, metallic=0.95)
    mat_chip = create_pbr_material("ChipMat", base_color=(0.1, 0.1, 0.1, 1.0), roughness=0.7, metallic=0.1)
    mat_core = create_emissive_material("QuantumCore", emissive_color=(0.15, 0.85, 1.0, 1.0), strength=2.2, base_color=(0.05, 0.2, 0.3, 1.0))

    # PCB Board
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
    pcb = bpy.context.active_object
    pcb.scale = (0.28, 0.42, 0.02)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(pcb)
    pcb.data.materials.append(mat_pcb)

    # Gold edge connector pins
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.19, 0.5))
    gold = bpy.context.active_object
    gold.scale = (0.24, 0.05, 0.025)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(gold)
    gold.data.materials.append(mat_gold)

    # RAM IC chips
    chips = []
    for cx in [-0.07, 0.07]:
        for cy in [-0.1, 0.05]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, cy, 0.52))
            c = bpy.context.active_object
            c.scale = (0.07, 0.08, 0.02)
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            smart_unwrap_object(c)
            c.data.materials.append(mat_chip)
            chips.append(c)

    # Central glowing quantum core
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.02, 0.53))
    core = bpy.context.active_object
    core.scale = (0.09, 0.09, 0.035)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(core)
    core.data.materials.append(mat_core)

    all_objs = [pcb, gold, core] + chips
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = pcb
    bpy.ops.object.join()
    pcb.name = "MemoryCore"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "memory_core_pickup.glb"))

# ==============================================================================
# 4. Coolant Pipe Junction (Multi-Material: Rusted Iron Pipes, Red Wheel, Brass Gauge)
# ==============================================================================
def generate_coolant_pipe_junction():
    reset_scene()
    mat_pipe = create_textured_material("PipeMat", "rusted_metal.jpg", roughness=0.75, metallic=0.5)
    mat_valve = create_pbr_material("ValveWheelMat", base_color=(0.78, 0.22, 0.12, 1.0), roughness=0.6, metallic=0.3)
    mat_brass = create_pbr_material("BrassMat", base_color=(0.72, 0.58, 0.22, 1.0), roughness=0.4, metallic=0.8)

    # Main vertical conduit
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=3.2, location=(0, 0, 1.6))
    pipe_v = bpy.context.active_object
    smart_unwrap_object(pipe_v)
    pipe_v.data.materials.append(mat_pipe)

    # Cross pipe
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=2.2, location=(0, 0, 1.8))
    pipe_h = bpy.context.active_object
    pipe_h.rotation_euler = (0, 1.5708, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    smart_unwrap_object(pipe_h)
    pipe_h.data.materials.append(mat_pipe)

    # Flanges (bolted metal rings)
    flange_objs = []
    flange_positions = [(0, 0, 3.1), (0, 0, 0.1), (-1.05, 0, 1.8), (1.05, 0, 1.8)]
    for fp in flange_positions:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.24, depth=0.08, location=fp)
        flg = bpy.context.active_object
        if fp[0] != 0:
            flg.rotation_euler = (0, 1.5708, 0)
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        smart_unwrap_object(flg)
        flg.data.materials.append(mat_pipe)
        flange_objs.append(flg)

    # Valve stem (brass)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.35, location=(0, 0.25, 1.8))
    stem = bpy.context.active_object
    stem.rotation_euler = (1.5708, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    smart_unwrap_object(stem)
    stem.data.materials.append(mat_brass)

    # Valve wheel (hazard red/orange)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.035, location=(0, 0.42, 1.8))
    wheel = bpy.context.active_object
    wheel.rotation_euler = (1.5708, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    smart_unwrap_object(wheel)
    wheel.data.materials.append(mat_valve)

    # Pressure gauge
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.08, location=(0.35, 0.18, 2.3))
    gauge = bpy.context.active_object
    gauge.rotation_euler = (1.5708, 0, 0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    smart_unwrap_object(gauge)
    gauge.data.materials.append(mat_brass)

    all_objs = [pipe_v, pipe_h, stem, wheel, gauge] + flange_objs
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = pipe_v
    bpy.ops.object.join()
    pipe_v.name = "CoolantPipe"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "coolant_pipe_junction.glb"))

# ==============================================================================
# 5. Bulkhead Blast Door (Multi-Material: Steel Frame, Hazard Yellow Accents, Chrome Pistons)
# ==============================================================================
def generate_blast_door():
    reset_scene()
    mat_frame = create_pbr_material("SteelFrame", base_color=(0.22, 0.24, 0.26, 1.0), roughness=0.7, metallic=0.6)
    mat_leaves = create_textured_material("DoorLeafMat", "rusted_metal.jpg", roughness=0.6, metallic=0.5)
    mat_hazard = create_pbr_material("HazardYellow", base_color=(0.85, 0.72, 0.12, 1.0), roughness=0.5, metallic=0.2)
    mat_chrome = create_pbr_material("PistonChrome", base_color=(0.85, 0.85, 0.88, 1.0), roughness=0.15, metallic=0.95)
    mat_status_red = create_emissive_material("DoorStatusRed", emissive_color=(1.0, 0.05, 0.05, 1.0), strength=2.5, base_color=(0.3, 0.02, 0.02, 1.0))

    # 1. Door Frame (Permanent stationary structure)
    frame_parts = []
    post_l = add_part('cube', (-1.65, 0, 1.7), scale=(0.5, 0.6, 3.4), material=mat_frame, bevel=0.02)
    post_r = add_part('cube', (1.65, 0, 1.7), scale=(0.5, 0.6, 3.4), material=mat_frame, bevel=0.02)
    header = add_part('cube', (0, 0, 3.45), scale=(3.8, 0.7, 0.5), material=mat_frame, bevel=0.02)
    caution = add_part('cube', (0, 0.36, 3.45), scale=(3.6, 0.04, 0.24), material=mat_hazard, bevel=0.005)
    status_lamp = add_part('cube', (0, 0.37, 3.15), scale=(0.3, 0.04, 0.1), material=mat_status_red, bevel=0.005)
    piston_l = add_part('cylinder', (-1.2, 0.22, 3.1), radius=0.07, depth=0.8, rotation=(0, 1.5708, 0), material=mat_chrome, bevel=0.008)
    piston_r = add_part('cylinder', (1.2, 0.22, 3.1), radius=0.07, depth=0.8, rotation=(0, 1.5708, 0), material=mat_chrome, bevel=0.008)
    frame_parts.extend([post_l, post_r, header, caution, status_lamp, piston_l, piston_r])
    frame_obj = join_objects_and_set_origin(frame_parts, "DoorFrame", (0, 0, 0))

    # 2. DoorLeaf_L (Left sliding leaf) - Origin at center of leaf
    leaf_l = add_part('cube', (-0.75, 0, 1.6), scale=(1.5, 0.18, 3.0), material=mat_leaves, bevel=0.02)
    rib_l = add_part('cube', (-0.75, 0.10, 1.6), scale=(1.3, 0.04, 0.2), material=mat_frame, bevel=0.01)
    leaf_l_obj = join_objects_and_set_origin([leaf_l, rib_l], "DoorLeaf_L", (-0.75, 0, 1.6))

    # 3. DoorLeaf_R (Right sliding leaf) - Origin at center of leaf
    leaf_r = add_part('cube', (0.75, 0, 1.6), scale=(1.5, 0.18, 3.0), material=mat_leaves, bevel=0.02)
    rib_r = add_part('cube', (0.75, 0.10, 1.6), scale=(1.3, 0.04, 0.2), material=mat_frame, bevel=0.01)
    leaf_r_obj = join_objects_and_set_origin([leaf_r, rib_r], "DoorLeaf_R", (0.75, 0, 1.6))

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "blast_door.glb"))


# ==============================================================================
# 6. Industrial Cable Nest (Multi-Material: Black Rubber Cables, Galvanized Steel Clamps)
# ==============================================================================
def generate_cable_nest():
    reset_scene()
    mat_rubber = create_pbr_material("RubberCable", base_color=(0.12, 0.12, 0.14, 1.0), roughness=0.92, metallic=0.05)
    mat_clamp = create_pbr_material("SteelClamp", base_color=(0.55, 0.55, 0.60, 1.0), roughness=0.4, metallic=0.85)

    cables = []
    # 4 snaking curved cable paths
    for i, z_offset in enumerate([-0.4, -0.15, 0.15, 0.4]):
        bpy.ops.curve.primitive_bezier_curve_add(location=(0, z_offset, 0.04))
        curve = bpy.context.active_object
        curve.data.bevel_depth = 0.05
        curve.data.bevel_resolution = 3
        bpy.ops.object.convert(target='MESH')
        c_obj = bpy.context.active_object
        smart_unwrap_object(c_obj)
        c_obj.data.materials.append(mat_rubber)
        cables.append(c_obj)

    # Floor tie-down clamps
    clamps = []
    for cx in [-0.8, 0.1, 0.8]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(cx, 0, 0.05))
        cl = bpy.context.active_object
        cl.scale = (0.12, 1.2, 0.08)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        smart_unwrap_object(cl)
        cl.data.materials.append(mat_clamp)
        clamps.append(cl)

    all_objs = cables + clamps
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = all_objs[0]
    bpy.ops.object.join()
    all_objs[0].name = "CableNest"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "cable_nest.glb"))

# ==============================================================================
# 7. Server Monolith Rack (Multi-Material: Labyrinth Sides, Steel Kickplates)
# ==============================================================================
def generate_server_rack():
    reset_scene()
    mat_side = create_textured_material("ServerRackTex", "server_labyrinth.jpg", roughness=0.7, metallic=0.4)
    mat_bezel = create_pbr_material("RackBezel", base_color=(0.15, 0.16, 0.18, 1.0), roughness=0.8, metallic=0.5)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.2))
    body = bpy.context.active_object
    body.scale = (1.0, 0.8, 2.4)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(body)
    body.data.materials.append(mat_side)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 2.35))
    top = bpy.context.active_object
    top.scale = (1.08, 0.88, 0.1)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(top)
    top.data.materials.append(mat_bezel)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.05))
    bot = bpy.context.active_object
    bot.scale = (1.08, 0.88, 0.1)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(bot)
    bot.data.materials.append(mat_bezel)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in [body, top, bot]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    body.name = "ServerRack"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "server_rack.glb"))

# ==============================================================================
# 8. Server Corridor Module (Complete Architecture: Ceiling, Floor, Wall Racks, Rafters)
# ==============================================================================
def generate_server_corridor():
    reset_scene()
    mat_wall = create_textured_material("CorridorWall", "server_labyrinth.jpg", roughness=0.75, metallic=0.3)
    mat_floor = create_textured_material("CorridorFloor", "rusted_metal.jpg", roughness=0.85, metallic=0.4)
    mat_rafter = create_pbr_material("SteelRafter", base_color=(0.18, 0.20, 0.22, 1.0), roughness=0.7, metallic=0.6)

    # Floor with non-slip industrial look
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.1))
    floor_obj = bpy.context.active_object
    floor_obj.scale = (4.0, 8.0, 0.2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(floor_obj)
    floor_obj.data.materials.append(mat_floor)

    # Ceiling overhead structure
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.9))
    ceiling_obj = bpy.context.active_object
    ceiling_obj.scale = (4.0, 8.0, 0.2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(ceiling_obj)
    ceiling_obj.data.materials.append(mat_floor)

    # Left & Right walls
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.0, 0, 1.9))
    wall_l = bpy.context.active_object
    wall_l.scale = (0.2, 8.0, 3.8)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(wall_l)
    wall_l.data.materials.append(mat_wall)

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.0, 0, 1.9))
    wall_r = bpy.context.active_object
    wall_r.scale = (0.2, 8.0, 3.8)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(wall_r)
    wall_r.data.materials.append(mat_wall)

    # Structural support pillars along corridor
    pillars = []
    for y_pos in [-2.5, 0.0, 2.5]:
        for x_pos in [-1.8, 1.8]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x_pos, y_pos, 1.9))
            p = bpy.context.active_object
            p.scale = (0.35, 0.45, 3.8)
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            smart_unwrap_object(p)
            p.data.materials.append(mat_rafter)
            pillars.append(p)

    all_objs = [floor_obj, ceiling_obj, wall_l, wall_r] + pillars
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = floor_obj
    bpy.ops.object.join()
    floor_obj.name = "ServerCorridor"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "server_corridor.glb"))

# ==============================================================================
# 9. Glitch Walker (Multi-Material Biomech Nightmare: Articulated Limb Hierarchy)
# ==============================================================================
def generate_glitch_walker():
    reset_scene()
    mat_chassis = create_pbr_material("WalkerArmor", base_color=(0.12, 0.13, 0.15, 1.0), roughness=0.4, metallic=0.85)
    mat_flesh = create_textured_material("FleshMat", "decaying_flesh.jpg", roughness=0.8, metallic=0.1)
    mat_cables = create_pbr_material("WalkerCables", base_color=(0.06, 0.06, 0.07, 1.0), roughness=0.9, metallic=0.05)
    mat_talons = create_pbr_material("WalkerTalons", base_color=(0.08, 0.09, 0.10, 1.0), roughness=0.2, metallic=0.95)
    mat_core_glow = create_emissive_material("GlitchEye", emissive_color=(1.0, 0.03, 0.03, 1.0), strength=3.5, base_color=(0.25, 0.01, 0.01, 1.0))

    # 1. HEAD (Predatory Alien Skull, Jaw, Crimson Optical Visor) - Pivot at (0, 0.18, 1.76)
    head_parts = []
    skull = add_part('cube', (0, 0.25, 1.88), scale=(0.22, 0.40, 0.22), material=mat_chassis, bevel=0.03)
    crest = add_part('cube', (0, -0.05, 1.96), scale=(0.18, 0.35, 0.14), material=mat_flesh, bevel=0.025)
    jaw = add_part('cube', (0, 0.30, 1.76), scale=(0.18, 0.28, 0.09), material=mat_talons, bevel=0.015)
    eye_slit = add_part('cube', (0, 0.46, 1.89), scale=(0.20, 0.02, 0.04), material=mat_core_glow, bevel=0.0)
    head_parts.extend([skull, crest, jaw, eye_slit])
    for side in [-1, 1]:
        cable = add_part('cylinder', (side * 0.10, -0.02, 1.76), radius=0.025, depth=0.30, rotation=(0.5, side * 0.2, 0), material=mat_cables, bevel=0.005)
        head_parts.append(cable)
    head_obj = join_objects_and_set_origin(head_parts, "Head", (0, 0.18, 1.76))

    # 2. TORSO (Spine, Ribcage, Corrupted Core, Pelvis) - Pivot at (0, -0.08, 0.90)
    torso_parts = []
    spine_segments = [
        ((0, -0.10, 0.95), 0.12),
        ((0, -0.06, 1.12), 0.11),
        ((0, -0.01, 1.30), 0.11),
        ((0, 0.05, 1.48), 0.10),
        ((0, 0.12, 1.65), 0.09),
        ((0, 0.18, 1.80), 0.08),
    ]
    for loc, rad in spine_segments:
        vert = add_part('cylinder', loc, radius=rad, depth=0.12, material=mat_chassis, bevel=0.015)
        fin = add_part('cube', (loc[0], loc[1] - rad - 0.05, loc[2]), scale=(0.03, 0.10, 0.08), material=mat_talons, bevel=0.008)
        torso_parts.extend([vert, fin])
    core = add_part('sphere', (0, 0.06, 1.38), radius=0.12, material=mat_core_glow)
    flesh_mass = add_part('cube', (0, 0.02, 1.36), scale=(0.34, 0.28, 0.42), material=mat_flesh, bevel=0.04)
    torso_parts.extend([core, flesh_mass])
    for rz in [1.24, 1.36, 1.48, 1.60]:
        for side in [-1, 1]:
            rib = add_part('cylinder', (side * 0.18, 0.08, rz), radius=0.022, depth=0.30, rotation=(0, side * 0.6, 0.8), material=mat_chassis, bevel=0.005)
            torso_parts.append(rib)
    pelvis = add_part('cube', (0, -0.08, 0.90), scale=(0.38, 0.28, 0.18), material=mat_chassis, bevel=0.025)
    torso_parts.append(pelvis)
    torso_obj = join_objects_and_set_origin(torso_parts, "Torso", (0, -0.08, 0.90))

    # 3. LEFT CLAW ARM - Pivot at shoulder (-0.36, 0.08, 1.62)
    arm_l_parts = []
    sh_l = add_part('sphere', (-0.36, 0.08, 1.62), radius=0.12, material=mat_chassis)
    up_l = add_part('cylinder', (-0.42, 0.10, 1.38), radius=0.065, depth=0.45, rotation=(-0.3, 0, 0.2), material=mat_chassis, bevel=0.012)
    spur_l = add_part('cone', (-0.45, -0.04, 1.20), radius=0.04, depth=0.16, rotation=(-1.5, 0, 0), material=mat_talons, bevel=0.005)
    fo_l = add_part('cylinder', (-0.44, 0.18, 1.00), radius=0.06, depth=0.45, rotation=(0.4, 0, -0.1), material=mat_flesh, bevel=0.012)
    palm_l = add_part('cube', (-0.44, 0.28, 0.78), scale=(0.12, 0.14, 0.08), material=mat_chassis, bevel=0.01)
    arm_l_parts.extend([sh_l, up_l, spur_l, fo_l, palm_l])
    for f_idx, fx in enumerate([-0.04, 0.0, 0.04]):
        talon = add_part('cone', (-0.44 + fx, 0.36 + f_idx * 0.02, 0.68), radius=0.022, depth=0.22, rotation=(1.2, 0, 0), material=mat_talons, bevel=0.004)
        arm_l_parts.append(talon)
    arm_l_obj = join_objects_and_set_origin(arm_l_parts, "Arm_L", (-0.36, 0.08, 1.62))

    # 4. RIGHT CLAW ARM - Pivot at shoulder (0.36, 0.08, 1.62)
    arm_r_parts = []
    sh_r = add_part('sphere', (0.36, 0.08, 1.62), radius=0.12, material=mat_chassis)
    up_r = add_part('cylinder', (0.32, 0.10, 1.38), radius=0.065, depth=0.45, rotation=(-0.3, 0, -0.2), material=mat_chassis, bevel=0.012)
    spur_r = add_part('cone', (0.45, -0.04, 1.20), radius=0.04, depth=0.16, rotation=(-1.5, 0, 0), material=mat_talons, bevel=0.005)
    fo_r = add_part('cylinder', (0.44, 0.18, 1.00), radius=0.06, depth=0.45, rotation=(0.4, 0, 0.1), material=mat_flesh, bevel=0.012)
    palm_r = add_part('cube', (0.44, 0.28, 0.78), scale=(0.12, 0.14, 0.08), material=mat_chassis, bevel=0.01)
    arm_r_parts.extend([sh_r, up_r, spur_r, fo_r, palm_r])
    for f_idx, fx in enumerate([-0.04, 0.0, 0.04]):
        talon = add_part('cone', (0.44 + fx, 0.36 + f_idx * 0.02, 0.68), radius=0.022, depth=0.22, rotation=(1.2, 0, 0), material=mat_talons, bevel=0.004)
        arm_r_parts.append(talon)
    arm_r_obj = join_objects_and_set_origin(arm_r_parts, "Arm_R", (0.36, 0.08, 1.62))

    # 5. LEFT DIGITIGRADE LEG - Pivot at hip (-0.20, 0, 0.88)
    leg_l_parts = []
    thigh_l = add_part('cylinder', (-0.20, 0.04, 0.76), radius=0.08, depth=0.34, rotation=(0.5, 0, 0.1), material=mat_flesh, bevel=0.012)
    knee_l = add_part('sphere', (-0.20, 0.16, 0.63), radius=0.075, material=mat_chassis)
    shank_l = add_part('cylinder', (-0.20, 0.06, 0.42), radius=0.065, depth=0.38, rotation=(-0.6, 0, -0.1), material=mat_chassis, bevel=0.012)
    hock_l = add_part('sphere', (-0.20, -0.06, 0.26), radius=0.06, material=mat_chassis)
    foot_l = add_part('cylinder', (-0.20, 0.04, 0.14), radius=0.05, depth=0.26, rotation=(0.5, 0, 0), material=mat_cables, bevel=0.008)
    leg_l_parts.extend([thigh_l, knee_l, shank_l, hock_l, foot_l])
    for t_idx, tx in enumerate([-0.05, 0.0, 0.05]):
        claw = add_part('cone', (-0.20 + tx, 0.16 + (1 - abs(t_idx - 1)) * 0.04, 0.03), radius=0.02, depth=0.18, rotation=(1.5, 0, 0), material=mat_talons, bevel=0.004)
        leg_l_parts.append(claw)
    leg_l_obj = join_objects_and_set_origin(leg_l_parts, "Leg_L", (-0.20, 0, 0.88))

    # 6. RIGHT DIGITIGRADE LEG - Pivot at hip (0.20, 0, 0.88)
    leg_r_parts = []
    thigh_r = add_part('cylinder', (0.20, 0.04, 0.76), radius=0.08, depth=0.34, rotation=(0.5, 0, -0.1), material=mat_flesh, bevel=0.012)
    knee_r = add_part('sphere', (0.20, 0.16, 0.63), radius=0.075, material=mat_chassis)
    shank_r = add_part('cylinder', (0.20, 0.06, 0.42), radius=0.065, depth=0.38, rotation=(-0.6, 0, 0.1), material=mat_chassis, bevel=0.012)
    hock_r = add_part('sphere', (0.20, -0.06, 0.26), radius=0.06, material=mat_chassis)
    foot_r = add_part('cylinder', (0.20, 0.04, 0.14), radius=0.05, depth=0.26, rotation=(0.5, 0, 0), material=mat_cables, bevel=0.008)
    leg_r_parts.extend([thigh_r, knee_r, shank_r, hock_r, foot_r])
    for t_idx, tx in enumerate([-0.05, 0.0, 0.05]):
        claw = add_part('cone', (0.20 + tx, 0.16 + (1 - abs(t_idx - 1)) * 0.04, 0.03), radius=0.02, depth=0.18, rotation=(1.5, 0, 0), material=mat_talons, bevel=0.004)
        leg_r_parts.append(claw)
    leg_r_obj = join_objects_and_set_origin(leg_r_parts, "Leg_R", (0.20, 0, 0.88))

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "glitch_walker.glb"))

# ==============================================================================
# 10. Roxy Vance (Articulated PS1 Heroine: Face/Chin, Bangs/Ponytail, Combat Vest,
#     Utility Belt & Holster, Cargo Shorts, Separated Pivoted Limbs for Walking)
# ==============================================================================
def generate_roxy_vance():
    reset_scene()
    mat_skin = create_pbr_material("RoxySkin", base_color=(0.88, 0.72, 0.62, 1.0), roughness=0.55, metallic=0.0)
    mat_hair = create_pbr_material("RoxyHair", base_color=(0.18, 0.12, 0.08, 1.0), roughness=0.85, metallic=0.05)
    mat_top = create_pbr_material("RoxyCropTop", base_color=(0.52, 0.11, 0.16, 1.0), roughness=0.65, metallic=0.05)
    mat_straps = create_pbr_material("RoxyStraps", base_color=(0.10, 0.10, 0.12, 1.0), roughness=0.8, metallic=0.2)
    mat_shorts = create_pbr_material("RoxyCargoShorts", base_color=(0.28, 0.32, 0.22, 1.0), roughness=0.8, metallic=0.05)
    mat_belt = create_pbr_material("RoxyBelt", base_color=(0.08, 0.08, 0.09, 1.0), roughness=0.6, metallic=0.3)
    mat_buckle = create_pbr_material("RoxyBuckle", base_color=(0.85, 0.78, 0.35, 1.0), roughness=0.25, metallic=0.95)
    mat_boots = create_pbr_material("RoxyBoots", base_color=(0.12, 0.12, 0.13, 1.0), roughness=0.85, metallic=0.1)
    mat_gloves = create_pbr_material("RoxyGloves", base_color=(0.14, 0.14, 0.16, 1.0), roughness=0.75, metallic=0.1)
    mat_holster = create_pbr_material("RoxyHolster", base_color=(0.20, 0.22, 0.24, 1.0), roughness=0.5, metallic=0.6)
    mat_eyes = create_emissive_material("RoxyEyes", emissive_color=(0.2, 0.7, 0.95, 1.0), strength=1.4, base_color=(0.1, 0.4, 0.6, 1.0))
    mat_eyebrows = create_pbr_material("RoxyBrows", base_color=(0.15, 0.09, 0.06, 1.0), roughness=0.9, metallic=0.0)
    mat_lips = create_pbr_material("RoxyLips", base_color=(0.82, 0.42, 0.46, 1.0), roughness=0.4, metallic=0.0)
    mat_pda = create_emissive_material("RoxyPDA", emissive_color=(0.15, 0.9, 0.4, 1.0), strength=2.0, base_color=(0.04, 0.12, 0.05, 1.0))
    mat_gun = create_pbr_material("RoxyPistol", base_color=(0.12, 0.13, 0.15, 1.0), roughness=0.35, metallic=0.85)
    mat_comms = create_pbr_material("RoxyHeadset", base_color=(0.15, 0.16, 0.18, 1.0), roughness=0.4, metallic=0.9)

    # 1. HEAD (Face, jaw, chin, eyes, brows, nose, lips, comms headset, bangs, ponytail) - Pivot at neck (0, 0, 1.48)
    head_parts = []
    head_cranium = add_part('sphere', (0, 0, 1.63), radius=0.14, material=mat_skin)
    head_jaw = add_part('cone', (0, 0.04, 1.55), radius=0.12, depth=0.14, rotation=(3.1415, 0, 0), material=mat_skin, bevel=0.015)
    chin = add_part('sphere', (0, 0.08, 1.50), radius=0.035, material=mat_skin)
    nose = add_part('cone', (0, 0.14, 1.61), radius=0.02, depth=0.05, rotation=(1.5708, 0, 0), material=mat_skin, bevel=0.005)
    lips = add_part('cube', (0, 0.11, 1.54), scale=(0.045, 0.015, 0.012), material=mat_lips, bevel=0.003)
    eye_l = add_part('sphere', (-0.052, 0.12, 1.63), radius=0.022, material=mat_eyes)
    eye_r = add_part('sphere', (0.052, 0.12, 1.63), radius=0.022, material=mat_eyes)
    brow_l = add_part('cube', (-0.055, 0.125, 1.66), scale=(0.045, 0.012, 0.008), rotation=(0, 0, 0.15), material=mat_eyebrows, bevel=0.002)
    brow_r = add_part('cube', (0.055, 0.125, 1.66), scale=(0.045, 0.012, 0.008), rotation=(0, 0, -0.15), material=mat_eyebrows, bevel=0.002)
    head_parts.extend([head_cranium, head_jaw, chin, nose, lips, eye_l, eye_r, brow_l, brow_r])

    for ex in [-0.13, 0.13]:
        ear = add_part('cube', (ex, -0.02, 1.62), scale=(0.02, 0.04, 0.05), material=mat_skin, bevel=0.005)
        head_parts.append(ear)

    # Tactical comms headset
    headset_ear = add_part('cylinder', (-0.14, -0.02, 1.62), radius=0.025, depth=0.03, rotation=(0, 0, 1.5708), material=mat_comms, bevel=0.005)
    headset_mic = add_part('cylinder', (-0.12, 0.06, 1.56), radius=0.008, depth=0.10, rotation=(0.8, -0.4, 0), material=mat_comms, bevel=0.002)
    head_parts.extend([headset_ear, headset_mic])

    # Hair
    hair_crown = add_part('sphere', (0, -0.04, 1.68), radius=0.155, material=mat_hair)
    hair_back = add_part('cube', (0, -0.09, 1.62), scale=(0.24, 0.12, 0.20), material=mat_hair, bevel=0.03)
    bangs_l = add_part('cone', (-0.07, 0.09, 1.69), radius=0.05, depth=0.14, rotation=(-0.4, 0.5, 0), material=mat_hair, bevel=0.01)
    bangs_r = add_part('cone', (0.07, 0.09, 1.69), radius=0.05, depth=0.14, rotation=(-0.4, -0.5, 0), material=mat_hair, bevel=0.01)
    side_l = add_part('cylinder', (-0.12, 0.04, 1.58), radius=0.022, depth=0.16, rotation=(0.2, 0, -0.2), material=mat_hair, bevel=0.008)
    side_r = add_part('cylinder', (0.12, 0.04, 1.58), radius=0.022, depth=0.16, rotation=(0.2, 0, 0.2), material=mat_hair, bevel=0.008)
    hair_tie = add_part('cylinder', (0, -0.16, 1.67), radius=0.045, depth=0.035, rotation=(1.5708, 0, 0), material=mat_buckle, bevel=0.005)
    ponytail_1 = add_part('cylinder', (0, -0.21, 1.59), radius=0.045, depth=0.18, rotation=(0.4, 0, 0), material=mat_hair, bevel=0.012)
    ponytail_2 = add_part('cone', (0, -0.26, 1.44), radius=0.04, depth=0.18, rotation=(0.2, 0, 0), material=mat_hair, bevel=0.01)
    neck = add_part('cylinder', (0, 0, 1.48), radius=0.065, depth=0.10, material=mat_skin, bevel=0.01)
    choker = add_part('cylinder', (0, 0, 1.46), radius=0.07, depth=0.025, material=mat_straps, bevel=0.004)
    head_parts.extend([hair_crown, hair_back, bangs_l, bangs_r, side_l, side_r, hair_tie, ponytail_1, ponytail_2, neck, choker])
    head_obj = join_objects_and_set_origin(head_parts, "Head", (0, 0, 1.48))

    # 2. TORSO (Chest, bust, harness, waist, belt, holster & gun, canisters, pelvis) - Pivot at (0, 0, 1.0)
    torso_parts = []
    chest = add_part('cube', (0, 0, 1.34), scale=(0.34, 0.24, 0.24), material=mat_top, bevel=0.03)
    bust_l = add_part('sphere', (-0.08, 0.07, 1.33), radius=0.08, material=mat_top)
    bust_r = add_part('sphere', (0.08, 0.07, 1.33), radius=0.08, material=mat_top)
    strap_l = add_part('cube', (-0.11, 0, 1.36), scale=(0.04, 0.25, 0.24), material=mat_straps, bevel=0.008)
    strap_r = add_part('cube', (0.11, 0, 1.36), scale=(0.04, 0.25, 0.24), material=mat_straps, bevel=0.008)
    strap_h = add_part('cube', (0, 0.125, 1.33), scale=(0.05, 0.02, 0.05), material=mat_buckle, bevel=0.005)
    midriff = add_part('cube', (0, 0, 1.18), scale=(0.28, 0.20, 0.12), material=mat_skin, bevel=0.02)
    belt = add_part('cube', (0, 0, 1.09), scale=(0.33, 0.23, 0.06), material=mat_belt, bevel=0.01)
    buckle = add_part('cube', (0, 0.12, 1.09), scale=(0.07, 0.02, 0.05), material=mat_buckle, bevel=0.005)
    holster = add_part('cube', (0.18, 0, 1.04), scale=(0.06, 0.12, 0.14), material=mat_holster, bevel=0.01)
    gun_grip = add_part('cube', (0.18, -0.02, 1.14), scale=(0.04, 0.08, 0.08), rotation=(0.3, 0, 0), material=mat_gun, bevel=0.005)
    pouch_l = add_part('cube', (-0.17, 0, 1.06), scale=(0.05, 0.09, 0.08), material=mat_straps, bevel=0.01)
    canister_1 = add_part('cylinder', (-0.07, -0.12, 1.09), radius=0.025, depth=0.08, material=mat_comms, bevel=0.004)
    canister_2 = add_part('cylinder', (0.07, -0.12, 1.09), radius=0.025, depth=0.08, material=mat_comms, bevel=0.004)
    pelvis = add_part('cube', (0, 0, 0.98), scale=(0.34, 0.24, 0.18), material=mat_shorts, bevel=0.025)
    torso_parts.extend([chest, bust_l, bust_r, strap_l, strap_r, strap_h, midriff, belt, buckle, holster, gun_grip, pouch_l, canister_1, canister_2, pelvis])
    torso_obj = join_objects_and_set_origin(torso_parts, "Torso", (0, 0, 1.0))

    # 3. LEFT ARM - Pivot at shoulder (-0.22, 0, 1.38)
    arm_l_parts = []
    sh_l = add_part('sphere', (-0.21, 0, 1.38), radius=0.07, material=mat_skin)
    up_l = add_part('cylinder', (-0.22, 0, 1.25), radius=0.055, depth=0.22, material=mat_skin, bevel=0.01)
    el_l = add_part('sphere', (-0.22, 0, 1.14), radius=0.05, material=mat_skin)
    fo_l = add_part('cylinder', (-0.23, 0.02, 1.04), radius=0.048, depth=0.18, material=mat_skin, bevel=0.01)
    pda_casing = add_part('cube', (-0.24, 0.04, 1.02), scale=(0.08, 0.07, 0.09), material=mat_comms, bevel=0.006)
    pda_screen = add_part('cube', (-0.24, 0.076, 1.02), scale=(0.06, 0.01, 0.06), material=mat_pda, bevel=0.002)
    cuff_l = add_part('cylinder', (-0.23, 0.03, 0.94), radius=0.055, depth=0.05, material=mat_straps, bevel=0.005)
    hand_l = add_part('cube', (-0.23, 0.04, 0.88), scale=(0.07, 0.08, 0.09), material=mat_gloves, bevel=0.015)
    knuckles_l = add_part('cube', (-0.23, 0.05, 0.86), scale=(0.065, 0.025, 0.035), material=mat_comms, bevel=0.003)
    thumb_l = add_part('cone', (-0.20, 0.06, 0.89), radius=0.018, depth=0.05, rotation=(0.5, 0.5, 0), material=mat_gloves, bevel=0.003)
    arm_l_parts.extend([sh_l, up_l, el_l, fo_l, pda_casing, pda_screen, cuff_l, hand_l, knuckles_l, thumb_l])
    arm_l_obj = join_objects_and_set_origin(arm_l_parts, "Arm_L", (-0.22, 0, 1.38))

    # 4. RIGHT ARM - Pivot at shoulder (0.22, 0, 1.38)
    arm_r_parts = []
    sh_r = add_part('sphere', (0.21, 0, 1.38), radius=0.07, material=mat_skin)
    up_r = add_part('cylinder', (0.22, 0, 1.25), radius=0.055, depth=0.22, material=mat_skin, bevel=0.01)
    el_r = add_part('sphere', (0.22, 0, 1.14), radius=0.05, material=mat_skin)
    fo_r = add_part('cylinder', (0.23, 0.02, 1.04), radius=0.048, depth=0.18, material=mat_skin, bevel=0.01)
    cuff_r = add_part('cylinder', (0.23, 0.03, 0.94), radius=0.055, depth=0.05, material=mat_straps, bevel=0.005)
    hand_r = add_part('cube', (0.23, 0.04, 0.88), scale=(0.07, 0.08, 0.09), material=mat_gloves, bevel=0.015)
    knuckles_r = add_part('cube', (0.23, 0.05, 0.86), scale=(0.065, 0.025, 0.035), material=mat_comms, bevel=0.003)
    thumb_r = add_part('cone', (0.20, 0.06, 0.89), radius=0.018, depth=0.05, rotation=(0.5, -0.5, 0), material=mat_gloves, bevel=0.003)
    arm_r_parts.extend([sh_r, up_r, el_r, fo_r, cuff_r, hand_r, knuckles_r, thumb_r])
    arm_r_obj = join_objects_and_set_origin(arm_r_parts, "Arm_R", (0.22, 0, 1.38))

    # 5. LEFT LEG - Pivot at hip (-0.12, 0, 0.90)
    leg_l_parts = []
    short_l = add_part('cylinder', (-0.12, 0, 0.84), radius=0.095, depth=0.14, material=mat_shorts, bevel=0.012)
    pocket_l = add_part('cube', (-0.20, 0, 0.86), scale=(0.04, 0.10, 0.09), material=mat_shorts, bevel=0.008)
    thigh_l = add_part('cylinder', (-0.12, 0, 0.70), radius=0.075, depth=0.20, material=mat_skin, bevel=0.015)
    knee_l = add_part('sphere', (-0.12, 0.01, 0.58), radius=0.065, material=mat_skin)
    knee_pad_l = add_part('cube', (-0.12, 0.05, 0.58), scale=(0.10, 0.04, 0.09), material=mat_straps, bevel=0.008)
    calf_l = add_part('cylinder', (-0.12, 0, 0.44), radius=0.065, depth=0.22, material=mat_skin, bevel=0.012)
    boot_sh_l = add_part('cylinder', (-0.12, 0, 0.25), radius=0.08, depth=0.20, material=mat_boots, bevel=0.015)
    boot_laces_l = add_part('cube', (-0.12, 0.06, 0.25), scale=(0.04, 0.025, 0.16), material=mat_buckle, bevel=0.003)
    boot_ft_l = add_part('cube', (-0.12, 0.05, 0.10), scale=(0.14, 0.22, 0.12), material=mat_boots, bevel=0.02)
    boot_sole_l = add_part('cube', (-0.12, 0.05, 0.025), scale=(0.16, 0.25, 0.05), material=mat_belt, bevel=0.008)
    boot_treads_l = add_part('cube', (-0.12, 0.05, 0.015), scale=(0.17, 0.26, 0.03), material=mat_belt, bevel=0.004)
    leg_l_parts.extend([short_l, pocket_l, thigh_l, knee_l, knee_pad_l, calf_l, boot_sh_l, boot_laces_l, boot_ft_l, boot_sole_l, boot_treads_l])
    leg_l_obj = join_objects_and_set_origin(leg_l_parts, "Leg_L", (-0.12, 0, 0.90))

    # 6. RIGHT LEG - Pivot at hip (0.12, 0, 0.90)
    leg_r_parts = []
    short_r = add_part('cylinder', (0.12, 0, 0.84), radius=0.095, depth=0.14, material=mat_shorts, bevel=0.012)
    pocket_r = add_part('cube', (0.20, 0, 0.86), scale=(0.04, 0.10, 0.09), material=mat_shorts, bevel=0.008)
    thigh_r = add_part('cylinder', (0.12, 0, 0.70), radius=0.075, depth=0.20, material=mat_skin, bevel=0.015)
    knee_r = add_part('sphere', (0.12, 0.01, 0.58), radius=0.065, material=mat_skin)
    knee_pad_r = add_part('cube', (0.12, 0.05, 0.58), scale=(0.10, 0.04, 0.09), material=mat_straps, bevel=0.008)
    calf_r = add_part('cylinder', (0.12, 0, 0.44), radius=0.065, depth=0.22, material=mat_skin, bevel=0.012)
    boot_sh_r = add_part('cylinder', (0.12, 0, 0.25), radius=0.08, depth=0.20, material=mat_boots, bevel=0.015)
    boot_laces_r = add_part('cube', (0.12, 0.06, 0.25), scale=(0.04, 0.025, 0.16), material=mat_buckle, bevel=0.003)
    boot_ft_r = add_part('cube', (0.12, 0.05, 0.10), scale=(0.14, 0.22, 0.12), material=mat_boots, bevel=0.02)
    boot_sole_r = add_part('cube', (0.12, 0.05, 0.025), scale=(0.16, 0.25, 0.05), material=mat_belt, bevel=0.008)
    boot_treads_r = add_part('cube', (0.12, 0.05, 0.015), scale=(0.17, 0.26, 0.03), material=mat_belt, bevel=0.004)
    leg_r_parts.extend([short_r, pocket_r, thigh_r, knee_r, knee_pad_r, calf_r, boot_sh_r, boot_laces_r, boot_ft_r, boot_sole_r, boot_treads_r])
    leg_r_obj = join_objects_and_set_origin(leg_r_parts, "Leg_R", (0.12, 0, 0.90))

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "roxy_vance.glb"))




# ==============================================================================
# 11. Handheld EMP Stun Discharger Tool (Roxy's Active Defense Tool)
# ==============================================================================
def generate_emp_device():
    reset_scene()
    mat_casing = create_pbr_material("EMPCasing", base_color=(0.18, 0.19, 0.22, 1.0), roughness=0.6, metallic=0.7)
    mat_gold_ring = create_pbr_material("EMPGold", base_color=(0.85, 0.72, 0.22, 1.0), roughness=0.3, metallic=0.9)
    mat_core_pulse = create_emissive_material("EMPCoil", emissive_color=(0.2, 0.7, 1.0, 1.0), strength=2.5, base_color=(0.05, 0.2, 0.4, 1.0))

    # Main grip handle
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.32, location=(0, 0, 0.16))
    handle = bpy.context.active_object
    smart_unwrap_object(handle)
    handle.data.materials.append(mat_casing)

    # Capacitor rings
    rings = []
    for rz in [0.22, 0.28]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.08, minor_radius=0.015, location=(0, 0, rz))
        r = bpy.context.active_object
        smart_unwrap_object(r)
        r.data.materials.append(mat_gold_ring)
        rings.append(r)

    # Core emitter bulb
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    emitter = bpy.context.active_object
    emitter.scale = (0.09, 0.09, 0.08)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smart_unwrap_object(emitter)
    emitter.data.materials.append(mat_core_pulse)

    all_objs = [handle, emitter] + rings
    bpy.ops.object.select_all(action='DESELECT')
    for obj in all_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = handle
    bpy.ops.object.join()
    handle.name = "EMPDevice"

    export_glb(os.path.join(OUTPUT_MODELS_DIR, "emp_device.glb"))

# ==============================================================================
# 12. Broken Server Rack (Exposed Motherboards, Smashed Door, Spark Emitter)
# ==============================================================================
def generate_broken_server_rack():
    reset_scene()
    mat_frame = create_textured_material("BrokenRackFrame", "rusted_metal.jpg", roughness=0.8, metallic=0.7)
    mat_guts = create_textured_material("BrokenRackGuts", "server_labyrinth.jpg", roughness=0.6, metallic=0.4)
    mat_spark_core = create_emissive_material("SparkCore", emissive_color=(0.4, 0.8, 1.0, 1.0), strength=4.0, base_color=(0.1, 0.3, 0.5, 1.0))
    mat_amber_warn = create_emissive_material("AmberFault", emissive_color=(1.0, 0.45, 0.05, 1.0), strength=2.8, base_color=(0.3, 0.1, 0.0, 1.0))
    mat_wire = create_pbr_material("ExposedWire", base_color=(0.08, 0.08, 0.09, 1.0), roughness=0.8, metallic=0.2)
    mat_copper = create_pbr_material("CopperBus", base_color=(0.85, 0.45, 0.22, 1.0), roughness=0.3, metallic=0.9)

    parts = []
    # Main outer cabinet (2.4m high, 1.0m wide, 0.9m deep) with bent frame
    cabinet = add_part('cube', (0, 0, 1.2), scale=(1.0, 0.9, 2.4), material=mat_frame, bevel=0.03)
    parts.append(cabinet)

    # Broken/ajar front door hanging askew at an angle
    door = add_part('cube', (0.42, 0.52, 1.15), scale=(0.95, 0.06, 2.2), rotation=(0.12, -0.25, 0.45), material=mat_frame, bevel=0.02)
    parts.append(door)

    # Exposed interior chassis cavity
    for z in [0.5, 0.9, 1.3, 1.7, 2.0]:
        shelf = add_part('cube', (0, 0.05, z), scale=(0.88, 0.75, 0.04), material=mat_frame, bevel=0.01)
        parts.append(shelf)

    # Pulled-out and askew server blades
    blade1 = add_part('cube', (0, 0.22, 0.7), scale=(0.84, 0.65, 0.14), rotation=(0, 0.08, -0.1), material=mat_guts, bevel=0.01)
    blade2 = add_part('cube', (0, 0.35, 1.1), scale=(0.84, 0.65, 0.14), rotation=(0.06, -0.12, 0.18), material=mat_guts, bevel=0.01)
    blade3 = add_part('cube', (0, 0.15, 1.5), scale=(0.84, 0.65, 0.14), material=mat_guts, bevel=0.01)
    parts.extend([blade1, blade2, blade3])

    # Blown capacitor bank and spark gap
    cap1 = add_part('cylinder', (-0.15, 0.18, 0.9), radius=0.045, depth=0.12, material=mat_copper, bevel=0.005)
    cap2 = add_part('cylinder', (0.15, 0.18, 0.9), radius=0.045, depth=0.12, material=mat_copper, bevel=0.005)
    spark_emitter = add_part('sphere', (0, 0.25, 0.9), radius=0.035, material=mat_spark_core)
    fault_led = add_part('cube', (-0.32, 0.38, 1.55), scale=(0.04, 0.02, 0.04), material=mat_amber_warn)
    fault_led2 = add_part('cube', (0.32, 0.38, 1.55), scale=(0.04, 0.02, 0.04), material=mat_amber_warn)
    parts.extend([cap1, cap2, spark_emitter, fault_led, fault_led2])

    # Dangling severed cables
    for cx in [-0.25, -0.1, 0.1, 0.25]:
        cable = add_part('cylinder', (cx, 0.38, 0.6), radius=0.018, depth=0.5, rotation=(0.35, cx * 0.5, 0), material=mat_wire, bevel=0.005)
        parts.append(cable)

    root = join_objects_and_set_origin(parts, "BrokenServerRack", (0, 0, 0))
    export_glb(os.path.join(OUTPUT_MODELS_DIR, "broken_server_rack.glb"))

# ==============================================================================
# 13. Sparking Wall-Mounted Fuse Box (Arc Gap, Danger Sign, Dangling Wires)
# ==============================================================================
def generate_sparking_fuse_box():
    reset_scene()
    mat_box = create_pbr_material("FuseBoxSteel", base_color=(0.20, 0.22, 0.24, 1.0), roughness=0.6, metallic=0.8)
    mat_hazard = create_pbr_material("HazardStripe", base_color=(0.85, 0.68, 0.15, 1.0), roughness=0.5, metallic=0.2)
    mat_spark = create_emissive_material("SparkPoint", emissive_color=(1.0, 0.95, 0.7, 1.0), strength=5.0, base_color=(0.8, 0.6, 0.1, 1.0))
    mat_copper = create_pbr_material("FuseCopper", base_color=(0.9, 0.5, 0.2, 1.0), roughness=0.25, metallic=0.95)
    mat_wire_red = create_pbr_material("WireRed", base_color=(0.75, 0.12, 0.10, 1.0), roughness=0.7, metallic=0.1)
    mat_wire_black = create_pbr_material("WireBlack", base_color=(0.08, 0.08, 0.09, 1.0), roughness=0.8, metallic=0.1)

    parts = []
    # Main wall-mounted housing (0.7m wide, 0.32m deep, 0.9m high)
    box = add_part('cube', (0, 0, 0.45), scale=(0.7, 0.32, 0.9), material=mat_box, bevel=0.02)
    parts.append(box)

    # Open hinged door swung out 80 degrees
    door = add_part('cube', (0.34, 0.26, 0.45), scale=(0.65, 0.04, 0.88), rotation=(0, 0, 1.25), material=mat_hazard, bevel=0.015)
    parts.append(door)

    # Internal bus bar and 3 ceramic heavy fuses
    bus = add_part('cube', (0, 0.04, 0.45), scale=(0.55, 0.03, 0.75), material=mat_box, bevel=0.01)
    parts.append(bus)
    for fx in [-0.18, 0.0, 0.18]:
        fuse = add_part('cylinder', (fx, 0.08, 0.45), radius=0.035, depth=0.35, material=mat_copper, bevel=0.008)
        parts.append(fuse)

    # Blown arc contact
    arc_contact = add_part('sphere', (0.0, 0.12, 0.62), radius=0.03, material=mat_spark)
    parts.append(arc_contact)

    # Dangling torn cables
    c1 = add_part('cylinder', (-0.12, 0.18, 0.15), radius=0.016, depth=0.45, rotation=(0.5, 0.3, 0), material=mat_wire_red, bevel=0.004)
    c2 = add_part('cylinder', (0.10, 0.20, 0.10), radius=0.016, depth=0.55, rotation=(0.4, -0.4, 0), material=mat_wire_black, bevel=0.004)
    parts.extend([c1, c2])

    root = join_objects_and_set_origin(parts, "SparkingFuseBox", (0, 0, 0))
    export_glb(os.path.join(OUTPUT_MODELS_DIR, "sparking_fuse_box.glb"))

# ==============================================================================
# 14. Floor Power Inverter with Glowing Vacuum Tubes
# ==============================================================================
def generate_power_inverter():
    reset_scene()
    mat_chassis = create_textured_material("InverterChassis", "rusted_metal.jpg", roughness=0.7, metallic=0.75)
    mat_vent = create_pbr_material("InverterVent", base_color=(0.10, 0.11, 0.12, 1.0), roughness=0.5, metallic=0.8)
    mat_tube_glass = create_pbr_material("TubeGlass", base_color=(0.8, 0.85, 0.9, 0.4), roughness=0.1, metallic=0.1)
    mat_filament = create_emissive_material("TubeFilament", emissive_color=(1.0, 0.42, 0.05, 1.0), strength=3.5, base_color=(0.5, 0.15, 0.0, 1.0))
    mat_copper = create_pbr_material("InverterCopper", base_color=(0.85, 0.45, 0.2, 1.0), roughness=0.3, metallic=0.9)

    parts = []
    # Base floor enclosure (1.1m wide, 0.8m deep, 0.55m high)
    base = add_part('cube', (0, 0, 0.275), scale=(1.1, 0.8, 0.55), material=mat_chassis, bevel=0.02)
    vent = add_part('cube', (0, 0.38, 0.3), scale=(0.9, 0.06, 0.35), material=mat_vent, bevel=0.01)
    parts.extend([base, vent])

    # 4 Glowing vacuum tubes / high-voltage valves standing on top
    for tx in [-0.32, -0.11, 0.11, 0.32]:
        socket = add_part('cylinder', (tx, 0, 0.58), radius=0.08, depth=0.06, material=mat_copper, bevel=0.005)
        glass = add_part('cylinder', (tx, 0, 0.76), radius=0.065, depth=0.32, material=mat_tube_glass, bevel=0.02)
        filament = add_part('cylinder', (tx, 0, 0.76), radius=0.02, depth=0.22, material=mat_filament, bevel=0.005)
        parts.extend([socket, glass, filament])

    root = join_objects_and_set_origin(parts, "PowerInverter", (0, 0, 0))
    export_glb(os.path.join(OUTPUT_MODELS_DIR, "power_inverter.glb"))

def main():
    print("=== Sub-Routine Production Blender Pipeline Starting ===")
    generate_glitch_walker()
    generate_roxy_vance()
    generate_server_corridor()
    generate_server_rack()
    generate_crt_terminal()
    generate_mainframe_bank()
    generate_cable_nest()
    generate_coolant_pipe_junction()
    generate_blast_door()
    generate_memory_core_pickup()
    generate_emp_device()
    generate_broken_server_rack()
    generate_sparking_fuse_box()
    generate_power_inverter()
    print("=== Sub-Routine Production Blender Pipeline Finished (14 Models Exported) ===")

if __name__ == "__main__":
    main()
