varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Emissive
uniform vec3 u_ueEmissive;
uniform float u_ueEmissiveIntensity;
uniform vec3 u_ueMaterialData; // [toneMapping, toneMappingExposure, toneMapped]
#define u_ueToneMapping         u_ueMaterialData.x
#define u_ueToneMappingExposure u_ueMaterialData.y
#define u_ueToneMapped          u_ueMaterialData.z

// Textures
uniform sampler2D s_emissiveMap;
uniform vec4 u_ueMapFlags;  // [hasMap, hasAlphaMap, hasOrmMap, hasNormalMap]
#define u_ueHasMap              u_ueMapFlags.x
#define u_ueHasAlphaMap         u_ueMapFlags.y
#define u_ueHasOrmMap           u_ueMapFlags.z
#define u_ueHasNormalMap        u_ueMapFlags.w

uniform vec4 u_ueMapFlags2; // [hasEmissiveMap, hasDisplacementMap, alphaTest, 0]
#define u_ueHasEmissiveMap      u_ueMapFlags2.x
#define u_ueHasDisplacementMap  u_ueMapFlags2.y
#define u_ueAlphaTest           u_ueMapFlags2.z

void main()
{
    vec4 tex = (u_ueHasMap > 0.5) ? texture2D(gm_BaseTexture, v_vTexcoord) : vec4(1.0);
    vec4 baseColor = v_vColour * tex;
    
    // Alpha Test
    if (baseColor.a < u_ueAlphaTest) discard;
    
    // === Emissive ===
    vec3 emissiveTex = (u_ueHasEmissiveMap > 0.5) ? texture2D(s_emissiveMap, v_vTexcoord).rgb : vec3(0.0);
    vec3 emissive = (emissiveTex + u_ueEmissive) * u_ueEmissiveIntensity;
    vec3 finalColor = baseColor.rgb + emissive;
    
    gl_FragColor = vec4(finalColor.rgb, baseColor.a);
}
