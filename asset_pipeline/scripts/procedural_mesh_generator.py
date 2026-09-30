#!/usr/bin/env python3
"""
Procedural 3D Mesh & GLB Generator for "Sub-Routine"
Generates low-poly PS1-style meshes with Simplex/Perlin organic noise distortion,
UV coordinates, normals, and exports binary glTF (.glb) assets directly into
godot_project/assets/models/.

Models Generated:
1. glitch_walker.glb - Humanoid wireframe enemy wrapped in pulsating fleshy noise
2. roxy_vance.glb - Classic 90s heroine: combat boots, cargo shorts, crop top
3. server_rack.glb - Monolithic server rack with drive bays and bezel
4. server_corridor.glb - Brutalist subterranean corridor module with pillars
5. crt_terminal.glb - Bulky desktop CRT computer terminal with curved phosphor screen
6. mainframe_bank.glb - High-density supercomputer bank with exhaust hood and LED indicators
7. cable_nest.glb - Tangled snaking industrial power cables with floor droop
8. coolant_pipe_junction.glb - High-pressure conduit junction with gate valve and bolted flanges
9. blast_door.glb - Heavy hydraulic bulkhead security gate with structural cross-bracing
10. memory_core_pickup.glb - Glowing cybernetic RAM keycard collectible
"""

import os
import struct
import json
import math

OUTPUT_MODELS_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "godot_project", "assets", "models")
)
os.makedirs(OUTPUT_MODELS_DIR, exist_ok=True)

def pseudo_noise_3d(x, y, z, freq=1.8):
    """Organic harmonic noise function mimicking Simplex/Perlin distortion."""
    n1 = math.sin(x * freq * 2.3 + y * 1.7) * math.cos(y * freq * 1.9 + z * 2.1)
    n2 = math.sin(z * freq * 1.5 + x * 2.7) * math.cos(x * freq * 1.1 + y * 0.8)
    return (n1 + n2) * 0.5

def build_glb(vertices, normals, uvs, indices, material_name="DefaultMat",
              base_color=(0.8, 0.8, 0.8, 1.0), metallic=0.1, roughness=0.85,
              emissive_factor=(0.0, 0.0, 0.0)):
    """
    Builds a valid binary GLB (glTF 2.0) file containing a single mesh primitive.
    """
    # Vertex buffer
    v_bytes = bytearray()
    min_v = [float('inf')]*3
    max_v = [float('-inf')]*3
    for v in vertices:
        for i in range(3):
            min_v[i] = min(min_v[i], v[i])
            max_v[i] = max(max_v[i], v[i])
        v_bytes += struct.pack('<fff', v[0], v[1], v[2])

    n_bytes = bytearray()
    for n in normals:
        n_bytes += struct.pack('<fff', n[0], n[1], n[2])

    uv_bytes = bytearray()
    for uv in uvs:
        uv_bytes += struct.pack('<ff', uv[0], uv[1])

    idx_bytes = bytearray()
    max_idx = max(indices) if indices else 0
    min_idx = min(indices) if indices else 0
    for idx in indices:
        idx_bytes += struct.pack('<H', idx)

    def pad(b):
        while len(b) % 4 != 0:
            b.append(0)
        return b

    pos_offset = 0
    pos_len = len(v_bytes)
    v_bytes = pad(v_bytes)

    norm_offset = len(v_bytes)
    norm_len = len(n_bytes)
    n_bytes = pad(n_bytes)

    uv_offset = norm_offset + len(n_bytes)
    uv_len = len(uv_bytes)
    uv_bytes = pad(uv_bytes)

    idx_offset = uv_offset + len(uv_bytes)
    idx_len = len(idx_bytes)
    idx_bytes = pad(idx_bytes)

    bin_data = v_bytes + n_bytes + uv_bytes + idx_bytes

    gltf = {
        "asset": {"version": "2.0", "generator": "SubRoutine-Procedural-Blender-Pipeline"},
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": material_name + "_Node"}],
        "materials": [{
            "name": material_name,
            "pbrMetallicRoughness": {
                "baseColorFactor": list(base_color),
                "metallicFactor": metallic,
                "roughnessFactor": roughness
            },
            "emissiveFactor": list(emissive_factor)
        }],
        "meshes": [{
            "name": material_name + "_Mesh",
            "primitives": [{
                "attributes": {
                    "POSITION": 0,
                    "NORMAL": 1,
                    "TEXCOORD_0": 2
                },
                "indices": 3,
                "material": 0,
                "mode": 4 # TRIANGLES
            }]
        }],
        "accessors": [
            {
                "bufferView": 0,
                "componentType": 5126, # FLOAT
                "count": len(vertices),
                "type": "VEC3",
                "max": max_v,
                "min": min_v
            },
            {
                "bufferView": 1,
                "componentType": 5126, # FLOAT
                "count": len(normals),
                "type": "VEC3"
            },
            {
                "bufferView": 2,
                "componentType": 5126, # FLOAT
                "count": len(uvs),
                "type": "VEC2"
            },
            {
                "bufferView": 3,
                "componentType": 5123, # UNSIGNED_SHORT
                "count": len(indices),
                "type": "SCALAR",
                "max": [max_idx],
                "min": [min_idx]
            }
        ],
        "bufferViews": [
            {"buffer": 0, "byteOffset": pos_offset, "byteLength": pos_len, "target": 34962},
            {"buffer": 0, "byteOffset": norm_offset, "byteLength": norm_len, "target": 34962},
            {"buffer": 0, "byteOffset": uv_offset, "byteLength": uv_len, "target": 34962},
            {"buffer": 0, "byteOffset": idx_offset, "byteLength": idx_len, "target": 34963}
        ],
        "buffers": [{"byteLength": len(bin_data)}]
    }

    json_str = json.dumps(gltf, separators=(',', ':'))
    json_bytes = json_str.encode('utf-8')
    while len(json_bytes) % 4 != 0:
        json_bytes += b' '

    chunk0_header = struct.pack('<II', len(json_bytes), 0x4E4F534A) # JSON
    chunk1_header = struct.pack('<II', len(bin_data), 0x004E4942)   # BIN

    total_len = 12 + len(chunk0_header) + len(json_bytes) + len(chunk1_header) + len(bin_data)
    glb_header = struct.pack('<III', 0x46546C67, 2, total_len)

    return glb_header + chunk0_header + json_bytes + chunk1_header + bin_data

