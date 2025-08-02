varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

uniform vec3 u_ueAmbient;

// Directional Light 0
uniform vec3 u_ueDirLightDir0;
uniform vec3 u_ueDirLightColor0;
uniform float u_ueDirLightIntensity0;

// Directional Light 1
uniform vec3 u_ueDirLightDir1;
uniform vec3 u_ueDirLightColor1;
uniform float u_ueDirLightIntensity1;

// Point Light 0
uniform vec3 u_uePointLightPosition0;
uniform vec3 u_uePointLightRange0;
uniform vec3 u_uePointLightColor0;
uniform float u_uePointLightIntensity0;

// Point Light 1
uniform vec3 u_uePointLightPosition1;
uniform vec3 u_uePointLightRange1;
uniform vec3 u_uePointLightColor1;
uniform float u_uePointLightIntensity1;

// Emissive
uniform vec3 u_ueEmissive;
uniform float u_ueEmissiveIntensity;

// Textures
uniform sampler2D s_map;
uniform sampler2D s_emissiveMap;

// Gamma correction (sRGB to Linear color space)
#define GAMMA 2.2

vec3 SRGBToLinear(vec3 inputColor) {
    return pow(inputColor, vec3(GAMMA));
}

vec3 LinearToSRGB(vec3 inputColor) {
    return pow(inputColor, vec3(1.0 / GAMMA));
}

// Light functions
vec3 calculateDirectionalLight(vec3 lightDir, vec3 lightColor, float intensity, vec3 normal) {
    vec3 dir = -lightDir;
    float diff = max(dot(normal, dir), 0.0);
    return SRGBToLinear(lightColor) * diff * intensity;
}

vec3 calculatePointLight(vec3 lightPos, vec3 lightColor, float intensity, vec3 range, vec3 normal, vec3 fragPos) {
    vec3 toLight = lightPos - fragPos;
    float dist = length(toLight);
    vec3 lightDir = normalize(toLight);
    float diff = max(dot(normal, lightDir), 0.0);
    
    float attenuation = 1.0 / (1.0 + 0.1 * dist + 0.01 * dist * dist);
    attenuation *= 1.0 - clamp(dist / range.x, 0.0, 1.0);

    return SRGBToLinear(lightColor) * diff * attenuation * intensity;
}

void main() 
{
    // Base texture * vertex color
    vec4 baseColor = v_vColour * texture2D(s_map, v_vTexcoord);
    baseColor.rgb = SRGBToLinear(baseColor.rgb); // Convert to linear space

    vec3 normal = normalize(v_vWorldNormal);
    vec3 lighting = u_ueAmbient;

    // === Directional Light ===
    lighting += calculateDirectionalLight(u_ueDirLightDir0, u_ueDirLightColor0, u_ueDirLightIntensity0, normal);
    lighting += calculateDirectionalLight(u_ueDirLightDir1, u_ueDirLightColor1, u_ueDirLightIntensity1, normal);

    // === Point Light ===
    lighting += calculatePointLight(u_uePointLightPosition0, u_uePointLightColor0, u_uePointLightIntensity0, u_uePointLightRange0, normal, v_vWorldPosition);
    lighting += calculatePointLight(u_uePointLightPosition1, u_uePointLightColor1, u_uePointLightIntensity1, u_uePointLightRange1, normal, v_vWorldPosition);

    // === Final lit color ===
    vec3 litColor = baseColor.rgb * lighting;

    // === Emissive ===
    vec3 emissiveTex = texture2D(s_emissiveMap, v_vTexcoord).rgb;
    vec3 emissive = SRGBToLinear(emissiveTex + u_ueEmissive) * u_ueEmissiveIntensity;
    litColor += emissive;

    // === Tone mapping (reinhard) ===
    // @todo Should be configurable
    //litColor = litColor / (litColor + vec3(1.0));
    
    // === Back to sRGB color space ===
    vec3 finalColor = LinearToSRGB(clamp(litColor, 0.0, 1.0));
    
    gl_FragColor = vec4(finalColor, baseColor.a);
}
