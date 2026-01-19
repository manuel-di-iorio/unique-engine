precision highp float;

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec4 vWorldTangent;
varying vec2 vTexcoord;
varying vec4 vColour;
varying vec4 vDirLightSpacePos;
varying vec4 vSpotLightSpacePos;

// ===== Scene =====
uniform mat4  u_ueWorldMatrix;
uniform vec4  u_ueSceneData[5];
// Row 0: camPos.xyz, fogDensity
// Row 1: ambient.rgb, fogNear
// Row 2: fogColor.rgb, fogFar
// Row 3: dirLightDir.xyz, dirLightIntensity
// Row 4: dirLightColor.rgb, [unused]

// ===== Material =====
uniform vec3  u_ueColor;
uniform float u_ueMetalness;
uniform float u_ueRoughness;
uniform vec3  u_ueEmissive;
uniform float u_ueEmissiveIntensity;
uniform vec3  u_ueMaterialData; // [toneMapping, toneMappingExposure, toneMapped]
#define u_ueToneMapping         u_ueMaterialData.x
#define u_ueToneMappingExposure u_ueMaterialData.y
#define u_ueToneMapped          u_ueMaterialData.z

uniform float u_ueAoIntensity;
uniform float u_ueAoMapIntensity;
uniform vec2  u_ueNormalMapScale;
uniform float u_ueFlatShading;
uniform float u_ueBumpScale;
uniform float u_ueLightMapIntensity;
uniform float u_ueEnvMapIntensity;
uniform vec3  u_ueEnvMapRotation;

// ===== Textures =====
uniform sampler2D s_alphaMap;
uniform sampler2D s_ormMap;
uniform sampler2D s_normalMap;
uniform sampler2D s_emissiveMap;
// uniform sampler2D s_bumpMap;
// uniform sampler2D s_lightMap;
// uniform sampler2D s_envMap;

uniform vec4 u_ueMapFlags;  // [hasMap, hasAlphaMap, hasOrmMap, hasNormalMap]
#define u_ueHasMap              u_ueMapFlags.x
#define u_ueHasAlphaMap         u_ueMapFlags.y
#define u_ueHasOrmMap           u_ueMapFlags.z
#define u_ueHasNormalMap        u_ueMapFlags.w

uniform vec4 u_ueMapFlags2; // [hasEmissiveMap, hasDisplacementMap, 0, 0]
#define u_ueHasEmissiveMap      u_ueMapFlags2.x
#define u_ueHasDisplacementMap  u_ueMapFlags2.y

// ===== Lights =====

// Point Lights (Packed in Mat4)
// Row 0: pos.xyz, range
// Row 1: color.rgb, intensity
// Row 2: decay, 0.0, 0.0, 0.0
uniform mat4  u_uePointLightsData[8];

// Spot Lights (Packed in Mat4)
// Row 0: pos.xyz, range
// Row 1: color.rgb, intensity
// Row 2: dir.xyz, decay
// Row 3: angle, penumbra, 0.0, 0.0
uniform mat4  u_ueSpotLightsData[8];

// Hemisphere Light
uniform vec3  u_ueHemiLightDirection;
uniform vec3  u_ueHemiLightSkyColor;
uniform vec3  u_ueHemiLightGroundColor;
uniform float u_ueHemiLightIntensity;

// ===== Shadow =====
uniform sampler2D s_dirShadowMap;
uniform sampler2D s_pointShadowMap;
uniform sampler2D s_spotShadowMap;
uniform float u_ueDirShadowEnabled;
uniform float u_uePointShadowEnabled;
uniform float u_ueSpotShadowEnabled;
uniform float u_ueReceiveShadow;
uniform float u_ueDirShadowInvTexelSize;
uniform vec2 u_uePointShadowInvTexelSize;
uniform float u_ueSpotShadowInvTexelSize;
uniform float u_ueDirShadowQuality;
uniform float u_uePointShadowQuality;
uniform float u_ueSpotShadowQuality;

