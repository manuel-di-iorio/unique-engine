varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying float v_vSoftness;
varying float v_vGlow;
varying vec4 v_vScreenPos;
varying vec4 v_vShadowPos;

uniform sampler2D u_ueDepthTex;
uniform vec4 u_ueDepthParams; // x: near, y: far, z: softness_inv_range, w: enabled

uniform sampler2D u_ueShadowTex;
uniform vec4 u_ueShadowParams; // x: strength, y: bias, z: size, w: enabled

uniform float u_ueTime;

void main() {
    float finalSoftness = v_vSoftness;
    
    // Optional Depth Check (Soft Particles)
    if (u_ueDepthParams.w > 0.5) {
        vec2 screenUV = (v_vScreenPos.xy / v_vScreenPos.w) * 0.5 + 0.5;
        
        float sceneDepth = texture2D(u_ueDepthTex, screenUV).r;
        float particleDepth = (v_vScreenPos.z / v_vScreenPos.w) * 0.5 + 0.5;
        
        // Simple linear difference for softness
        float diff = (sceneDepth - particleDepth) * u_ueDepthParams.z;
        finalSoftness *= clamp(diff, 0.0, 1.0);
    }
    
    if (finalSoftness < 0.005) discard;
    
    float shadow = 1.0;
    if (u_ueShadowParams.w > 0.5) {
        vec3 shadowCoord = (v_vShadowPos.xyz / v_vShadowPos.w) * 0.5 + 0.5;
        float shadowDepth = texture2D(u_ueShadowTex, shadowCoord.xy).r;
        if (shadowCoord.z > shadowDepth + u_ueShadowParams.y) {
            shadow = 1.0 - u_ueShadowParams.x;
        }
    }
    
    vec4 texColor = texture2D(gm_BaseTexture, v_vTexcoord);
    
    vec4 finalColor = v_vColour * texColor;
    finalColor.rgb *= v_vGlow * shadow; // Apply emissive glow and shadow
    finalColor.a *= finalSoftness; // Apply ground fading and depth softness
    
    gl_FragColor = finalColor;
}
