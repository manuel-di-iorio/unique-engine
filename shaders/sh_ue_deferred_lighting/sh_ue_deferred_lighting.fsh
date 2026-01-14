precision highp float;

varying vec2 vTexcoord;

// ===== G-Buffer Samplers =====
uniform sampler2D s_gbufferAlbedo;
uniform sampler2D s_gbufferNormal;
uniform sampler2D s_gbufferPosition;
uniform sampler2D s_gbufferORM;

// ===== Scene =====
uniform vec3  u_ueCameraPosition;
uniform vec3  u_ueAmbient;

// Fog
uniform vec3  u_ueFogColor;
uniform float u_ueFogDensity;
uniform float u_ueFogNear;
uniform float u_ueFogFar;

// ===== Lights =====
// Directional
uniform vec3  u_ueDirLightDir0;
uniform vec3  u_ueDirLightColor0;
uniform float u_ueDirLightIntensity0;

// Point
uniform vec3  u_uePointLightPosition[8];
uniform vec3  u_uePointLightColor[8];
uniform float u_uePointLightRange[8];
uniform float u_uePointLightIntensity[8];
uniform float u_uePointLightDecay[8];

// Spot
uniform vec3  u_ueSpotLightPosition[4];
uniform vec3  u_ueSpotLightDirection[4];
uniform vec3  u_ueSpotLightColor[4];
uniform float u_ueSpotLightRange[4];
uniform float u_ueSpotLightIntensity[4];
uniform float u_ueSpotLightDecay[4];
uniform float u_ueSpotLightAngle[4];
uniform float u_ueSpotLightPenumbra[4];

// Hemisphere
uniform vec3  u_ueHemiLightDirection;
uniform vec3  u_ueHemiLightSkyColor;
uniform vec3  u_ueHemiLightGroundColor;
uniform float u_ueHemiLightIntensity;

// ===== Shadow =====
uniform sampler2D s_dirShadowMap;
uniform sampler2D s_pointShadowMap;
uniform sampler2D s_spotShadowMap;

uniform mat4  u_ueDirShadowMatrix;
uniform mat4  u_ueSpotShadowMatrix;

uniform float u_ueDirShadowEnabled;
uniform float u_uePointShadowEnabled;
uniform float u_ueSpotShadowEnabled;
uniform float u_ueReceiveShadow;
uniform float u_ueDirShadowInvTexelSize;
uniform vec2  u_uePointShadowInvTexelSize;
uniform float u_ueSpotShadowInvTexelSize;
uniform float u_ueDirShadowQuality;
uniform float u_uePointShadowQuality;
uniform float u_ueSpotShadowQuality;

uniform float u_uePointShadowFar;
uniform float u_uePointShadowNear;
uniform vec3  u_uePointShadowPos;
uniform mat4  u_uePointShadowMatrix[6];

uniform float u_ueSpotShadowFar;
uniform float u_ueSpotShadowNear;
uniform vec3  u_ueSpotShadowPos;

uniform float u_ueToneMapping;
uniform float u_ueToneMappingExposure;
uniform float u_ueToneMapped;

// ===== Constants =====
#define PI 3.14159265359
#define GAMMA 2.2
#define EPSILON 1e-6

// ===== Color Space =====
vec3 SRGBToLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(GAMMA)); }
vec3 LinearToSRGB(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / GAMMA)); }

float LinearizeDepth(float depth, float zparam) { 
    return 1.0 / ((1.0 - zparam) * (depth * 2.0 - 1.0) + zparam); 
}

