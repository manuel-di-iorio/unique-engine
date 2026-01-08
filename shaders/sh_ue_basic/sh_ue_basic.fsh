varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Emissive
uniform vec3 u_ueEmissive;
uniform float u_ueEmissiveIntensity;

// Textures
uniform sampler2D s_emissiveMap;
uniform float u_ueHasMap;
uniform float u_ueHasEmissiveMap;

void main()
{
    vec4 tex = (u_ueHasMap > 0.5) ? texture2D(gm_BaseTexture, v_vTexcoord) : vec4(1.0);
    vec4 baseColor = v_vColour * tex;
    
    // === Emissive ===
    vec3 emissiveTex = (u_ueHasEmissiveMap > 0.5) ? texture2D(s_emissiveMap, v_vTexcoord).rgb : vec3(0.0);
    vec3 emissive = (emissiveTex + u_ueEmissive) * u_ueEmissiveIntensity;
    vec3 finalColor = baseColor.rgb + emissive;
    
    gl_FragColor = vec4(finalColor.rgb, baseColor.a);
}
