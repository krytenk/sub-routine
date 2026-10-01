#!/usr/bin/env python3
"""
Headless Blender Script: Generates Survival Horror Personnel Remains (Casualties),
Industrial Auxiliary Generator, and Generator Repair Components.
PS1-era low-poly survival horror aesthetic matching Roxy Vale / Sub-Routine.
"""

import sys
import os
import math
import random

try:
    import bpy
    import mathutils
except ImportError:
    print("Run this script via: /home/chriswinters/bin/blender -b -P <script>")
    sys.exit(0)

BASE_DIR = "/home/chriswinters/Roxy Vale"
MODELS_DIR = os.path.join(BASE_DIR, "godot_project", "assets", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_mat(name, base_color=(0.2, 0.2, 0.2, 1.0), roughness=0.8, metallic=0.1):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = base_color
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    mat.node_tree.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return mat

def create_emissive_mat(name, color=(0.1, 0.9, 0.3, 1.0), strength=2.5):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    out = nodes.new(type='ShaderNodeOutputMaterial')
    bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = (color[0]*0.2, color[1]*0.2, color[2]*0.2, 1.0)
    bsdf.inputs['Emission Color'].default_value = color
    bsdf.inputs['Emission Strength'].default_value = strength
    mat.node_tree.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return mat

def export_glb(filepath):
    bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_yup=True
    )
    print(f"[Blender Export] Saved GLB to: {filepath}")

