shader_type canvas_item;

// PS1 CRT Phosphor Decay & Glitch Overlay Shader
// Provides authentic CRT scanlines, chromatic aberration, curvature, and Overseer glitch tears.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_count : hint_range(100.0, 720.0) = 360.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.28;
uniform float curvature : hint_range(0.0, 0.15) = 0.035;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0035;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.85;

vec2 curve_uv(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv *= 1.0 + pow(length(uv) * curvature, 2.0);
    return (uv / 2.0) + 0.5;
}

float random_noise(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = curve_uv(SCREEN_UV);

    // Black out out-of-bounds curve border
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // Overseer horizontal glitch tearing
        if (glitch_intensity > 0.01) {
            float slice = floor(uv.y * 30.0);
            float noise = random_noise(vec2(slice, TIME * 12.0));
            if (noise < glitch_intensity * 0.45) {
                float shift = (random_noise(vec2(slice, TIME * 18.0)) - 0.5) * glitch_intensity * 0.15;
                uv.x += shift;
            }
        }

        // Chromatic aberration (RGB channel split)
        float split = chromatic_aberration + (glitch_intensity * 0.008);
        float r = texture(screen_texture, vec2(uv.x + split, uv.y)).r;
        float g = texture(screen_texture, uv).g;
        float b = texture(screen_texture, vec2(uv.x - split, uv.y)).b;
        vec3 col = vec3(r, g, b);

        // CRT Scanlines
        float scanline = sin(uv.y * scanline_count * 3.14159265);
        scanline = (scanline + 1.0) * 0.5;
        col *= 1.0 - (scanline * scanline_intensity);

        // Phosphor vignette falloff
        vec2 vig_uv = (uv - 0.5) * 2.0;
        float vig = 1.0 - dot(vig_uv, vig_uv) * (vignette_strength * 0.25);
        col *= clamp(vig, 0.0, 1.0);

        // Subtle phosphor green bias
        col.g *= 1.04;

        COLOR = vec4(col, 1.0);
    }
}
