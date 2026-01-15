precision highp float;

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec4 vWorldTangent;
varying vec2 vTexcoord;
varying vec4 vColour;

// ===== Scene =====
uniform vec4  u_ueSceneData[5];
#define u_ueCameraPosition u_ueSceneData[0].xyz

// ===== Material =====
uniform vec3  u_ueColor;
uniform float u_ueMetalness;
uniform float u_ueRoughness;
uniform vec3  u_ueEmissive;
uniform vec4  u_ueMaterialData; // [emissiveIntensity, toneMapping, toneMappingExposure, toneMapped]
#define u_ueEmissiveIntensity   u_ueMaterialData.x
#define u_ueToneMapping         u_ueMaterialData.y
#define u_ueToneMappingExposure u_ueMaterialData.z
#define u_ueToneMapped          u_ueMaterialData.w

uniform float u_ueAoIntensity;
uniform float u_ueAoMapIntensity;
uniform vec2  u_ueNormalMapScale;
uniform float u_ueFlatShading;
uniform float u_ueReceiveShadow;

// ===== Textures =====
uniform sampler2D s_alphaMap;
uniform sampler2D s_ormMap;
uniform sampler2D s_normalMap;
uniform sampler2D s_emissiveMap;

uniform vec4 u_ueMapFlags;  // [hasMap, hasAlphaMap, hasOrmMap, hasNormalMap]
#define u_ueHasMap              u_ueMapFlags.x
#define u_ueHasAlphaMap         u_ueMapFlags.y
#define u_ueHasOrmMap           u_ueMapFlags.z
#define u_ueHasNormalMap        u_ueMapFlags.w

uniform vec4 u_ueMapFlags2; // [hasEmissiveMap, hasDisplacementMap, 0, 0]
#define u_ueHasEmissiveMap      u_ueMapFlags2.x
#define u_ueHasDisplacementMap  u_ueMapFlags2.y

#define EPSILON 1e-6

// ===== TBN =====
mat3 calculateTBN(vec3 N, vec3 pos, vec2 uv, vec4 vT) {
    if (length(vT.xyz) > 0.1) {
        vec3 T = normalize(vT.xyz);
        T = normalize(T - dot(T, N) * N);
        vec3 B = cross(N, T) * vT.w;
        return mat3(T, B, N);
    }
    vec3 dp1 = dFdx(pos);
    vec3 dp2 = dFdy(pos);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);
    float det = (duv1.x * duv2.y - duv1.y * duv2.x);
    if (abs(det) < EPSILON) return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), N);
    vec3 T = normalize(dp1 * duv2.y - dp2 * duv1.y);
    vec3 B = normalize(dp2 * duv1.x - dp1 * duv2.x);
    T = normalize(T - dot(T, N) * N);
    return mat3(T, B, N);
}

// ===== Color Space =====
vec3 SRGBToLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }

void main() {
    // ===== Base =====
    vec4 tex = (u_ueHasMap > 0.5) ? texture2D(gm_BaseTexture, vTexcoord) : vec4(1.0);
    vec4 vCol = vColour;
    if (length(vCol.rgb) < 0.001) vCol.rgb = vec3(1.0);
    if (vCol.a < 0.001) vCol.a = 1.0;
    
    vec4 base = tex * vCol;
    float alphaMap = (u_ueHasAlphaMap > 0.5) ? texture2D(s_alphaMap, vTexcoord).r : 1.0;
    float alpha = base.a * alphaMap;

    // Discard if transparent (for Opaque pass, we can use alpha testing)
    if (alpha < 0.5) discard;

    vec3 albedo = SRGBToLinear(base.rgb) * SRGBToLinear(u_ueColor);

    vec3 orm = (u_ueHasOrmMap > 0.5) ? texture2D(s_ormMap, vTexcoord).rgb : vec3(1.0, 1.0, 0.0);
    float ao = mix(1.0, orm.r, u_ueAoIntensity * u_ueAoMapIntensity);
    float roughness = orm.g * u_ueRoughness;
    float metalness = orm.b * u_ueMetalness;

    // ===== Normal =====
    vec3 N;
    if (u_ueFlatShading > 0.5) {
        N = normalize(cross(dFdx(vWorldPosition), dFdy(vWorldPosition)));
    } else {
        N = normalize(vWorldNormal);
    }

    if (u_ueHasNormalMap > 0.5) {
        vec3 normalMapSample = texture2D(s_normalMap, vTexcoord).rgb;
        vec3 nm = normalMapSample * 2.0 - 1.0;
        nm.xy *= u_ueNormalMapScale;
        mat3 TBN = calculateTBN(N, vWorldPosition, vTexcoord, vWorldTangent);
        N = normalize(TBN * nm);
    }

    // ===== Emissive =====
    vec3 emissiveMapColor = (u_ueHasEmissiveMap > 0.5) ? SRGBToLinear(texture2D(s_emissiveMap, vTexcoord).rgb) : vec3(0.0);
    vec3 emissive = (emissiveMapColor + SRGBToLinear(u_ueEmissive)) * u_ueEmissiveIntensity;

    // MRT Outputs
    // Target 0: Albedo (RGB) + Alpha (A)
    gl_FragData[0] = vec4(albedo, alpha);
    
    // Target 1: Normal (RGB) + Metalness (A)
    gl_FragData[1] = vec4(N * 0.5 + 0.5, metalness);
    
    // Target 2: Roughness (R) + AO/Shadow (G)
    // We pack AO and ReceiveShadow into the G channel
    // Positive values = receive shadow, negative values = do not receive shadow
    float aoOut = ao;
    if (u_ueReceiveShadow < 0.5) aoOut = -ao - 0.001;
    
    gl_FragData[2] = vec4(roughness, aoOut, 0.0, 1.0);
    
    // Target 3: Emissive (RGB)
    gl_FragData[3] = vec4(emissive, 1.0);
}
