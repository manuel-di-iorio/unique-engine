precision mediump float;

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec2 vTexcoord;
varying vec4 vColour;
varying vec4 vLightSpacePos;

// ===== Scene =====
uniform vec3  u_ueCameraPosition;
uniform vec3  u_ueAmbient;
uniform mat4  u_ueWorldMatrix;

// Fog
uniform vec3  u_ueFogColor;
uniform float u_ueFogDensity;
uniform float u_ueFogNear;
uniform float u_ueFogFar;

// ===== Material =====
uniform vec3  u_ueColor;
uniform float u_ueMetalness;
uniform float u_ueRoughness;
uniform vec3  u_ueEmissive;
uniform float u_ueEmissiveIntensity;
uniform float u_ueAoIntensity;
uniform float u_ueAoMapIntensity;
uniform float u_ueNormalMapType; // 0 = Tangent, 1 = Object
uniform vec2  u_ueNormalMapScale;
uniform float u_ueFlatShading;
uniform float u_ueBumpScale;
uniform float u_ueLightMapIntensity;
uniform float u_ueEnvMapIntensity;
uniform vec3  u_ueEnvMapRotation;

// ===== Textures =====
uniform sampler2D s_alphaMap;
uniform sampler2D s_metalnessMap;
uniform sampler2D s_roughnessMap;
uniform sampler2D s_aoMap;
uniform sampler2D s_normalMap;
uniform sampler2D s_emissiveMap;
// uniform sampler2D s_bumpMap;
// uniform sampler2D s_lightMap;
// uniform sampler2D s_envMap;

// ===== Lights =====
// Directional
uniform vec3  u_ueDirLightDir0;
uniform vec3  u_ueDirLightColor0;
uniform float u_ueDirLightIntensity0;

uniform vec3  u_ueDirLightDir1;
uniform vec3  u_ueDirLightColor1;
uniform float u_ueDirLightIntensity1;

// Point
uniform vec3  u_uePointLightPosition0;
uniform vec3  u_uePointLightColor0;
uniform float u_uePointLightIntensity0;
uniform vec3  u_uePointLightRange0;

uniform vec3  u_uePointLightPosition1;
uniform vec3  u_uePointLightColor1;
uniform float u_uePointLightIntensity1;
uniform vec3  u_uePointLightRange1;

// ===== Shadow =====
uniform sampler2D s_shadowMap;
uniform float u_ueShadowEnabled;
uniform float u_ueReceiveShadow;
uniform float u_ueShadowTexelSize;
uniform float u_ueShadowQuality;

// ===== Constants =====
#define PI 3.14159265359
#define GAMMA 2.2
#define EPSILON 1e-6

#extension GL_OES_standard_derivatives : enable

// ===== Color Space =====
vec3 SRGBToLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(GAMMA)); }
vec3 LinearToSRGB(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / GAMMA)); }

// ===== TBN (no precomputed tangents) =====
mat3 calculateTBN(vec3 N, vec3 pos, vec2 uv) {
    vec3 dp1 = dFdx(pos);
    vec3 dp2 = dFdy(pos);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);

    float det = (duv1.x * duv2.y - duv1.y * duv2.x);
    if (abs(det) < EPSILON) return mat3(vec3(1,0,0), vec3(0,1,0), N);

    vec3 T = normalize(dp1 * duv2.y - dp2 * duv1.y);
    vec3 B = normalize(dp2 * duv1.x - dp1 * duv2.x);

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

// ===== Shadow =====
vec2 getPoisson(int i) {
    if(i==0) return vec2(-0.94,-0.39);
    if(i==1) return vec2( 0.94,-0.76);
    if(i==2) return vec2(-0.09,-0.92);
    if(i==3) return vec2( 0.34, 0.29);
    return vec2(0.0);
}

float calculateShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
    if (lightSpacePos.w < EPSILON) return 0.0;
    vec3 p = lightSpacePos.xyz / lightSpacePos.w;
    p = p * 0.5 + 0.5;

    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0 || p.z > 1.0) return 0.0;

    float bias = max(0.002 * (1.0 - dot(N, L)), 0.0005);
    float shadow = 0.0;

    int samples = (u_ueShadowQuality > 0.5) ? 4 : 1;

    for (int i = 0; i < 4; i++) {
        if (i >= samples) break;
        vec2 off = getPoisson(i) * u_ueShadowTexelSize;
        float d = texture2D(s_shadowMap, p.xy + off).r;
        shadow += (p.z - bias > d) ? 1.0 : 0.0;
    }

    return shadow / float(samples);
}

// ===== PBR Light =====
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