# ==============================================================================
# MODEL 1: Casualty Slumped Against Wall (Ragged Hazmat Technician)
# ==============================================================================
def generate_casualty_slumped_wall():
    reset_scene()
    
    mat_suit = create_pbr_mat("Mat_TornSuit", base_color=(0.18, 0.24, 0.28, 1.0), roughness=0.9, metallic=0.05) # faded navy jumpsuit
    mat_undersuit = create_pbr_mat("Mat_Undersuit", base_color=(0.08, 0.08, 0.08, 1.0), roughness=0.95, metallic=0.0) # torn dark inner cloth
    mat_skin = create_pbr_mat("Mat_PaleSkin", base_color=(0.38, 0.36, 0.34, 1.0), roughness=0.7, metallic=0.0) # desaturated/cyanotic pale skin
    mat_boots = create_pbr_mat("Mat_HeavyBoots", base_color=(0.12, 0.10, 0.09, 1.0), roughness=0.85, metallic=0.15)
    mat_badge = create_emissive_mat("Mat_FlickerBadge", color=(0.2, 0.6, 1.0, 1.0), strength=1.2) # cyan flickering ID badge
    mat_cable = create_pbr_mat("Mat_EnsnaringCable", base_color=(0.05, 0.05, 0.05, 1.0), roughness=0.6, metallic=0.2)
    
    # Pelvis on ground (slumped against back wall at Z=0.25)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.15, 0.12))
    pelvis = bpy.context.active_object
    pelvis.scale = (0.22, 0.18, 0.14)
    pelvis.data.materials.append(mat_suit)
    
    # Torso angled back against wall (tilted ~25 degrees back)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.48, 0.18))
    torso = bpy.context.active_object
    torso.scale = (0.26, 0.28, 0.16)
    torso.rotation_euler = (math.radians(-22), 0.0, math.radians(4))
    torso.data.materials.append(mat_suit)
    
    # Torn chest tear exposing inner dark fabric/frame
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.04, 0.52, 0.26))
    tear = bpy.context.active_object
    tear.scale = (0.10, 0.12, 0.03)
    tear.rotation_euler = (math.radians(-22), 0.0, math.radians(15))
    tear.data.materials.append(mat_undersuit)
    
    # Slumped Head (tilted heavily downward and sideways onto chest)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.14, location=(0.02, 0.72, 0.28))
    head = bpy.context.active_object
    head.scale = (0.9, 1.05, 0.95)
    head.rotation_euler = (math.radians(35), math.radians(-18), math.radians(12))
    head.data.materials.append(mat_suit) # hooded / helmet collar
    
    # Face aperture / mask rim
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.04, location=(0.03, 0.69, 0.38))
    mask = bpy.context.active_object
    mask.rotation_euler = (math.radians(35), math.radians(-18), 0.0)
    mask.data.materials.append(mat_undersuit)
    
    # Left Leg (splayed forward-left along floor)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.16, 0.12, 0.45))
    leg_l = bpy.context.active_object
    leg_l.scale = (0.10, 0.10, 0.36)
    leg_l.rotation_euler = (math.radians(12), math.radians(-16), 0.0)
    leg_l.data.materials.append(mat_suit)
    
    # Left Boot
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.24, 0.10, 0.78))
    boot_l = bpy.context.active_object
    boot_l.scale = (0.11, 0.12, 0.18)
    boot_l.rotation_euler = (0.0, math.radians(-25), 0.0)
    boot_l.data.materials.append(mat_boots)
    
    # Right Leg (knee bent upward, foot near pelvis)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.18, 0.28, 0.32))
    thigh_r = bpy.context.active_object
    thigh_r.scale = (0.10, 0.22, 0.12)
    thigh_r.rotation_euler = (math.radians(-35), math.radians(10), 0.0)
    thigh_r.data.materials.append(mat_suit)
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.20, 0.14, 0.52))
    shin_r = bpy.context.active_object
    shin_r.scale = (0.09, 0.18, 0.09)
    shin_r.rotation_euler = (math.radians(45), math.radians(8), 0.0)
    shin_r.data.materials.append(mat_suit)
    
    # Right Boot
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.22, 0.08, 0.65))
    boot_r = bpy.context.active_object
    boot_r.scale = (0.11, 0.10, 0.16)
    boot_r.data.materials.append(mat_boots)
    
    # Left Arm (slumped limply along ground at side)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.26, 0.30, 0.22))
    arm_l = bpy.context.active_object
    arm_l.scale = (0.08, 0.28, 0.08)
    arm_l.rotation_euler = (math.radians(15), 0.0, math.radians(-15))
    arm_l.data.materials.append(mat_suit)
    
    # Left limp hand with digital badge held near fingertips
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.30, 0.05, 0.38))
    hand_l = bpy.context.active_object
    hand_l.scale = (0.05, 0.04, 0.09)
    hand_l.data.materials.append(mat_skin)
    
    # Dropped Security Keycard / ID Badge emitting dim LED pulse
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.35, 0.02, 0.44))
    badge = bpy.context.active_object
    badge.scale = (0.07, 0.01, 0.10)
    badge.rotation_euler = (0.0, math.radians(28), 0.0)
    badge.data.materials.append(mat_badge)
    
    # Right Upper Arm (torn off at elbow! Ragged cloth fringe)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.24, 0.38, 0.20))
    arm_r_stump = bpy.context.active_object
    arm_r_stump.scale = (0.08, 0.15, 0.08)
    arm_r_stump.rotation_euler = (math.radians(10), 0.0, math.radians(15))
    arm_r_stump.data.materials.append(mat_suit)
    
    # Severed Forearm + Hand lying separately ~0.45m away on the floor
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.52, 0.04, 0.35))
    severed_arm = bpy.context.active_object
    severed_arm.scale = (0.06, 0.05, 0.22)
    severed_arm.rotation_euler = (0.0, math.radians(55), 0.0)
    severed_arm.data.materials.append(mat_suit)
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.66, 0.03, 0.44))
    severed_hand = bpy.context.active_object
    severed_hand.scale = (0.05, 0.03, 0.08)
    severed_hand.rotation_euler = (0.0, math.radians(70), 0.0)
    severed_hand.data.materials.append(mat_skin)
    
    # Facility cables coiled across lower legs (environmental hazard/trapped suggestion)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.025, depth=0.9, location=(0.0, 0.04, 0.55))
    cable = bpy.context.active_object
    cable.rotation_euler = (0.0, math.radians(82), math.radians(85))
    cable.data.materials.append(mat_cable)

    # Join and export
    export_glb(os.path.join(MODELS_DIR, "casualty_slumped_wall.glb"))

