varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;
varying vec4 v_vLightSpacePos;

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

// Shadow mapping - Directional Light (semplificato)
uniform sampler2D s_shadowMap;
uniform float u_ueShadowEnabled;
uniform float u_ueReceiveShadow;
uniform float u_ueShadowQuality; // 0=LOW, 1=MEDIUM, 2=HIGH
uniform float u_ueShadowTexelSize; // 1.0 / shadowMapWidth

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
    float diff = max(dot(normal, lightDir), 0.0);
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

// Helper function to get Poisson disk sample (GLSL ES compatible)
vec2 getPoissonSample(int index) {
    // Poisson disk sampling pattern for soft shadows
    if(index == 0) return vec2(-0.94201624, -0.39906216);
    if(index == 1) return vec2(0.94558609, -0.76890725);
    if(index == 2) return vec2(-0.094184101, -0.92938870);
    if(index == 3) return vec2(0.34495938, 0.29387760);
    if(index == 4) return vec2(-0.91588581, 0.45771432);
    if(index == 5) return vec2(-0.81544232, -0.87912464);
    if(index == 6) return vec2(-0.38277543, 0.27676845);
    if(index == 7) return vec2(0.97484398, 0.75648379);
    if(index == 8) return vec2(0.44323325, -0.97511554);
    if(index == 9) return vec2(0.53742981, -0.47373420);
    if(index == 10) return vec2(-0.26496911, -0.41893023);
    if(index == 11) return vec2(0.79197514, 0.19090188);
    if(index == 12) return vec2(-0.24188840, 0.99706507);
    if(index == 13) return vec2(-0.81409955, 0.91437590);
    if(index == 14) return vec2(0.19984126, 0.78641367);
    return vec2(0.14383161, -0.14100790); // index 15 or default
}

// Shadow calculation with quality-based PCF
float calculateShadow(vec4 lightSpacePos, vec3 normal, vec3 lightDir) {
    vec3 projCoords = lightSpacePos.xyz / lightSpacePos.w;
    projCoords = projCoords * 0.5 + 0.5;

    // Check if outside shadow map
    if(projCoords.z > 1.0 || projCoords.x < 0.0 || projCoords.x > 1.0 || projCoords.y < 0.0 || projCoords.y > 1.0) return 0.0;
    
    float currentDepth = projCoords.z;
    
    // Dynamic bias based on surface angle (reduces shadow acne)
    float bias = max(0.002 * (1.0 - dot(normal, lightDir)), 0.0005);
    
    float shadow = 0.0;
    
    // Quality level determines sample count and softness
    int sampleCount = 1;      // LOW: hard shadows
    float shadowRadius = 0.0; // LOW: no blur
    
    if (u_ueShadowQuality > 1.5) {
        // HIGH: 16 samples, very soft shadows
        sampleCount = 16;
        shadowRadius = 1.5;
    } else if (u_ueShadowQuality > 0.5) {
        // MEDIUM: 4 samples, moderate softness
        sampleCount = 4;
        shadowRadius = 0.8;
    }
    
    // Perform PCF sampling
    for(int i = 0; i < 16; i++) {
        if (i >= sampleCount) break;
        
        vec2 offset = getPoissonSample(i) * u_ueShadowTexelSize * shadowRadius;
        float closestDepth = texture2D(s_shadowMap, projCoords.xy + offset).r;
        shadow += currentDepth - bias > closestDepth ? 1.0 : 0.0;
    }
    
    shadow /= float(sampleCount);
    
    return shadow;
}

void main() 
{
    // Base texture * vertex color
    vec4 baseColor = v_vColour * texture2D(s_map, v_vTexcoord);
    baseColor.rgb = SRGBToLinear(baseColor.rgb); // Convert to linear space

    vec3 normal = normalize(v_vWorldNormal);
    vec3 lighting = u_ueAmbient;

    // === Directional Light ===
    vec3 dirLight0 = calculateDirectionalLight(normalize(-u_ueDirLightDir0), u_ueDirLightColor0, u_ueDirLightIntensity0, normal);
    vec3 dirLight1 = calculateDirectionalLight(normalize(-u_ueDirLightDir1), u_ueDirLightColor1, u_ueDirLightIntensity1, normal);
    
    // Apply shadow to the first directional light
    if (u_ueShadowEnabled > 0.5 && u_ueReceiveShadow > 0.5) {
        vec3 lightDir = normalize(-u_ueDirLightDir0);
        float shadow = calculateShadow(v_vLightSpacePos, normal, lightDir);
        dirLight0 *= (1.0 - shadow);
        
        // DEBUG: Visualize depth comparison (comment out for production)
        // vec3 projCoords = v_vLightSpacePos.xyz / v_vLightSpacePos.w;
        // projCoords = projCoords * 0.5 + 0.5;
        // float closestDepth = texture2D(s_shadowMap, projCoords.xy).r;
        // float currentDepth = projCoords.z;
        // gl_FragColor = vec4(currentDepth, closestDepth, 0.0, 1.0); return;        
    }
    
    // DEBUG: Visualize light direction (uncomment to test)
    // gl_FragColor = vec4(dirLight0, 1.0); return;
    
    // DEBUG: Visualize dot product (green = lit, red = should be lit but isn't)
    // float rawDot = dot(normal, normalize(-u_ueDirLightDir0));
    // gl_FragColor = vec4(max(-rawDot, 0.0), max(rawDot, 0.0), 0.0, 1.0); return;               
    
    lighting += dirLight0;
    lighting += dirLight1;

    // === Point Light ===
    vec3 pointLight0 = calculatePointLight(u_uePointLightPosition0, u_uePointLightColor0, u_uePointLightIntensity0, u_uePointLightRange0, normal, v_vWorldPosition);
    vec3 pointLight1 = calculatePointLight(u_uePointLightPosition1, u_uePointLightColor1, u_uePointLightIntensity1, u_uePointLightRange1, normal, v_vWorldPosition);
    
    lighting += pointLight0;
    lighting += pointLight1;

    // === Final lit color ===
    vec3 litColor = baseColor.rgb * lighting;

    // === Emissive ===
    vec3 emissiveTex = texture2D(s_emissiveMap, v_vTexcoord).rgb;
    vec3 emissive = SRGBToLinear(emissiveTex + u_ueEmissive) * u_ueEmissiveIntensity;
    litColor += emissive;

    // === Back to sRGB color space ===
    vec3 finalColor = LinearToSRGB(clamp(litColor, 0.0, 1.0));
    
    // DEBUG: Visualize world normals (R=X, G=Y, B=Z)
    //gl_FragColor = vec4(abs(normal), 1.0); return;
    
    // DEBUG: Visualize light direction as RGB (signed, remapped to 0-1)
    //vec3 lightDir = normalize(-u_ueDirLightDir0);
    //gl_FragColor = vec4(lightDir * 0.5 + 0.5, 1.0); return;
    
    gl_FragColor = vec4(finalColor, baseColor.a);
}
