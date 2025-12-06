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


void main() 
{
    vec3 normal = normalize(v_vWorldNormal);
    gl_FragColor = vec4(abs(normal), 1.0); return;
}
