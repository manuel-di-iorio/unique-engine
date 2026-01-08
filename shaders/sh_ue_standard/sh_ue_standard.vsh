attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec2 in_TextureCoord0;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord1;
attribute vec2 in_TextureCoord2;

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec2 vTexcoord;
varying vec4 vColour;
varying vec4 vLightSpacePos;

uniform mat4 u_ueLightSpaceMatrix;

// Displacement (vertex only)
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

    vWorldPosition = worldPos.xyz;
    vWorldNormal   = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
    vTexcoord      = in_TextureCoord0;
    vColour        = in_Colour;

    vLightSpacePos = u_ueLightSpaceMatrix * worldPos;

    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 1.0);
}