// Point shadow specific
uniform float u_uePointShadowFar;
uniform float u_uePointShadowNear;
uniform vec3  u_uePointShadowPos;
uniform mat4  u_uePointShadowMatrix[6];

// Spot shadow specific
uniform float u_ueSpotShadowFar;
uniform float u_ueSpotShadowNear;
uniform vec3  u_ueSpotShadowPos;

// ===== Constants =====
#define PI 3.14159265359
#define GAMMA 2.2
#define EPSILON 1e-6

// ===== Color Space =====
vec3 SRGBToLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(GAMMA)); }
vec3 LinearToSRGB(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / GAMMA)); }

float LinearizeDepth(float depth, float zparam) 
{ 
#if !defined(_YY_HLSL11_) 
    depth = depth * 2.0 - 1.0; 
#endif 
    return 1.0 / ((1.0 - zparam) * depth + zparam); 
}

// ===== TBN (use precomputed tangents or fallback to derivatives) =====
mat3 calculateTBN(vec3 N, vec3 pos, vec2 uv, vec4 vT) {
    // Check if precomputed tangents are valid
    if (length(vT.xyz) > 0.1) {
        vec3 T = normalize(vT.xyz);
        // Re-orthogonalize T with respect to N
        T = normalize(T - dot(T, N) * N);
        // Reconstruct Bitangent
        vec3 B = cross(N, T) * vT.w;
        return mat3(T, B, N);
    }

    // Fallback: Calculate TBN using derivatives (dFdx/dFdy)
    vec3 dp1 = dFdx(pos);
    vec3 dp2 = dFdy(pos);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);

    float det = (duv1.x * duv2.y - duv1.y * duv2.x);
    if (abs(det) < EPSILON) return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), N);

    vec3 T = normalize(dp1 * duv2.y - dp2 * duv1.y);
    vec3 B = normalize(dp2 * duv1.x - dp1 * duv2.x);

    // Re-orthogonalize T
    T = normalize(T - dot(T, N) * N);

    return mat3(T, B, N);
}