# ==============================================================================
# MODEL 2: Casualty Corner Curled (Desperate Corner Demise)
# ==============================================================================
def generate_casualty_corner_curled():
    reset_scene()
    
    mat_suit = create_pbr_mat("Mat_TornOrangeSuit", base_color=(0.32, 0.16, 0.08, 1.0), roughness=0.9, metallic=0.05) # faded amber hazard suit
    mat_undersuit = create_pbr_mat("Mat_InnerMesh", base_color=(0.06, 0.06, 0.07, 1.0), roughness=0.95, metallic=0.0)
    mat_boots = create_pbr_mat("Mat_ScuffedBoots", base_color=(0.10, 0.10, 0.10, 1.0), roughness=0.8, metallic=0.2)
    mat_datapad = create_emissive_mat("Mat_CrackedDatapad", color=(0.9, 0.3, 0.1, 1.0), strength=1.5) # amber cracked screen
    
    # Curled torso in fetal posture
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.12, 0.22, -0.10))
    torso = bpy.context.active_object
    torso.scale = (0.24, 0.26, 0.20)
    torso.rotation_euler = (math.radians(-35), math.radians(25), math.radians(40))
    torso.data.materials.append(mat_suit)
    
    # Head buried into knees/arms
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.13, location=(-0.10, 0.38, 0.04))
    head = bpy.context.active_object
    head.scale = (0.9, 1.0, 0.95)
    head.rotation_euler = (math.radians(-50), math.radians(20), 0.0)
    head.data.materials.append(mat_suit)
    
    # Pulled up legs
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.08, 0.18, -0.05))
    legs = bpy.context.active_object
    legs.scale = (0.18, 0.20, 0.28)
    legs.rotation_euler = (math.radians(25), math.radians(-30), 0.0)
    legs.data.materials.append(mat_suit)
    
    # Single boot attached
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.18, 0.10, 0.12))
    boot1 = bpy.context.active_object
    boot1.scale = (0.10, 0.10, 0.16)
    boot1.data.materials.append(mat_boots)
    
    # Separated detached boot + torn pant cuff 0.5m away in the corner
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.45, 0.08, 0.30))
    boot_detached = bpy.context.active_object
    boot_detached.scale = (0.10, 0.10, 0.16)
    boot_detached.rotation_euler = (math.radians(80), 0.0, math.radians(45))
    boot_detached.data.materials.append(mat_boots)
    
    # Dropped diagnostic datapad with cracked amber screen
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.25, 0.03, -0.22))
    datapad = bpy.context.active_object
    datapad.scale = (0.14, 0.02, 0.18)
    datapad.rotation_euler = (0.0, math.radians(-32), 0.0)
    datapad.data.materials.append(mat_datapad)
    
    export_glb(os.path.join(MODELS_DIR, "casualty_corner_curled.glb"))

# ==============================================================================
# MODEL 3: Industrial Subterranean Generator (Multi-Part Machine)
# ==============================================================================
def generate_subterranean_generator():
    reset_scene()
    
    mat_metal = create_pbr_mat("Mat_GenChassis", base_color=(0.16, 0.18, 0.20, 1.0), roughness=0.65, metallic=0.75)
    mat_hazard = create_pbr_mat("Mat_GenHazard", base_color=(0.45, 0.38, 0.10, 1.0), roughness=0.8, metallic=0.1) # industrial yellow/black stripes
    mat_copper = create_pbr_mat("Mat_GenCopper", base_color=(0.65, 0.32, 0.15, 1.0), roughness=0.4, metallic=0.85)
    mat_gauge = create_emissive_mat("Mat_GenStatusOffline", color=(0.9, 0.15, 0.1, 1.0), strength=2.0) # red offline warning light
    mat_socket_empty = create_pbr_mat("Mat_SocketEmpty", base_color=(0.04, 0.04, 0.05, 1.0), roughness=0.9, metallic=0.2)
    
    # Heavy base plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.20, 0.0))
    plinth = bpy.context.active_object
    plinth.scale = (1.8, 0.40, 1.4)
    plinth.data.materials.append(mat_metal)
    
    # Central cylindrical turbine / dynamo housing
    bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=1.6, location=(0.0, 0.95, -0.10))
    turbine = bpy.context.active_object
    turbine.rotation_euler = (0.0, 0.0, math.radians(90))
    turbine.data.materials.append(mat_metal)
    
    # Copper cooling fins / stator rings
    for x_offset in [-0.55, -0.20, 0.20, 0.55]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.72, depth=0.12, location=(x_offset, 0.95, -0.10))
        stator = bpy.context.active_object
        stator.rotation_euler = (0.0, 0.0, math.radians(90))
        stator.data.materials.append(mat_copper)
        
    # High-voltage control console face (front side Z=0.55)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 1.05, 0.55))
    console = bpy.context.active_object
    console.scale = (1.4, 0.70, 0.25)
    console.data.materials.append(mat_hazard)
    
    # 3x Component Receptacle Sockets (Relay, Coolant Cell, Fuse Link)
    socket_x_coords = [-0.42, 0.0, 0.42]
    for i, sx in enumerate(socket_x_coords):
        # Socket recess
        bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.15, location=(sx, 1.05, 0.68))
        sock = bpy.context.active_object
        sock.rotation_euler = (math.radians(90), 0.0, 0.0)
        sock.data.materials.append(mat_socket_empty)
        
        # Socket Status Indicator LED
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.035, location=(sx, 1.25, 0.68))
        led = bpy.context.active_object
        led.data.materials.append(mat_gauge)
        
    # Exhaust flue / top pressure manifold
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=0.8, location=(0.0, 1.90, -0.10))
    flue = bpy.context.active_object
    flue.data.materials.append(mat_metal)
    
    export_glb(os.path.join(MODELS_DIR, "subterranean_generator.glb"))