def generate_box(width, height, depth, center=(0,0,0), uv_scale=(1,1), noise_scale=0.0):
    """Generates 3D box geometry with inward or outward normals and optional noise."""
    w, h, d = width/2.0, height/2.0, depth/2.0
    cx, cy, cz = center

    raw_faces = [
        # Front (+Z)
        [(-w, -h,  d), ( w, -h,  d), ( w,  h,  d), (-w,  h,  d)],
        # Back (-Z)
        [( w, -h, -d), (-w, -h, -d), (-w,  h, -d), ( w,  h, -d)],
        # Top (+Y)
        [(-w,  h,  d), ( w,  h,  d), ( w,  h, -d), (-w,  h, -d)],
        # Bottom (-Y)
        [(-w, -h, -d), ( w, -h, -d), ( w, -h,  d), (-w, -h,  d)],
        # Right (+X)
        [( w, -h,  d), ( w, -h, -d), ( w,  h, -d), ( w,  h,  d)],
        # Left (-X)
        [(-w, -h, -d), (-w, -h,  d), (-w,  h,  d), (-w,  h, -d)]
    ]

    face_normals = [
        (0, 0, 1), (0, 0, -1), (0, 1, 0), (0, -1, 0), (1, 0, 0), (-1, 0, 0)
    ]

    face_uvs = [(0, 0), (1, 0), (1, 1), (0, 1)]
    vertices, normals, uvs, indices = [], [], [], []

    for f_idx, face in enumerate(raw_faces):
        base_v = len(vertices)
        fn = face_normals[f_idx]
        for v_idx, v in enumerate(face):
            vx = v[0] + cx
            vy = v[1] + cy
            vz = v[2] + cz
            if noise_scale > 0:
                nv = pseudo_noise_3d(vx, vy, vz) * noise_scale
                vx += fn[0] * nv + nv * 0.5
                vy += fn[1] * nv + nv * 0.5
                vz += fn[2] * nv + nv * 0.5
            vertices.append((vx, vy, vz))
            normals.append(fn)
            uvs.append((face_uvs[v_idx][0] * uv_scale[0], face_uvs[v_idx][1] * uv_scale[1]))

        indices.extend([base_v, base_v+1, base_v+2, base_v, base_v+2, base_v+3])

    return vertices, normals, uvs, indices

