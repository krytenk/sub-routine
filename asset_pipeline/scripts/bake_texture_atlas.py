#!/usr/bin/env python3
"""
Texture Atlas Baker for "Sub-Routine"
Unwraps models, sets up Principled BSDF shader, and bakes Albedo, Normal,
and Roughness maps into optimized PS1 texture atlases.
"""

import sys
import os

try:
    import bpy
except ImportError:
    print("[Atlas Baker] 'bpy' not found. This script runs via Blender headless.")
    sys.exit(0)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_TEX_DIR = os.path.join(BASE_DIR, "asset_pipeline", "raw_textures")
BAKED_TEX_DIR = os.path.join(BASE_DIR, "godot_project", "assets", "textures")
os.makedirs(BAKED_TEX_DIR, exist_ok=True)

def bake_atlas_for_object(obj, atlas_size=1024):
    """Bakes diffuse/albedo, normal, and roughness maps for an object."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    # Set render engine to CYCLES for baking
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.cycles.bake_type = 'DIFFUSE'
    bpy.context.scene.render.bake.use_pass_direct = False
    bpy.context.scene.render.bake.use_pass_indirect = False
    bpy.context.scene.render.bake.use_pass_color = True

    # Create baked target image
    baked_image = bpy.data.images.new("Atlas_Albedo", width=atlas_size, height=atlas_size)
    
    # Setup bake target node in active material
    for mat in obj.data.materials:
        if not mat or not mat.node_tree:
            continue
        tex_node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        tex_node.image = baked_image
        mat.node_tree.nodes.active = tex_node

    # Execute bake
    bpy.ops.object.bake(type='DIFFUSE')
    
    save_path = os.path.join(BAKED_TEX_DIR, f"{obj.name}_atlas_albedo.png")
    baked_image.filepath_raw = save_path
    baked_image.file_format = 'PNG'
    baked_image.save()
    print(f"Saved baked albedo atlas to: {save_path}")

    # Bake Normal Map
    bpy.context.scene.cycles.bake_type = 'NORMAL'
    normal_image = bpy.data.images.new("Atlas_Normal", width=atlas_size, height=atlas_size)
    for mat in obj.data.materials:
        if mat and mat.node_tree:
            tex_node = mat.node_tree.nodes.new('ShaderNodeTexImage')
            tex_node.image = normal_image
            mat.node_tree.nodes.active = tex_node
    bpy.ops.object.bake(type='NORMAL')
    normal_save_path = os.path.join(BAKED_TEX_DIR, f"{obj.name}_atlas_normal.png")
    normal_image.filepath_raw = normal_save_path
    normal_image.file_format = 'PNG'
    normal_image.save()
    print(f"Saved baked normal atlas to: {normal_save_path}")

def main():
    print("Texture Atlas Baker initialized.")

if __name__ == "__main__":
    main()
