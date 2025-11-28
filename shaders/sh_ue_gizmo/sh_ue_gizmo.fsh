varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

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

void main() 
{
    // Base texture * vertex color
    vec4 baseColor = v_vColour;
    baseColor.rgb = SRGBToLinear(baseColor.rgb); // Convert to linear space

    vec3 normal = normalize(v_vWorldNormal);
    vec3 lighting = vec3(0.9);

    // === Directional Light ===
    lighting += calculateDirectionalLight(vec3(0.5), vec3(0.65), 1.0, normal);

    // === Final lit color ===
    vec3 litColor = baseColor.rgb * lighting;

    // === Back to sRGB color space ===
    vec3 finalColor = LinearToSRGB(clamp(litColor, 0.0, 1.0));
    
    gl_FragColor = vec4(finalColor, baseColor.a);
}