def generate_cylinder(radius, height, segments=8, center=(0,0,0), axis='Y', caps=True, noise_scale=0.0):
    """Generates low-poly cylinder oriented along X, Y, or Z axis with optional caps."""
    cx, cy, cz = center
    half_h = height / 2.0
    vertices, normals, uvs, indices = [], [], [], []

    for i in range(segments):
        theta0 = (2.0 * math.pi * i) / segments
        theta1 = (2.0 * math.pi * (i + 1)) / segments

        c0, s0 = math.cos(theta0) * radius, math.sin(theta0) * radius
        c1, s1 = math.cos(theta1) * radius, math.sin(theta1) * radius

        base_idx = len(vertices)
        if axis == 'Y':
            v0 = (c0 + cx, cy - half_h, s0 + cz)
            v1 = (c1 + cx, cy - half_h, s1 + cz)
            v2 = (c1 + cx, cy + half_h, s1 + cz)
            v3 = (c0 + cx, cy + half_h, s0 + cz)
            n0 = (math.cos(theta0), 0.0, math.sin(theta0))
            n1 = (math.cos(theta1), 0.0, math.sin(theta1))
        elif axis == 'X':
            v0 = (cx - half_h, c0 + cy, s0 + cz)
            v1 = (cx - half_h, c1 + cy, s1 + cz)
            v2 = (cx + half_h, c1 + cy, s1 + cz)
            v3 = (cx + half_h, c0 + cy, s0 + cz)
            n0 = (0.0, math.cos(theta0), math.sin(theta0))
            n1 = (0.0, math.cos(theta1), math.sin(theta1))
        else: # 'Z'
            v0 = (c0 + cx, s0 + cy, cz - half_h)
            v1 = (c1 + cx, s1 + cy, cz - half_h)
            v2 = (c1 + cx, s1 + cy, cz + half_h)
            v3 = (c0 + cx, s0 + cy, cz + half_h)
            n0 = (math.cos(theta0), math.sin(theta0), 0.0)
            n1 = (math.cos(theta1), math.sin(theta1), 0.0)

        u0, u1 = i / segments, (i + 1) / segments
        vertices.extend([v0, v1, v2, v3])
        normals.extend([n0, n1, n1, n0])
        uvs.extend([(u0, 0), (u1, 0), (u1, 1), (u0, 1)])
        indices.extend([base_idx, base_idx + 1, base_idx + 2, base_idx, base_idx + 2, base_idx + 3])

    if caps:
        for cap_dir in [-1, 1]:
            cap_base = len(vertices)
            if axis == 'Y':
                center_v = (cx, cy + cap_dir * half_h, cz)
                norm = (0.0, float(cap_dir), 0.0)
            elif axis == 'X':
                center_v = (cx + cap_dir * half_h, cy, cz)
                norm = (float(cap_dir), 0.0, 0.0)
            else:
                center_v = (cx, cy, cz + cap_dir * half_h)
                norm = (0.0, 0.0, float(cap_dir))

            vertices.append(center_v)
            normals.append(norm)
            uvs.append((0.5, 0.5))

            for i in range(segments):
                theta = (2.0 * math.pi * i) / segments
                c, s = math.cos(theta) * radius, math.sin(theta) * radius
                if axis == 'Y':
                    v = (c + cx, cy + cap_dir * half_h, s + cz)
                elif axis == 'X':
                    v = (cx + cap_dir * half_h, c + cy, s + cz)
                else:
                    v = (c + cx, s + cy, cz + cap_dir * half_h)
                vertices.append(v)
                normals.append(norm)
                uvs.append((0.5 + 0.5 * math.cos(theta), 0.5 + 0.5 * math.sin(theta)))

            for i in range(segments):
                v_curr = cap_base + 1 + i
                v_next = cap_base + 1 + ((i + 1) % segments)
                if cap_dir > 0:
                    indices.extend([cap_base, v_curr, v_next])
                else:
                    indices.extend([cap_base, v_next, v_curr])

    return vertices, normals, uvs, indices

