// Outline fragment shader (Sobel filter on luminance)
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_visibleEdgeColor; // RGB
uniform float u_thickness;       // outline radius in pixels
uniform float u_edgeStrength;    // intensity multiplier
uniform float u_edgeGlow;        // softening factor
uniform vec3 u_hiddenEdgeColor;  // color for hidden edges (not used here yet)
uniform vec2 u_texelSize;        // texel size (1 / texture size)

// Get luminance from color
float luminance(vec4 c) {
    return dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    // Sample the base color
    vec4 baseColor = texture2D(gm_BaseTexture, v_vTexcoord);
    
    // Calculate texel size in UV space
    vec2 texel = u_texelSize * u_thickness;

    // Sample 3x3 neighborhood for Sobel edge detection
    float tl = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(-texel.x, -texel.y)));
    float  t = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, -texel.y)));
    float tr = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(texel.x, -texel.y)));
    float l  = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(-texel.x, 0.0)));
    float c  = luminance(texture2D(gm_BaseTexture, v_vTexcoord));
    float r  = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(texel.x, 0.0)));
    float bl = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(-texel.x, texel.y)));
    float b  = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(0.0, texel.y)));
    float br = luminance(texture2D(gm_BaseTexture, v_vTexcoord + vec2(texel.x, texel.y)));

    // Sobel kernels
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;

    float edge = length(vec2(gx, gy));
    edge = edge * u_edgeStrength;

    // Apply glow/softening
    float edgeAlpha = 1.0 - exp(-edge * (1.0 + u_edgeGlow));

    // Blend: base color + edge overlay
    vec3 edgeColor = u_visibleEdgeColor;
    vec3 finalColor = mix(baseColor.rgb, edgeColor, edgeAlpha);

    gl_FragColor = vec4(finalColor, baseColor.a);
}
