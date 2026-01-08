attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec2 in_TextureCoord0; // UV
attribute vec4 in_TextureCoord1; // Tangent (xyz) + Handedness (w)
attribute vec4 in_Colour;

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec4 vWorldTangent;
varying vec2 vTexcoord;
varying vec4 vColour;
varying vec4 vLightSpacePos;

uniform mat4 u_ueLightSpaceMatrix;

// Displacement
uniform sampler2D s_displacementMap;
uniform float u_ueDisplacementScale;
uniform float u_ueDisplacementBias;
uniform float u_ueHasDisplacementMap;

void main() {
    vec3 pos = in_Position;

    // Vertex displacement (safe: default map = black)
    if (u_ueHasDisplacementMap > 0.5 && abs(u_ueDisplacementScale) > 0.0001) {
        float h = texture2D(s_displacementMap, in_TextureCoord0).r;
        pos += in_Normal * (h * u_ueDisplacementScale + u_ueDisplacementBias);
    }

    vec4 worldPos = gm_Matrices[MATRIX_WORLD] * vec4(pos, 1.0);

    vWorldPosition  = worldPos.xyz;
    vWorldNormal    = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
    
    vTexcoord       = in_TextureCoord0;
    vColour        = in_Colour;

    vWorldTangent.xyz = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_TextureCoord1.xyz, 0.0)).xyz);
    vWorldTangent.w   = in_TextureCoord1.w;

    vLightSpacePos = u_ueLightSpaceMatrix * worldPos;

    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 1.0);
}
