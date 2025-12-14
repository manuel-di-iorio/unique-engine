/**
 * Outline Pass Fragment Shader
 * 
 * This shader performs edge detection on a MASK texture (not the scene).
 * The mask contains selected objects rendered as white on black background.
 * 
 * How it works:
 * 1. gm_BaseTexture = the original scene (passed via draw_surface/vertex_submit)
 * 2. s_mask = the mask with selected objects in white
 * 3. Sobel edge detection is applied to the MASK to find silhouette edges
 * 4. The detected edges are overlaid onto the original scene
 * 
 * This approach only detects the external contours of selected objects,
 * not internal shading edges, because the mask is a flat white silhouette.
 */

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Outline parameters
uniform vec3 u_visibleEdgeColor;  // RGB color for visible edges
uniform float u_thickness;        // Edge thickness in pixels
uniform float u_edgeStrength;     // Intensity multiplier
uniform float u_edgeGlow;         // Softening/glow factor
uniform vec2 u_texelSize;         // 1.0 / texture dimensions

// Mask texture containing selected objects as white silhouettes
uniform sampler2D s_mask;

/**
 * Sobel edge detection on the mask texture.
 * Returns edge intensity (0 = no edge, higher = stronger edge).
 */
float detectEdge(vec2 uv) {
    vec2 texel = u_texelSize * u_thickness;
    
    // Sample 3x3 neighborhood from the MASK (not the scene)
    // We only need the red channel since the mask is grayscale
    float tl = texture2D(s_mask, uv + vec2(-texel.x, -texel.y)).r;
    float t  = texture2D(s_mask, uv + vec2(0.0, -texel.y)).r;
    float tr = texture2D(s_mask, uv + vec2(texel.x, -texel.y)).r;
    float l  = texture2D(s_mask, uv + vec2(-texel.x, 0.0)).r;
    float r  = texture2D(s_mask, uv + vec2(texel.x, 0.0)).r;
    float bl = texture2D(s_mask, uv + vec2(-texel.x, texel.y)).r;
    float b  = texture2D(s_mask, uv + vec2(0.0, texel.y)).r;
    float br = texture2D(s_mask, uv + vec2(texel.x, texel.y)).r;
    
    // Sobel kernels for gradient detection
    // Horizontal gradient: detects vertical edges
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    // Vertical gradient: detects horizontal edges  
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    
    // Combined gradient magnitude
    return length(vec2(gx, gy));
}

void main() {
    // Sample the original scene color
    vec4 sceneColor = texture2D(gm_BaseTexture, v_vTexcoord);
    
    // Detect edges on the mask
    float edge = detectEdge(v_vTexcoord);
    edge = edge * u_edgeStrength;
    
    // Apply glow/softening effect
    // exp(-x) creates a smooth falloff; higher edgeGlow = more spread
    float edgeAlpha = 1.0 - exp(-edge * (1.0 + u_edgeGlow));
    
    // Blend: mix scene color with edge color based on edge intensity
    vec3 finalColor = mix(sceneColor.rgb, u_visibleEdgeColor, edgeAlpha);
    
    gl_FragColor = vec4(finalColor, sceneColor.a);
}