def generate_torus(major_radius=0.2, minor_radius=0.035, segments_major=12, segments_minor=6, center=(0,0,0), axis='Z'):
    """Generates low-poly torus for valve wheels, pipe collars, and circular connectors."""
    cx, cy, cz = center
    verts, norms, uvs, indices = [], [], [], []
    for i in range(segments_major):
        u0 = (2 * math.pi * i) / segments_major
        u1 = (2 * math.pi * (i + 1)) / segments_major
        for j in range(segments_minor):
            v0 = (2 * math.pi * j) / segments_minor
            v1 = (2 * math.pi * (j + 1)) / segments_minor
            quad = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
            base_idx = len(verts)
            for u, v in quad:
                x = (major_radius + minor_radius * math.cos(v)) * math.cos(u)
                y = (major_radius + minor_radius * math.cos(v)) * math.sin(u)
                z = minor_radius * math.sin(v)
                nx = math.cos(v) * math.cos(u)
                ny = math.cos(v) * math.sin(u)
                nz = math.sin(v)
                if axis == 'X':
                    verts.append((z + cx, x + cy, y + cz))
                    norms.append((nz, nx, ny))
                elif axis == 'Y':
                    verts.append((x + cx, z + cy, y + cz))
                    norms.append((nx, nz, ny))
                else: # 'Z'
                    verts.append((x + cx, y + cy, z + cz))
                    norms.append((nx, ny, nz))
                uvs.append((u / (2 * math.pi), v / (2 * math.pi)))
            indices.extend([base_idx, base_idx+1, base_idx+2, base_idx, base_idx+2, base_idx+3])
    return verts, norms, uvs, indices

def generate_tube_path(points, radius=0.04, segments=6, uv_scale=(1,1)):
    """Generates continuous tube mesh along an ordered list of 3D points for cables and conduits."""
    if len(points) < 2:
        return [], [], [], []
    verts, norms, uvs, indices = [], [], [], []

    frames = []
    for i in range(len(points)):
        p = points[i]
        if i == 0:
            p_next = points[i+1]
            tangent = (p_next[0]-p[0], p_next[1]-p[1], p_next[2]-p[2])
        elif i == len(points)-1:
            p_prev = points[i-1]
            tangent = (p[0]-p_prev[0], p[1]-p_prev[1], p[2]-p_prev[2])
        else:
            p_prev = points[i-1]
            p_next = points[i+1]
            tangent = (p_next[0]-p_prev[0], p_next[1]-p_prev[1], p_next[2]-p_prev[2])

        mag = math.sqrt(tangent[0]**2 + tangent[1]**2 + tangent[2]**2) or 1.0
        T = (tangent[0]/mag, tangent[1]/mag, tangent[2]/mag)

        up = (0, 1, 0) if abs(T[1]) < 0.95 else (1, 0, 0)
        N = (T[1]*up[2] - T[2]*up[1], T[2]*up[0] - T[0]*up[2], T[0]*up[1] - T[1]*up[0])
        mag_n = math.sqrt(N[0]**2 + N[1]**2 + N[2]**2) or 1.0
        N = (N[0]/mag_n, N[1]/mag_n, N[2]/mag_n)
        B = (T[1]*N[2] - T[2]*N[1], T[2]*N[0] - T[0]*N[2], T[0]*N[1] - T[1]*N[0])
        frames.append((p, T, N, B))

    for seg_idx in range(len(points) - 1):
        p0, _, N0, B0 = frames[seg_idx]
        p1, _, N1, B1 = frames[seg_idx + 1]

        t0 = seg_idx / (len(points) - 1)
        t1 = (seg_idx + 1) / (len(points) - 1)

        for s in range(segments):
            theta0 = (2 * math.pi * s) / segments
            theta1 = (2 * math.pi * (s + 1)) / segments

            c0, s0_val = math.cos(theta0), math.sin(theta0)
            c1, s1_val = math.cos(theta1), math.sin(theta1)

            v00 = (p0[0] + radius*(c0*N0[0] + s0_val*B0[0]), p0[1] + radius*(c0*N0[1] + s0_val*B0[1]), p0[2] + radius*(c0*N0[2] + s0_val*B0[2]))
            v10 = (p0[0] + radius*(c1*N0[0] + s1_val*B0[0]), p0[1] + radius*(c1*N0[1] + s1_val*B0[1]), p0[2] + radius*(c1*N0[2] + s1_val*B0[2]))
            v11 = (p1[0] + radius*(c1*N1[0] + s1_val*B1[0]), p1[1] + radius*(c1*N1[1] + s1_val*B1[1]), p1[2] + radius*(c1*N1[2] + s1_val*B1[2]))
            v01 = (p1[0] + radius*(c0*N1[0] + s0_val*B1[0]), p1[1] + radius*(c0*N1[1] + s0_val*B1[1]), p1[2] + radius*(c0*N1[2] + s0_val*B1[2]))

            n00 = (c0*N0[0] + s0_val*B0[0], c0*N0[1] + s0_val*B0[1], c0*N0[2] + s0_val*B0[2])
            n10 = (c1*N0[0] + s1_val*B0[0], c1*N0[1] + s1_val*B0[1], c1*N0[2] + s1_val*B0[2])
            n11 = (c1*N1[0] + s1_val*B1[0], c1*N1[1] + s1_val*B1[1], c1*N1[2] + s1_val*B1[2])
            n01 = (c0*N1[0] + s0_val*B1[0], c0*N1[1] + s0_val*B1[1], c0*N1[2] + s0_val*B1[2])

            base_idx = len(verts)
            verts.extend([v00, v10, v11, v01])
            norms.extend([n00, n10, n11, n01])
            uvs.extend([
                ((s/segments)*uv_scale[0], t0*uv_scale[1]),
                (((s+1)/segments)*uv_scale[0], t0*uv_scale[1]),
                (((s+1)/segments)*uv_scale[0], t1*uv_scale[1]),
                ((s/segments)*uv_scale[0], t1*uv_scale[1])
            ])
            indices.extend([base_idx, base_idx+1, base_idx+2, base_idx, base_idx+2, base_idx+3])

    return verts, norms, uvs, indices