void main() {

    // ===== Base =====
    vec4 tex = texture2D(gm_BaseTexture, vTexcoord);
    
    // Fallback if vertex color is black or transparent (often occurs if not provided)
    vec4 vCol = vColour;
    if (vCol.r + vCol.g + vCol.b < 0.001) vCol.rgb = vec3(1.0);
    if (vCol.a < 0.001) vCol.a = 1.0;
    
    vec4 base = tex * vCol;
    float alpha = base.a * texture2D(s_alphaMap, vTexcoord).r;
    //if (alpha < 0.01) discard;

    vec3 albedo = SRGBToLinear(base.rgb * u_ueColor);

    float metalness = texture2D(s_metalnessMap, vTexcoord).r * u_ueMetalness;
    float roughness = texture2D(s_roughnessMap, vTexcoord).r * u_ueRoughness;
    roughness = clamp(roughness, 0.04, 1.0);

     float ao = mix(1.0, texture2D(s_aoMap, vTexcoord).r, u_ueAoIntensity * u_ueAoMapIntensity);

    // ===== Normal =====
    vec3 N;
    if (u_ueFlatShading > 0.5) {
        N = normalize(cross(dFdx(vWorldPosition), dFdy(vWorldPosition)));
    } else {
        N = normalize(vWorldNormal);
    }

    vec3 nm = texture2D(s_normalMap, vTexcoord).rgb * 2.0 - 1.0;
    nm.xy *= u_ueNormalMapScale;
    
    // Safety check for normal map sampling
    if (length(nm) < 0.1) nm = vec3(0.0, 0.0, 1.0);
    
    if (u_ueNormalMapType > 0.5) {
        // Object Space
        N = normalize((u_ueWorldMatrix * vec4(nm, 0.0)).xyz);
    } else {
        // Tangent Space
        mat3 TBN = calculateTBN(N, vWorldPosition, vTexcoord);
        N = normalize(TBN * nm);
    }

    vec3 V = normalize(u_ueCameraPosition - vWorldPosition + vec3(EPSILON));

    vec3 F0 = mix(vec3(0.04), albedo, metalness);

    vec3 Lo = vec3(0.0);

    // Directional 0
    {
        vec3 L = normalize(-u_ueDirLightDir0 + vec3(EPSILON));
        float shadow = 0.0;
        if (u_ueShadowEnabled > 0.5 && u_ueReceiveShadow > 0.5) {
            shadow = calculateShadow(vLightSpacePos, N, L);
        }
        Lo += BRDF_GGX(N, V, L, SRGBToLinear(u_ueDirLightColor0),
                       u_ueDirLightIntensity0, albedo, F0, roughness, metalness)
              * (1.0 - shadow);
    }

    // Directional 1
    {
        vec3 L = normalize(-u_ueDirLightDir1 + vec3(EPSILON));
        Lo += BRDF_GGX(N, V, L, SRGBToLinear(u_ueDirLightColor1),
                       u_ueDirLightIntensity1, albedo, F0, roughness, metalness);
    }

    // Point 0
    {
        vec3 toL = u_uePointLightPosition0 - vWorldPosition;
        float d2 = dot(toL, toL);
        float d = sqrt(d2);
        float att = 1.0 / (d2 + EPSILON);
        att *= clamp(1.0 - d / max(u_uePointLightRange0.x, EPSILON), 0.0, 1.0);

        Lo += BRDF_GGX(N, V, normalize(toL + vec3(EPSILON)), SRGBToLinear(u_uePointLightColor0),
                       u_uePointLightIntensity0 * att, albedo, F0, roughness, metalness);
    }

    // Point 1
    {
        vec3 toL = u_uePointLightPosition1 - vWorldPosition;
        float d2 = dot(toL, toL);
        float d = sqrt(d2);
        float att = 1.0 / (d2 + EPSILON);
        att *= clamp(1.0 - d / max(u_uePointLightRange1.x, EPSILON), 0.0, 1.0);

        Lo += BRDF_GGX(N, V, normalize(toL + vec3(EPSILON)), SRGBToLinear(u_uePointLightColor1),
                       u_uePointLightIntensity1 * att, albedo, F0, roughness, metalness);
    }

    // Ambient
    vec3 ambient = SRGBToLinear(u_ueAmbient + vec3(0.05)) * albedo * ao;

    // Emissive
    vec3 emissive = (SRGBToLinear(texture2D(s_emissiveMap, vTexcoord).rgb)
                    + SRGBToLinear(u_ueEmissive)) * u_ueEmissiveIntensity;

    vec3 color = ambient + Lo + emissive;

    // ===== Fog =====
    float dist = length(u_ueCameraPosition - vWorldPosition);
    float fogFactor = 0.0;
    
    if (u_ueFogDensity > 0.0) {
        // Exponential fog
        fogFactor = 1.0 - exp(-dist * u_ueFogDensity);
    } else if (u_ueFogFar > u_ueFogNear) {
        // Linear fog
        fogFactor = clamp((dist - u_ueFogNear) / (u_ueFogFar - u_ueFogNear), 0.0, 1.0);
    }
    
    color = mix(color, SRGBToLinear(u_ueFogColor), fogFactor);

    gl_FragColor = vec4(LinearToSRGB(color), alpha);
    //gl_FragColor = vec4(texture2D(s_alphaMap, vTexcoord).rgb, 1.0);
}
