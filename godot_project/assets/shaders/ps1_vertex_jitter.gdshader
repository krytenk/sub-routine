shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

// PS1 Authentic Vertex Jitter & Affine Texture Warping Shader
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float jitter_resolution : hint_range(32.0, 480.0) = 180.0;
uniform bool enable_affine_warp = true;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
    // Transform to clip space
    vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    
    // Snap vertex positions to simulate PS1 lack of sub-pixel floating point precision
    vec2 grid = vec2(jitter_resolution, jitter_resolution * (VIEWPORT_SIZE.y / VIEWPORT_SIZE.x));
    clip_pos.xy = floor(clip_pos.xy / clip_pos.w * grid + 0.5) / grid * clip_pos.w;
    
    POSITION = clip_pos;
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb * tint_color.rgb;
    ROUGHNESS = 0.95;
    METALLIC = 0.05;
}