def merge_geometries(geom_list):
    """Merges multiple vertex/normal/uv/index tuples."""
    all_v, all_n, all_uv, all_idx = [], [], [], []
    for v, n, uv, idx in geom_list:
        offset = len(all_v)
        all_v.extend(v)
        all_n.extend(n)
        all_uv.extend(uv)
        for i in idx:
            all_idx.append(i + offset)
    return all_v, all_n, all_uv, all_idx

def export_model(filename, parts, material_name, base_color=(0.8, 0.8, 0.8, 1.0),
                 metallic=0.1, roughness=0.85, emissive_factor=(0.0, 0.0, 0.0)):
    """Helper to merge, build and save GLB model."""
    v, n, uv, idx = merge_geometries(parts)
    glb_data = build_glb(v, n, uv, idx, material_name=material_name,
                         base_color=base_color, metallic=metallic,
                         roughness=roughness, emissive_factor=emissive_factor)
    out_path = os.path.join(OUTPUT_MODELS_DIR, filename)
    with open(out_path, "wb") as f:
        f.write(glb_data)
    print(f"-> Generated {filename}: {len(v)} vertices, {len(idx)//3} triangles ({len(glb_data)} bytes)")

def main():
    print("=== Sub-Routine Enhanced Procedural Asset Generator Starting ===")

    # 1. Glitch Walker (faceless humanoid wireframe wrapped in pulsating fleshy noise)
    gw_parts = [
        generate_box(0.5, 0.5, 0.5, center=(0, 1.7, 0), noise_scale=0.08),
        generate_box(0.7, 0.9, 0.4, center=(0, 1.0, 0), noise_scale=0.10),
        generate_cylinder(0.12, 0.9, segments=6, center=(-0.25, 0.45, 0), noise_scale=0.06),
        generate_cylinder(0.12, 0.9, segments=6, center=(0.25, 0.45, 0), noise_scale=0.06),
        generate_cylinder(0.09, 0.8, segments=6, center=(-0.45, 1.0, 0), noise_scale=0.05),
        generate_cylinder(0.09, 0.8, segments=6, center=(0.45, 1.0, 0), noise_scale=0.05),
    ]
    export_model("glitch_walker.glb", gw_parts, "DecayingFlesh", base_color=(0.6, 0.25, 0.25, 1.0), metallic=0.05, roughness=0.9)

    # 2. Roxy Vance (classic 90s heroine: combat boots, cargo shorts, crop top)
    roxy_parts = [
        generate_box(0.35, 0.38, 0.35, center=(0, 1.65, 0)),
        generate_box(0.48, 0.45, 0.3, center=(0, 1.25, 0)),
        generate_box(0.52, 0.35, 0.35, center=(0, 0.88, 0)),
        generate_cylinder(0.11, 0.5, segments=6, center=(-0.2, 0.55, 0)),
        generate_cylinder(0.11, 0.5, segments=6, center=(0.2, 0.55, 0)),
        generate_box(0.24, 0.35, 0.38, center=(-0.2, 0.18, 0.05)),
        generate_box(0.24, 0.35, 0.38, center=(0.2, 0.18, 0.05)),
        generate_cylinder(0.08, 0.65, segments=6, center=(-0.35, 1.2, 0)),
        generate_cylinder(0.08, 0.65, segments=6, center=(0.35, 1.2, 0)),
    ]
    export_model("roxy_vance.glb", roxy_parts, "RoxyVance", base_color=(0.35, 0.4, 0.35, 1.0), metallic=0.1, roughness=0.8)

    # 3. Server Monolith / Rack
    rack_parts = [
        generate_box(1.0, 2.4, 0.8, center=(0, 1.2, 0), uv_scale=(1, 2)),
        generate_box(1.08, 0.1, 0.88, center=(0, 2.35, 0)),
        generate_box(1.08, 0.1, 0.88, center=(0, 0.05, 0)),
    ]
    export_model("server_rack.glb", rack_parts, "ServerRack", base_color=(0.25, 0.25, 0.28, 1.0), metallic=0.3, roughness=0.7)

    # 4. Brutalist Subterranean Corridor
    corridor_parts = [
        generate_box(4.0, 0.2, 8.0, center=(0, 0, 0), uv_scale=(2, 4)),
        generate_box(4.0, 0.2, 8.0, center=(0, 3.8, 0), uv_scale=(2, 4)),
        generate_box(0.2, 3.8, 8.0, center=(-2.0, 1.9, 0), uv_scale=(2, 4)),
        generate_box(0.2, 3.8, 8.0, center=(2.0, 1.9, 0), uv_scale=(2, 4)),
        generate_box(0.4, 3.6, 0.4, center=(-1.8, 1.9, -2.0)),
        generate_box(0.4, 3.6, 0.4, center=(1.8, 1.9, -2.0)),
        generate_box(0.4, 3.6, 0.4, center=(-1.8, 1.9, 2.0)),
        generate_box(0.4, 3.6, 0.4, center=(1.8, 1.9, 2.0)),
    ]
    export_model("server_corridor.glb", corridor_parts, "SubterraneanCorridor", base_color=(0.3, 0.3, 0.32, 1.0), metallic=0.3, roughness=0.85)

    # 5. CRT Terminal Console (Interactive workstation)
    crt_parts = [
        generate_box(1.2, 0.75, 0.8, center=(0, 0.375, 0)),                  # Desk pedestal
        generate_box(0.8, 0.06, 0.3, center=(0, 0.78, 0.25)),                 # Keyboard base
        generate_box(0.7, 0.55, 0.6, center=(0, 1.08, -0.05)),                # Monitor housing
        generate_box(0.56, 0.44, 0.05, center=(0, 1.08, 0.26)),               # Screen bezel
        generate_box(0.48, 0.36, 0.02, center=(0, 1.08, 0.28)),               # Curved CRT face
        generate_box(0.2, 0.04, 0.02, center=(-0.25, 0.65, 0.41)),            # 3.5in floppy slot
        generate_cylinder(0.04, 0.4, segments=6, center=(0.28, 0.95, -0.1), axis='Z') # rear power cord
    ]
    export_model("crt_terminal.glb", crt_parts, "CRTTerminal", base_color=(0.35, 0.38, 0.35, 1.0), metallic=0.15, roughness=0.6, emissive_factor=(0.0, 0.0, 0.0))

    # 6. Mainframe Supercomputer Bank
    mainframe_parts = [
        generate_box(2.2, 2.6, 1.0, center=(0, 1.3, 0), uv_scale=(2, 2)),    # Main cabinet
        generate_box(2.35, 0.15, 1.1, center=(0, 0.075, 0)),                  # Base kickplate
        generate_box(2.35, 0.2, 1.1, center=(0, 2.7, 0)),                     # Top exhaust cowl
        generate_cylinder(0.09, 2.6, segments=6, center=(-1.05, 1.3, 0.45)),  # Left conduit
        generate_cylinder(0.09, 2.6, segments=6, center=(1.05, 1.3, 0.45)),   # Right conduit
    ]
    # 6 rack blade drawers
    for b in range(6):
        y_pos = 0.45 + b * 0.36
        mainframe_parts.append(generate_box(1.9, 0.28, 0.06, center=(0, y_pos, 0.52)))
        mainframe_parts.append(generate_box(0.12, 0.04, 0.02, center=(0.85, y_pos, 0.56))) # Status LED
    export_model("mainframe_bank.glb", mainframe_parts, "MainframeBank", base_color=(0.22, 0.24, 0.28, 1.0), metallic=0.45, roughness=0.65, emissive_factor=(0.0, 0.0, 0.0))

    # 7. Industrial Cable Nest
    cable_parts = [
        # Main floor trunk 1
        generate_tube_path([(-1.4, 0.04, -0.8), (-0.8, 0.06, -0.3), (-0.1, 0.05, 0.2), (0.7, 0.05, 0.6), (1.4, 0.06, 1.0)], radius=0.06, segments=6),
        # Intertwining floor trunk 2
        generate_tube_path([(-1.2, 0.05, -0.6), (-0.6, 0.08, 0.1), (0.2, 0.06, 0.4), (0.9, 0.04, 0.9), (1.5, 0.05, 1.3)], radius=0.05, segments=6),
        # Branch 1 (wall tap)
        generate_tube_path([(-0.3, 0.05, 0.1), (-0.6, 0.2, 0.6), (-0.9, 0.6, 1.0), (-1.1, 1.2, 1.1)], radius=0.035, segments=6),
        # Branch 2 (wall tap)
        generate_tube_path([(0.4, 0.05, 0.4), (0.8, 0.3, 0.2), (1.1, 0.8, 0.0), (1.2, 1.4, -0.1)], radius=0.035, segments=6),
        # Cable ties / clamps
        generate_torus(major_radius=0.1, minor_radius=0.02, segments_major=8, segments_minor=4, center=(-0.7, 0.07, -0.2), axis='Y'),
        generate_torus(major_radius=0.1, minor_radius=0.02, segments_major=8, segments_minor=4, center=(0.8, 0.06, 0.75), axis='Y'),
    ]
    export_model("cable_nest.glb", cable_parts, "IndustrialCable", base_color=(0.14, 0.14, 0.16, 1.0), metallic=0.05, roughness=0.92)

    # 8. Coolant Pipe Junction (with Valve Wheel and Flanges)
    pipe_parts = [
        generate_cylinder(0.18, 3.2, segments=8, center=(0, 1.6, 0)),                      # Main vertical conduit
        generate_cylinder(0.15, 2.2, segments=8, center=(0, 1.8, 0), axis='X'),            # Cross pipe
        generate_cylinder(0.24, 0.08, segments=8, center=(0, 3.1, 0)),                    # Top flange
        generate_cylinder(0.24, 0.08, segments=8, center=(0, 0.1, 0)),                    # Bottom flange
        generate_cylinder(0.22, 0.08, segments=8, center=(-1.05, 1.8, 0), axis='X'),       # Left flange
        generate_cylinder(0.22, 0.08, segments=8, center=(1.05, 1.8, 0), axis='X'),        # Right flange
        generate_cylinder(0.05, 0.35, segments=6, center=(0, 1.8, 0.25), axis='Z'),        # Valve stem
        generate_torus(major_radius=0.22, minor_radius=0.03, segments_major=12, segments_minor=6, center=(0, 1.8, 0.42), axis='Z'), # Valve rim
        generate_cylinder(0.025, 0.44, segments=4, center=(0, 1.8, 0.42), axis='X'),       # Valve horizontal spoke
        generate_cylinder(0.025, 0.44, segments=4, center=(0, 1.8, 0.42), axis='Y'),       # Valve vertical spoke
        generate_cylinder(0.12, 0.08, segments=8, center=(0.35, 2.3, 0.18), axis='Z'),     # Pressure gauge
    ]
    export_model("coolant_pipe_junction.glb", pipe_parts, "CoolantPipe", base_color=(0.48, 0.42, 0.36, 1.0), metallic=0.45, roughness=0.72)

    # 9. Bulkhead Blast Door (Hydraulic security gate)
    blast_door_parts = [
        generate_box(0.4, 3.4, 0.6, center=(-1.4, 1.7, 0)),                    # Left jamb
        generate_box(0.4, 3.4, 0.6, center=(1.4, 1.7, 0)),                     # Right jamb
        generate_box(3.2, 0.5, 0.7, center=(0, 3.35, 0)),                      # Top lintel
        generate_box(3.2, 0.15, 0.6, center=(0, 0.075, 0)),                    # Floor threshold
        generate_box(1.15, 2.9, 0.18, center=(-0.58, 1.6, -0.05)),             # Left leaf
        generate_box(1.15, 2.9, 0.18, center=(0.58, 1.6, 0.05)),              # Right leaf
        generate_cylinder(0.08, 1.1, segments=6, center=(-0.9, 3.05, 0.25), axis='X'), # Left hydraulic cylinder
        generate_cylinder(0.08, 1.1, segments=6, center=(0.9, 3.05, 0.25), axis='X'),  # Right hydraulic cylinder
        generate_box(0.15, 2.6, 0.06, center=(-0.6, 1.6, 0.06)),               # Structural rib L
        generate_box(0.15, 2.6, 0.06, center=(0.6, 1.6, 0.16)),                # Structural rib R
    ]
    export_model("blast_door.glb", blast_door_parts, "BulkheadBlastDoor", base_color=(0.32, 0.34, 0.38, 1.0), metallic=0.55, roughness=0.68)

    # 10. Memory Core Keycard (Cybernetic collectible)
    core_parts = [
        generate_box(0.24, 0.02, 0.36, center=(0, 0.5, 0)),                    # Green circuit PCB
        generate_box(0.22, 0.025, 0.06, center=(0, 0.5, 0.16)),                # Gold edge contacts
        generate_box(0.06, 0.02, 0.08, center=(-0.06, 0.52, 0.04)),           # RAM IC 1
        generate_box(0.06, 0.02, 0.08, center=(0.06, 0.52, 0.04)),            # RAM IC 2
        generate_box(0.06, 0.02, 0.08, center=(-0.06, 0.52, -0.08)),          # RAM IC 3
        generate_box(0.06, 0.02, 0.08, center=(0.06, 0.52, -0.08)),           # RAM IC 4
        generate_box(0.08, 0.04, 0.08, center=(0, 0.53, -0.02)),               # Glowing quantum core
    ]
    export_model("memory_core_pickup.glb", core_parts, "MemoryCore", base_color=(0.15, 0.55, 0.35, 1.0), metallic=0.6, roughness=0.35, emissive_factor=(0.1, 0.85, 1.0))

    # 11. Handheld EMP Stun Pulse Emitter
    emp_parts = [
        generate_box(0.25, 0.15, 0.45, center=(0, 0.3, 0)),                     # Main housing
        generate_cylinder(0.08, 0.25, segments=6, center=(0, 0.15, -0.1), axis='Y'), # Pistol grip
        generate_torus(0.12, 0.025, segments_major=8, segments_minor=4, center=(0, 0.3, 0.25), axis='Z'), # Front emitter ring
    ]
    export_model("emp_device.glb", emp_parts, "EMPDevice", base_color=(0.2, 0.22, 0.25, 1.0), metallic=0.8, roughness=0.25)

    print("=== Sub-Routine Enhanced Procedural Asset Generator Finished (11 Models Exported) ===")

if __name__ == "__main__":
    main()