// ===== GGX & PBR Logic (same as sh_ue_standard) =====
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
    return G_SchlickGGX(NdotV, roughness) * G_SchlickGGX(NdotL, roughness);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 BRDF_GGX(vec3 N, vec3 V, vec3 L, vec3 lightColor, float intensity,
              vec3 albedo, vec3 F0, float roughness, float metalness) {
    vec3 H = normalize(V + L);
    float NdotL = max(dot(N, L), 0.0);
    float NdotV = max(dot(N, V), EPSILON);
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

// Shadow calculation functions (same as sh_ue_standard)
float calculateDirShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
    if (lightSpacePos.w < EPSILON) return 0.0;
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    p = p * 0.5 + 0.5;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 0.0;
    float bias = max(0.0015 * (1.0 - dot(N, L)), 0.0004);
    if (u_ueDirShadowQuality > 0.5) {
        float texelSize = u_ueDirShadowInvTexelSize;
        float shadow = 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2(-0.7, -0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2( 0.7, -0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2(-0.7,  0.7) * texelSize).r) ? 1.0 : 0.0;
        shadow += (p.z - bias > texture2D(s_dirShadowMap, p.xy + vec2( 0.7,  0.7) * texelSize).r) ? 1.0 : 0.0;
        return shadow / 5.0;
    }
    return (p.z - bias > texture2D(s_dirShadowMap, p.xy).r) ? 1.0 : 0.0;
}

float calculatePointShadow(vec3 worldPos, vec3 N) {
    vec3 L = normalize(worldPos - u_uePointShadowPos);
    float NdotL = max(dot(N, -L), 0.0);
    float normalBias = mix(0.02, 0.005, NdotL);
    vec3 shadowPos = worldPos + N * normalBias;
    vec3 dir = shadowPos - u_uePointShadowPos;
    float absX = abs(dir.x), absY = abs(dir.y), absZ = abs(dir.z);
    int faceIndex;
    if (absY >= absX && absY >= absZ) faceIndex = (dir.y < 0.0) ? 2 : 3;
    else faceIndex = (dir.x < 0.0) ? 4 : 5;
    vec4 lightSpacePos = u_uePointShadowMatrix[faceIndex] * vec4(shadowPos, 1.0);
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    p = p * 0.5 + 0.5;
    p.y = 1.0 - p.y;
    if (p.z > 1.0 || p.z < 0.0) return 0.0;
    int col = faceIndex - (faceIndex / 3) * 3, row = faceIndex / 3;
    vec2 tileMin = vec2(float(col) / 3.0, float(row) / 2.0);
    vec2 tileMax = tileMin + vec2(1.0 / 3.0, 1.0 / 2.0);
    vec2 texelSize = u_uePointShadowInvTexelSize;
    vec2 margin = texelSize * 1.5;
    vec2 tMin = tileMin + margin, tMax = tileMax - margin;
    vec2 uv = tileMin + p.xy * vec2(1.0 / 3.0, 1.0 / 2.0);
    float currentDepth = (length(shadowPos - u_uePointShadowPos) - u_uePointShadowNear) / (u_uePointShadowFar - u_uePointShadowNear);
    float bias = max(0.01 * (1.0 - NdotL), 0.002);
    if (u_uePointShadowQuality > 0.5) {
        float shadow = 0.0;
        vec2 offsets[5];
        offsets[0] = vec2(0,0); offsets[1] = vec2(-1,-1); offsets[2] = vec2(1,-1); offsets[3] = vec2(-1,1); offsets[4] = vec2(1,1);
        for (int i = 0; i < 5; i++) {
            shadow += (currentDepth - bias > texture2D(s_pointShadowMap, clamp(uv + offsets[i] * texelSize, tMin, tMax)).r) ? 1.0 : 0.0;
        }
        return shadow / 5.0;
    }
    return (currentDepth - bias > texture2D(s_pointShadowMap, clamp(uv, tMin, tMax)).r) ? 1.0 : 0.0;
}

float calculateSpotShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
    if (lightSpacePos.w < EPSILON) return 0.0;
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    p.xy = p.xy * 0.5 + 0.5; p.y = 1.0 - p.y;
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z < 0.0 || p.z > 1.0) return 0.0;
    float zparam = u_ueSpotShadowFar / u_ueSpotShadowNear;
    float currentDepth = LinearizeDepth(p.z, zparam);
    float bias = max(0.005 * (1.0 - clamp(dot(N, L), 0.0, 1.0)), 0.001);
    if (u_ueSpotShadowQuality > 0.5) {
        float texelSize = u_ueSpotShadowInvTexelSize;
        float shadow = 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2(-0.7, -0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2( 0.7, -0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2(-0.7,  0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        shadow += (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy + vec2( 0.7,  0.7) * texelSize).r, zparam)) ? 1.0 : 0.0;
        return shadow / 5.0;
    }
    return (currentDepth - bias > LinearizeDepth(texture2D(s_spotShadowMap, p.xy).r, zparam)) ? 1.0 : 0.0;
}

