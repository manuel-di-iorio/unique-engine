varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Emissive
uniform vec3 u_ueEmissive;
uniform float u_ueEmissiveIntensity;

// Textures
uniform sampler2D s_emissiveMap;

void main()
{
    vec4 baseColor = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    
    // === Emissive ===
    vec3 emissiveTex = texture2D(s_emissiveMap, v_vTexcoord).rgb;
    vec3 emissive = (emissiveTex + u_ueEmissive) * u_ueEmissiveIntensity;
    vec3 finalColor = baseColor.rgb + emissive;
    
    gl_FragColor = vec4(finalColor.rgb, baseColor.a);
}