// ===== GGX =====
float D_GGX(float NdotH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float d  = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

float G_SchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float G_Smith(float NdotV, float NdotL, float roughness) {
    return G_SchlickGGX(NdotV, roughness) *
           G_SchlickGGX(NdotL, roughness);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float calculateDirShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
    if (lightSpacePos.w < EPSILON) return 0.0;
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    
    p = p * 0.5 + 0.5;

    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 0.0;

    float bias = max(0.0015 * (1.0 - dot(N, L)), 0.0004);
    float shadow = 0.0;

    // 5-tap PCF (Center + corners)
    if (u_ueDirShadowQuality > 0.5) {
        vec2 texelSize = vec2(u_ueDirShadowInvTexelSize);
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2(-0.7, -0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2( 0.7, -0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2(-0.7,  0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2( 0.7,  0.7) * texelSize).r) ? 1.0 : 0.0;
        return shadow / 5.0;
    } else {
        float d = texture2D(s_dirShadowMap, p.xy).r;
        return (p.z - bias > d) ? 1.0 : 0.0;
    }
}

float calculatePointShadow(vec3 worldPos, vec3 N) {
    // === 1. Normal offset BIAS DINAMICO ===
    vec3 L = normalize(worldPos - u_uePointShadowPos);
    float NdotL = max(dot(N, -L), 0.0);

    float normalBias = mix(0.02, 0.005, NdotL);
    vec3 shadowPos = worldPos + N * normalBias;

    // === 2. Direzione corretta dal punto alla luce ===
    vec3 dir = shadowPos - u_uePointShadowPos;

    float absX = abs(dir.x);
    float absY = abs(dir.y);
    float absZ = abs(dir.z);

    int faceIndex;
    /* if (absZ >= absX && absZ >= absY) {
         faceIndex = (dir.z < 0.0) ? 0 : 1;
    } else */ if (absY >= absX && absY >= absZ) {
        faceIndex = (dir.y < 0.0) ? 2 : 3;
    } else {
        faceIndex = (dir.x < 0.0) ? 4 : 5;
    }

    // === 3. Trasformazione nello space corretto ===
    vec4 lightSpacePos = u_uePointShadowMatrix[faceIndex] * vec4(shadowPos, 1.0);

    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    p = p * 0.5 + 0.5;
    p.y = 1.0 - p.y;

    // === 4. Scarta fuori frustum (FONDAMENTALE) ===
    if (p.z > 1.0 || p.z < 0.0) {
        return 0.0;
    }

    // === 5. Atlas 3x2 corretto ===
    int col = faceIndex - (faceIndex / 3) * 3;
    int row = faceIndex / 3;

    vec2 tileMin = vec2(float(col) / 3.0, float(row) / 2.0);
    vec2 tileMax = tileMin + vec2(1.0 / 3.0, 1.0 / 2.0);

    vec2 texelSize = u_uePointShadowInvTexelSize;
    vec2 margin = texelSize * 1.5;

    vec2 tMin = tileMin + margin;
    vec2 tMax = tileMax - margin;

    vec2 uv = tileMin + p.xy * vec2(1.0 / 3.0, 1.0 / 2.0);

    // === 6. PROFONDITÀ LINEARE COERENTE ===
    float currentDepth =
        (length(shadowPos - u_uePointShadowPos) - u_uePointShadowNear) /
        (u_uePointShadowFar - u_uePointShadowNear);

    // === 7. Bias slope-scale corretto ===
    float bias = max(0.01 * (1.0 - NdotL), 0.002);

    // === 8. PCF ===
    float shadow = 0.0;

    if (u_uePointShadowQuality > 0.5) {
        vec2 offsets[5];
        offsets[0] = vec2(0.0, 0.0);
        offsets[1] = vec2(-1.0, -1.0);
        offsets[2] = vec2( 1.0, -1.0);
        offsets[3] = vec2(-1.0,  1.0);
        offsets[4] = vec2( 1.0,  1.0);

        for (int i = 0; i < 5; i++) {
            vec2 u = clamp(uv + offsets[i] * texelSize, tMin, tMax);
            float depth = texture2D(s_pointShadowMap, u).r;
            shadow += (currentDepth - bias > depth) ? 1.0 : 0.0;
        }

        return shadow / 5.0;
    }

    float depth = texture2D(s_pointShadowMap, clamp(uv, tMin, tMax)).r;
    return (currentDepth - bias > depth) ? 1.0 : 0.0;
}

float calculateSpotShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
    if (lightSpacePos.w < EPSILON) return 0.0;
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    
    // Map NDC to UV for x and y
    p.xy = p.xy * 0.5 + 0.5;
    p.y = 1.0 - p.y; // Flip Y for GameMaker surfaces
    
    // Scarta fuori frustum
    if (p.x < 0.0 || p.x > 1.0 ||
        p.y < 0.0 || p.y > 1.0 ||
        p.z < 0.0 || p.z > 1.0)
    {
        return 0.0;
    }

    float zparam = u_ueSpotShadowFar / u_ueSpotShadowNear;
    float currentDepth = LinearizeDepth(p.z, zparam);

    // Bias (slightly adjusted for linear depth)
    float cosTheta = clamp(dot(N, L), 0.0, 1.0);
    float bias = max(0.005 * (1.0 - cosTheta), 0.001);

    float shadow = 0.0;

    // 5-tap PCF (Center + corners)
    if (u_ueSpotShadowQuality > 0.5) {
        float texelSize = u_ueSpotShadowInvTexelSize;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2(-0.7, -0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2( 0.7, -0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2(-0.7,  0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2( 0.7,  0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        return shadow / 5.0;
    } else {
        float d = LinearizeDepth(texture2D(s_spotShadowMap, p.xy).r, zparam);
        return (currentDepth - bias > d) ? 1.0 : 0.0;
    }
}

vec3 BRDF_GGX(vec3 N, vec3 V, vec3 L, vec3 lightColor, float intensity,
              vec3 albedo, vec3 F0, float roughness, float metalness) {

    vec3 H = normalize(V + L);
    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), EPSILON); // Avoid division by zero
    float NdotH = max(dot(N, H), 0.0);
    float VdotH = max(dot(V, H), 0.0);

    if (NdotL <= 0.0) return vec3(0.0);

    float D = D_GGX(NdotH, roughness);
    float G = G_Smith(NdotV, NdotL, roughness);
    vec3  F = fresnelSchlick(VdotH, F0);

    vec3 spec = (D * G * F) / (4.0 * NdotV * NdotL + EPSILON);

    vec3 kd = (1.0 - F) * (1.0 - metalness);
    vec3 diff = kd * albedo / PI;

    return (diff + spec) * lightColor * intensity * NdotL;
}

// ===== PBR Light =====
vec3 calculatePointLight(vec3 pos, vec3 color, float range, float intensity, float decay, vec3 N, vec3 V, vec3 albedo, vec3 F0, float roughness, float metalness) {
    vec3 toL = pos - vWorldPosition;
    float d = length(toL);
    if (intensity <= 0.0 || (range > 0.0 && d > range)) return vec3(0.0);

    float att = 1.0 / (pow(d, decay) + EPSILON);
    if (range > 0.0) {
        att *= pow(clamp(1.0 - pow(d / range, 4.0), 0.0, 1.0), 2.0);
    }

    return BRDF_GGX(N, V, normalize(toL + vec3(EPSILON)), SRGBToLinear(color), intensity * att, albedo, F0, roughness, metalness);
}

// ===== Spot Light =====
vec3 calculateSpotLight(vec3 pos, vec3 dir, vec3 color, float range, float intensity, float decay, float angle, float penumbra, vec3 N, vec3 V, vec3 albedo, vec3 F0, float roughness, float metalness) {
    vec3 toL = pos - vWorldPosition;
    float d = length(toL);
    if (intensity <= 0.0 || (range > 0.0 && d > range)) return vec3(0.0);

    vec3 L = normalize(toL);
    float theta = dot(L, normalize(-dir));
    
    if (theta < angle) return vec3(0.0);

    float att = 1.0 / (pow(d, decay) + EPSILON);
    if (range > 0.0) {
        att *= pow(clamp(1.0 - pow(d / range, 4.0), 0.0, 1.0), 2.0);
    }

    float intensityFactor = 1.0;
    if (abs(penumbra - angle) > EPSILON) {
        intensityFactor = clamp((theta - angle) / (penumbra - angle), 0.0, 1.0);
    }
    att *= intensityFactor;

    return BRDF_GGX(N, V, L, SRGBToLinear(color), intensity * att, albedo, F0, roughness, metalness);
}

// ===== Tone Mapping =====
vec3 LinearToneMapping(vec3 color) {
    return color * u_ueToneMappingExposure;
}

vec3 ReinhardToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    return color / (1.0 + color);
}

vec3 CineonToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    color = max(vec3(0.0), color - 0.004);
    return (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
}

vec3 ACESFilmicToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// AgX Tone Mapping
vec3 AgXToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    const mat3 AgX_In = mat3(
        0.8424790622537815, 0.0423282422610123, 0.0429093763853347,
        0.0784351724105776, 0.8784686364697723, 0.0784314393537293,
        0.0792237451475514, 0.0791661274605167, 0.8784297143940141
    );
    color = AgX_In * color;
    color = clamp(log2(color + 1e-10), -10.0, 2.0);
    color = clamp((color + 10.0) / 12.0, 0.0, 1.0);
    color = color * color * (3.0 - 2.0 * color); // Cubic sigmoid
    const mat3 AgX_Out = mat3(
        1.1968790351201026, -0.0528968517574562, -0.0529716355144604,
        -0.0980208811401368, 1.1519031299041722, -0.0980434501171241,
        -0.099044710128318, -0.0989611756130454, 1.1510731034335441
    );
    return AgX_Out * color;
}

vec3 NeutralToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    const float startCompression = 0.8;
    const float desaturation = 0.15;
    float x = min(color.r, min(color.g, color.b));
    float offset = x < 0.08 ? x - 6.25 * x * x : 0.04 - 0.04 / (12.5 * x + 1.0);
    color -= offset;
    float peak = max(color.r, max(color.g, color.b));
    if (peak < startCompression) return color;
    float d = 1.0 - startCompression;
    float newPeak = 1.0 - d * d / (peak + d - startCompression);
    color *= newPeak / peak;
    float g = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
    return mix(color, vec3(newPeak), g);
}

