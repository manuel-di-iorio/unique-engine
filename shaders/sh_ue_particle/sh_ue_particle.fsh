//
// Optimized Particle Fragment Shader (Shadows Hidden)
//
varying vec2 v_vTexcoord;  // Atlas UV
varying vec2 v_vLocalUV;   // Local UV (0..2)
varying vec4 v_vColour;
// varying vec4 v_vShadowCoord;
varying float v_vDepth;

uniform float u_ueSoftFactor;
uniform sampler2D u_ueDepthTexture;
uniform float u_ueNear;
uniform float u_ueFar;
// uniform sampler2D s_dirShadowMap;
// uniform float u_ueReceiveShadow;

void main()
{
    // Clip the Big Triangle to the [0,1] Quad area using Local UVs
    if (v_vLocalUV.x > 1.0 || v_vLocalUV.y > 1.0) discard;

    vec4 tex = texture2D( gm_BaseTexture, v_vTexcoord );
    vec4 finalColor = v_vColour * tex;
    
    // Soft Particles
    if (u_ueSoftFactor > 0.0) {
        vec2 screenUV = gl_FragCoord.xy / vec2(800.0, 600.0); 
        float sceneDepth = texture2D(u_ueDepthTexture, screenUV).r;
        float particleDepth = gl_FragCoord.z;
        float fade = clamp((sceneDepth - particleDepth) * u_ueSoftFactor, 0.0, 1.0);
        finalColor.a *= fade;
    }

    // Shadow Receiving (Disabled)
    /*
    if (u_ueReceiveShadow > 0.5) {
        vec3 shadowUV = v_vShadowCoord.xyz / v_vShadowCoord.w;
        shadowUV = shadowUV * 0.5 + 0.5;
        float shadowDepth = texture2D(s_dirShadowMap, shadowUV.xy).r;
        if (shadowUV.z > shadowDepth + 0.001) {
            finalColor.rgb *= 0.5;
        }
    }
    */

    if (finalColor.a < 0.01) discard;
    
    gl_FragColor = finalColor;
}