// Tone Mapping functions (same as sh_ue_standard)
vec3 LinearToneMapping(vec3 color) {
    return color * u_ueToneMappingExposure;
}

vec3 ReinhardToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    return color / (vec3(1.0) + color);
}

vec3 CineonToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    color = max(vec3(0.0), color - 0.004);
    return pow((color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06), vec3(2.2));
}

vec3 ACESFilmicToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    return clamp((color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14), 0.0, 1.0);
}

vec3 AgXToneMapping(vec3 color) {
    color *= u_ueToneMappingExposure;
    const mat3 AgXInputMatrix = mat3(
        0.8424790622, 0.0423282422, 0.042375654,
        0.0784351618, 0.8784686364, 0.0784314393,
        0.0792237451, 0.0791661274, 0.8791429737
    );
    const mat3 AgXOutputMatrix = mat3(
        1.1968790059, -0.0528968517, -0.0529716355,
        -0.0980208811, 1.1519031299, -0.0980434501,
        -0.099029744, -0.0989611761, 1.1510736126
    );
    vec3 x = AgXInputMatrix * color;
    x = clamp((log2(max(x, 1e-10)) + 12.47393) / 16.53692, 0.0, 1.0);
    vec3 val = x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
    return AgXOutputMatrix * val;
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
    // Read from G-Buffer
    vec4 gAlbedo = texture2D(s_gbufferAlbedo, vTexcoord);
    if (gAlbedo.a < 0.1) discard; // Sky or background

    vec4 gNormal = texture2D(s_gbufferNormal, vTexcoord);
    vec4 gPos = texture2D(s_gbufferPosition, vTexcoord);
    vec4 gORM = texture2D(s_gbufferORM, vTexcoord);

    vec3 albedo = SRGBToLinear(gAlbedo.rgb);
    vec3 N = normalize(gNormal.rgb * 2.0 - 1.0);
    vec3 worldPos = gPos.rgb;
    float metalness = gNormal.a;
    float roughness = gPos.a;
    vec3 emissive = gORM.rgb;
    
    // Decode AO and receiveShadow
    float rawAO = gORM.a;
    float receiveShadow = 1.0;
    float ao = rawAO;
    if (rawAO < 0.0) {
        receiveShadow = 0.0;
        ao = abs(rawAO) - 0.001;
    }
    ao = clamp(ao, 0.0, 1.0);

    vec3 V = normalize(u_ueCameraPosition - worldPos + vec3(EPSILON));
    vec3 F0 = mix(vec3(0.04), albedo, metalness);
    vec3 Lo = vec3(0.0);

    // Directional Light
    {
        vec3 L = normalize(-u_ueDirLightDir0 + vec3(EPSILON));
        float shadow = 0.0;
        if (u_ueDirShadowEnabled > 0.5 && receiveShadow > 0.5) {
            shadow = calculateDirShadow(u_ueDirShadowMatrix * vec4(worldPos, 1.0), N, L);
        }
        Lo += BRDF_GGX(N, V, L, SRGBToLinear(u_ueDirLightColor0), u_ueDirLightIntensity0, albedo, F0, roughness, metalness) * (1.0 - shadow);
    }

    // Point Lights
    for (int i = 0; i < 8; i++) {
        if (u_uePointLightIntensity[i] <= 0.0) continue;
        vec3 toL = u_uePointLightPosition[i] - worldPos;
        float d = length(toL);
        if (u_uePointLightRange[i] > 0.0 && d > u_uePointLightRange[i]) continue;
        float att = 1.0 / (pow(d, u_uePointLightDecay[i]) + EPSILON);
        if (u_uePointLightRange[i] > 0.0) att *= pow(clamp(1.0 - pow(d / u_uePointLightRange[i], 4.0), 0.0, 1.0), 2.0);
        
        float shadow = 0.0;
        if (i == 0 && u_uePointShadowEnabled > 0.5 && receiveShadow > 0.5) {
            shadow = calculatePointShadow(worldPos, N);
        }
        Lo += BRDF_GGX(N, V, normalize(toL + vec3(EPSILON)), SRGBToLinear(u_uePointLightColor[i]), u_uePointLightIntensity[i] * att, albedo, F0, roughness, metalness) * (1.0 - shadow);
    }

    // Spot Lights
    for (int i = 0; i < 4; i++) {
        if (u_ueSpotLightIntensity[i] <= 0.0) continue;
        vec3 toL = u_ueSpotLightPosition[i] - worldPos;
        float d = length(toL);
        if (u_ueSpotLightRange[i] > 0.0 && d > u_ueSpotLightRange[i]) continue;
        vec3 L = normalize(toL);
        float theta = dot(L, normalize(-u_ueSpotLightDirection[i]));
        if (theta < u_ueSpotLightAngle[i]) continue;
        float att = 1.0 / (pow(d, u_ueSpotLightDecay[i]) + EPSILON);
        if (u_ueSpotLightRange[i] > 0.0) att *= pow(clamp(1.0 - pow(d / u_ueSpotLightRange[i], 4.0), 0.0, 1.0), 2.0);
        float intensityFactor = 1.0;
        if (abs(u_ueSpotLightPenumbra[i] - u_ueSpotLightAngle[i]) > EPSILON) intensityFactor = clamp((theta - u_ueSpotLightAngle[i]) / (u_ueSpotLightPenumbra[i] - u_ueSpotLightAngle[i]), 0.0, 1.0);
        att *= intensityFactor;

        float shadow = 0.0;
        if (i == 0 && u_ueSpotShadowEnabled > 0.5 && receiveShadow > 0.5) {
            vec4 shadowWorldPos = vec4(worldPos + N * 0.15, 1.0);
            shadow = calculateSpotShadow(u_ueSpotShadowMatrix * shadowWorldPos, N, L);
        }
        Lo += BRDF_GGX(N, V, L, SRGBToLinear(u_ueSpotLightColor[i]), u_ueSpotLightIntensity[i] * att, albedo, F0, roughness, metalness) * (1.0 - shadow);
    }

    // Ambient & Hemisphere
    vec3 ambient = SRGBToLinear(u_ueAmbient + vec3(0.05)) * albedo * ao;
    if (u_ueHemiLightIntensity > 0.0) {
        float hemiWeight = 0.5 * dot(N, u_ueHemiLightDirection) + 0.5;
        vec3 hemiColor = mix(SRGBToLinear(u_ueHemiLightGroundColor), SRGBToLinear(u_ueHemiLightSkyColor), hemiWeight);
        ambient += hemiColor * u_ueHemiLightIntensity * albedo * ao;
    }

    vec3 color = ambient + Lo + emissive;

    // Fog
    float dist = length(u_ueCameraPosition - worldPos);
    float fogFactor = (u_ueFogDensity > 0.0) ? (1.0 - exp(-dist * u_ueFogDensity)) : (u_ueFogFar > u_ueFogNear ? clamp((dist - u_ueFogNear) / (u_ueFogFar - u_ueFogNear), 0.0, 1.0) : 0.0);
    color = mix(color, SRGBToLinear(u_ueFogColor), fogFactor);

    // Final Tone Mapping
    if (u_ueToneMapped > 0.5) {
        if (u_ueToneMapping == 1.0) color = LinearToneMapping(color);
        else if (u_ueToneMapping == 2.0) color = ReinhardToneMapping(color);
        else if (u_ueToneMapping == 3.0) color = CineonToneMapping(color);
        else if (u_ueToneMapping == 4.0) color = ACESFilmicToneMapping(color);
        else if (u_ueToneMapping == 5.0) color = AgXToneMapping(color);
        else if (u_ueToneMapping == 6.0) color = NeutralToneMapping(color);
    }

    gl_FragColor = vec4(LinearToSRGB(color), 1.0);
}