void main() {

    // Base Albedo & Alpha
    vec4 tex = (u_ueHasMap > 0.5) ? texture2D(gm_BaseTexture, vTexcoord) : vec4(1.0);
    vec4 vCol = vColour;
    if (vCol.r + vCol.g + vCol.b < 0.001) vCol.rgb = vec3(1.0);
    if (vCol.a < 0.001) vCol.a = 1.0;
    
    vec4 base = tex * vCol;
    float alphaMap = (u_ueHasAlphaMap > 0.5) ? texture2D(s_alphaMap, vTexcoord).r : 1.0;
    float alpha = base.a * alphaMap;

    // Discard if transparent (for Opaque pass, we can use alpha testing)
    // if (alpha < 0.5) discard;

    vec3 albedo = SRGBToLinear(base.rgb * u_ueColor);

    // ORM Map
    vec3 orm = (u_ueHasOrmMap > 0.5) ? texture2D(s_ormMap, vTexcoord).rgb : vec3(1.0, 1.0, 0.0);
    float ao = mix(1.0, orm.r, u_ueAoIntensity * u_ueAoMapIntensity);
    float roughness = orm.g * u_ueRoughness;
    float metalness = orm.b * u_ueMetalness;

    // Normal Mapping
    vec3 N;
    if (u_ueFlatShading > 0.5) {
        N = normalize(cross(dFdx(vWorldPosition), dFdy(vWorldPosition)));
    } else {
        N = normalize(vWorldNormal);
    }

    vec3 normalMapSample = (u_ueHasNormalMap > 0.5) ? texture2D(s_normalMap, vTexcoord).rgb : vec3(0.5, 0.5, 1.0);
    vec3 nm = normalMapSample * 2.0 - 1.0;
    nm.xy *= u_ueNormalMapScale;
    
    // Safety check for normal map sampling
    if (length(nm) < 0.1) nm = vec3(0.0, 0.0, 1.0);
    
    // Tangent Space Normal Mapping
    mat3 TBN = calculateTBN(N, vWorldPosition, vTexcoord, vWorldTangent);
    N = normalize(TBN * nm);

    // Extract scene data
    vec3 _u_ueCameraPosition = u_ueSceneData[0].xyz;
    float _u_ueFogDensity = u_ueSceneData[0].w;
    vec3 u_ueAmbient = u_ueSceneData[1].xyz;
    float _u_ueFogNear = u_ueSceneData[1].w;
    vec3 u_ueFogColor = u_ueSceneData[2].xyz;
    float _u_ueFogFar = u_ueSceneData[2].w;
    vec3 u_ueDirLightDir0 = u_ueSceneData[3].xyz;
    float u_ueDirLightIntensity0 = u_ueSceneData[3].w;
    vec3 u_ueDirLightColor0 = u_ueSceneData[4].xyz;

    vec3 V = normalize(_u_ueCameraPosition - vWorldPosition + vec3(EPSILON));

    vec3 F0 = mix(vec3(0.04), albedo, metalness);

    vec3 Lo = vec3(0.0);

    // Directional 0
    {
        vec3 L = normalize(-u_ueDirLightDir0 + vec3(EPSILON));
        float shadow = 0.0;
        if (u_ueDirShadowEnabled > 0.5 && u_ueReceiveShadow > 0.5) {
            shadow = calculateDirShadow(vDirLightSpacePos, N, L);
        }
        Lo += BRDF_GGX(N, V, L, SRGBToLinear(u_ueDirLightColor0),
                       u_ueDirLightIntensity0, albedo, F0, roughness, metalness)
              * (1.0 - shadow);
    }

    // Point Lights
    for (int i = 0; i < 8; i++) {
        mat4 lp = u_uePointLightsData[i];
        vec3 pPos = lp[0].xyz;
        float pRange = lp[0].w;
        vec3 pColor = lp[1].xyz;
        float pIntensity = lp[1].w;
        float pDecay = lp[2].x;

        if (pIntensity <= 0.0) continue;

        float shadow = 0.0;
        if (i == 0 && u_uePointShadowEnabled > 0.5 && u_ueReceiveShadow > 0.5) {
            shadow = calculatePointShadow(vWorldPosition, N);
        }

        Lo += calculatePointLight(pPos, pColor, pRange, pIntensity, pDecay, N, V, albedo, F0, roughness, metalness)
              * (1.0 - shadow);
    }

    // Spot Lights
    for (int i = 0; i < 8; i++) {
        mat4 ls = u_ueSpotLightsData[i];
        vec3 sPos = ls[0].xyz;
        float sRange = ls[0].w;
        vec3 sColor = ls[1].xyz;
        float sIntensity = ls[1].w;
        vec3 sDir = ls[2].xyz;
        float sDecay = ls[2].w;
        float sAngle = ls[3].x;
        float sPenumbra = ls[3].y;

        if (sIntensity <= 0.0) continue;

        float shadow = 0.0;
        vec3 L = normalize(sPos - vWorldPosition);
        if (i == 0 && u_ueSpotShadowEnabled > 0.5 && u_ueReceiveShadow > 0.5) {
            shadow = calculateSpotShadow(vSpotLightSpacePos, N, L);
        }

        Lo += calculateSpotLight(sPos, sDir, sColor, sRange, sIntensity, sDecay, sAngle, sPenumbra, N, V, albedo, F0, roughness, metalness)
              * (1.0 - shadow);
    }

    // Ambient
    vec3 _ambient = u_ueAmbient * albedo * ao;

    // Hemisphere
    if (u_ueHemiLightIntensity > 0.0) {
        float hemiWeight = 0.5 * dot(N, u_ueHemiLightDirection) + 0.5;
        vec3 hemiColor = mix(SRGBToLinear(u_ueHemiLightGroundColor), SRGBToLinear(u_ueHemiLightSkyColor), hemiWeight);
        _ambient += hemiColor * u_ueHemiLightIntensity * albedo * ao;
    }

    // Emissive
    vec3 emissiveMapColor = (u_ueHasEmissiveMap > 0.5) ? SRGBToLinear(texture2D(s_emissiveMap, vTexcoord).rgb) : vec3(0.0);
    vec3 emissive = (emissiveMapColor + SRGBToLinear(u_ueEmissive)) * u_ueEmissiveIntensity;

    vec3 color = _ambient + Lo + emissive;

    // ===== Fog =====
    float dist = length(_u_ueCameraPosition - vWorldPosition);
    float fogFactor = 0.0;
    
    if (_u_ueFogDensity > 0.0) {
        // Exponential fog
        fogFactor = 1.0 - exp(-dist * _u_ueFogDensity);
    } else if (_u_ueFogFar > _u_ueFogNear) {
        // Linear fog
        fogFactor = clamp((dist - _u_ueFogNear) / (_u_ueFogFar - _u_ueFogNear), 0.0, 1.0);
    }
    
    color = mix(color, SRGBToLinear(u_ueFogColor), fogFactor);

    // Final color
    if (u_ueToneMapped > 0.5) {
        if (u_ueToneMapping == 1.0) color = LinearToneMapping(color);
        else if (u_ueToneMapping == 2.0) color = ReinhardToneMapping(color);
        else if (u_ueToneMapping == 3.0) color = CineonToneMapping(color);
        else if (u_ueToneMapping == 4.0) color = ACESFilmicToneMapping(color);
        else if (u_ueToneMapping == 5.0) color = AgXToneMapping(color);
        else if (u_ueToneMapping == 6.0) color = NeutralToneMapping(color);
    }

    gl_FragColor = vec4(LinearToSRGB(color), alpha);

    // Show normals (debug)
    // gl_FragColor = vec4(normalize(vWorldNormal) * 0.5 + 0.5, 1.0);
}