# ==============================================================================
# MODEL 4: Generator Repair Part 1 - Transformer Relay
# ==============================================================================
def generate_part_relay():
    reset_scene()
    mat_casing = create_pbr_mat("Mat_RelayCase", base_color=(0.15, 0.22, 0.18, 1.0), roughness=0.6, metallic=0.5)
    mat_copper = create_pbr_mat("Mat_RelayCoil", base_color=(0.75, 0.35, 0.12, 1.0), roughness=0.35, metallic=0.85)
    mat_glow = create_emissive_mat("Mat_RelayGlow", color=(0.2, 0.8, 1.0, 1.0), strength=2.2) # electric cyan
    
    # Core cylinder
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.22, location=(0.0, 0.11, 0.0))
    core = bpy.context.active_object
    core.data.materials.append(mat_casing)
    
    # Wrapped copper transformer coils
    bpy.ops.mesh.primitive_torus_add(major_radius=0.09, minor_radius=0.025, location=(0.0, 0.08, 0.0))
    coil1 = bpy.context.active_object
    coil1.data.materials.append(mat_copper)
    
    bpy.ops.mesh.primitive_torus_add(major_radius=0.09, minor_radius=0.025, location=(0.0, 0.14, 0.0))
    coil2 = bpy.context.active_object
    coil2.data.materials.append(mat_copper)
    
    # Contact prongs & spark indicator
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.23, 0.0))
    prong = bpy.context.active_object
    prong.scale = (0.04, 0.04, 0.04)
    prong.data.materials.append(mat_glow)
    
    export_glb(os.path.join(MODELS_DIR, "generator_part_relay.glb"))

# ==============================================================================
# MODEL 5: Generator Repair Part 2 - Coolant Compression Cell
# ==============================================================================
def generate_part_coolant():
    reset_scene()
    mat_case = create_pbr_mat("Mat_CoolantCase", base_color=(0.25, 0.26, 0.28, 1.0), roughness=0.5, metallic=0.7)
    mat_glass = create_emissive_mat("Mat_CoolantFluid", color=(0.1, 0.95, 0.45, 1.0), strength=2.0) # radioactive coolant green
    
    # Flask cylinder
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.24, location=(0.0, 0.12, 0.0))
    body = bpy.context.active_object
    body.data.materials.append(mat_glass)
    
    # Metal reinforcement end caps
    for y_pos in [0.02, 0.22]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.085, depth=0.04, location=(0.0, y_pos, 0.0))
        cap = bpy.context.active_object
        cap.data.materials.append(mat_case)
        
    export_glb(os.path.join(MODELS_DIR, "generator_part_coolant.glb"))

# ==============================================================================
# MODEL 6: Generator Repair Part 3 - Heavy Magnetic Fuse
# ==============================================================================
def generate_part_fuse():
    reset_scene()
    mat_ceramic = create_pbr_mat("Mat_FuseCeramic", base_color=(0.78, 0.76, 0.72, 1.0), roughness=0.8, metallic=0.05)
    mat_brass = create_pbr_mat("Mat_FuseBrass", base_color=(0.70, 0.55, 0.20, 1.0), roughness=0.3, metallic=0.9)
    mat_arc = create_emissive_mat("Mat_FuseArc", color=(1.0, 0.75, 0.2, 1.0), strength=2.5) # amber high voltage
    
    # Ceramic barrel
    bpy.ops.mesh.primitive_cylinder_add(radius=0.065, depth=0.20, location=(0.0, 0.10, 0.0))
    barrel = bpy.context.active_object
    barrel.data.materials.append(mat_ceramic)
    
    # Heavy brass blade terminals
    for y_pos in [0.01, 0.19]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, y_pos, 0.0))
        blade = bpy.context.active_object
        blade.scale = (0.03, 0.04, 0.10)
        blade.data.materials.append(mat_brass)
        
    # Central arc indicator window
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.04, location=(0.0, 0.10, 0.0))
    window = bpy.context.active_object
    window.data.materials.append(mat_arc)
    
    export_glb(os.path.join(MODELS_DIR, "generator_part_fuse.glb"))

if __name__ == "__main__":
    print("--- Generating Personnel Remains & Generator Assets ---")
    generate_casualty_slumped_wall()
    generate_casualty_corner_curled()
    generate_subterranean_generator()
    generate_part_relay()
    generate_part_coolant()
    generate_part_fuse()
    print("--- Finished Asset Generation ---")
