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

// Outline parameters
uniform vec3 u_visibleEdgeColor;  // RGB color for visible edges
uniform float u_thickness;        // Edge thickness in pixels
uniform float u_edgeStrength;     // Intensity multiplier
uniform float u_edgeGlow;         // Softening/glow factor
uniform vec2 u_texelSize;         // 1.0 / texture dimensions

// Optimization: G-Buffer support
uniform float u_useGBuffer;       // 1.0 if we should use G-Buffer for better edges
uniform float u_normalEdgeStrength; // Strength of edges from normal map

// Textures
uniform sampler2D s_mask;         // Mask texture containing selected objects
uniform sampler2D s_gbufferNormal; // G-Buffer Normal map (optional)
uniform sampler2D s_gbufferDepth;  // G-Buffer Depth/Position (optional)

/**
 * Sobel edge detection on the mask texture.
 */
float detectMaskEdge(vec2 uv) {
    vec2 texel = u_texelSize * u_thickness;
    
    float tl = texture2D(s_mask, uv + vec2(-texel.x, -texel.y)).r;
    float t  = texture2D(s_mask, uv + vec2(0.0, -texel.y)).r;
    float tr = texture2D(s_mask, uv + vec2(texel.x, -texel.y)).r;
    float l  = texture2D(s_mask, uv + vec2(-texel.x, 0.0)).r;
    float r  = texture2D(s_mask, uv + vec2(texel.x, 0.0)).r;
    float bl = texture2D(s_mask, uv + vec2(-texel.x, texel.y)).r;
    float b  = texture2D(s_mask, uv + vec2(0.0, texel.y)).r;
    float br = texture2D(s_mask, uv + vec2(texel.x, texel.y)).r;
    
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    
    return length(vec2(gx, gy));
}

/**
 * Edge detection based on normals from G-Buffer.
 */
float detectNormalEdge(vec2 uv) {
    vec2 texel = u_texelSize * u_thickness;
    
    vec3 n_t = texture2D(s_gbufferNormal, uv + vec2(0.0, -texel.y)).rgb * 2.0 - 1.0;
    vec3 n_b = texture2D(s_gbufferNormal, uv + vec2(0.0, texel.y)).rgb * 2.0 - 1.0;
    vec3 n_l = texture2D(s_gbufferNormal, uv + vec2(-texel.x, 0.0)).rgb * 2.0 - 1.0;
    vec3 n_r = texture2D(s_gbufferNormal, uv + vec2(texel.x, 0.0)).rgb * 2.0 - 1.0;
    
    // Dot product difference between neighbors
    float edge = 0.0;
    edge += 1.0 - dot(n_t, n_b);
    edge += 1.0 - dot(n_l, n_r);
    
    return edge;
}

void main() {
    // Sample the original scene color
    vec4 sceneColor = texture2D(gm_BaseTexture, v_vTexcoord);
    
    // Detect edges on the mask (silhouette of selected objects)
    float maskEdge = detectMaskEdge(v_vTexcoord);
    
    // Detect edges from G-Buffer if available
    float finalEdge = maskEdge * u_edgeStrength;
    
    if (u_useGBuffer > 0.5) {
        float normalEdge = detectNormalEdge(v_vTexcoord);
        
        // We only apply normal edges where the mask is present (internal edges of selected objects)
        // or globally if we want a full scene outline.
        // For now, let's use the mask as a gate for normal edges to keep it focused on selection.
        float maskVal = texture2D(s_mask, v_vTexcoord).r;
        finalEdge += normalEdge * u_normalEdgeStrength * maskVal;
    }
    
    // Apply glow/softening effect
    float edgeAlpha = 1.0 - exp(-finalEdge * (1.0 + u_edgeGlow));
    
    // Blend: mix scene color with edge color based on edge intensity
    vec3 finalColor = mix(sceneColor.rgb, u_visibleEdgeColor, edgeAlpha);
    
    gl_FragColor = vec4(finalColor, sceneColor.a);
}
