/**
 * Standard PBR Shader
 * This is the main Physically Based Rendering (PBR) shader for forward rendering. 
 * It handles skeletal skinning, displacement mapping, and TBN matrix generation in the vertex stage. 
 * The fragment stage implements the GGX/Cook-Torrance reflectance model for multiple light sources 
 * (directional, point, spot, and hemisphere), including shadow mapping, fog, and tone mapping.
 * Used by UeMeshStandardMaterial.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec2 in_TextureCoord0;             // (u,v)
attribute vec4 in_TextureCoord1;             // (tangent.xyz, handedness.w)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec4 in_TextureCoord2;             // Bone Indices
attribute vec4 in_TextureCoord3;             // Bone Weights

varying vec3 vWorldPosition;
varying vec3 vWorldNormal;
varying vec4 vWorldTangent;
varying vec2 vTexcoord;
varying vec4 vColour;
varying vec4 vDirLightSpacePos;
varying vec4 vSpotLightSpacePos;

uniform mat4 u_ueDirShadowMatrix;
uniform mat4 u_ueSpotShadowMatrix;

// Uniforms
uniform float u_ueNumBones;
uniform mat4 u_ueBoneMatrices[128];

// Displacement
uniform sampler2D s_displacementMap;
uniform float u_ueDisplacementScale;
uniform float u_ueDisplacementBias;
uniform float u_ueHasDisplacementMap;

void main() {
    vec4 localPos = vec4(in_Position, 1.0);
    vec3 localNormal = in_Normal;
    vec3 localTangent = in_TextureCoord1.xyz;

    vec4 worldPos;
    vec3 worldNormal;
    vec3 worldTangent;

    // Skinning
    if (u_ueNumBones > 0.5) {
        ivec4 indices = ivec4(in_TextureCoord2 + 0.5);
        vec4 weights = in_TextureCoord3;
                
        worldPos = vec4(0.0);
        worldNormal = vec3(0.0);
        worldTangent = vec3(0.0);

        for (int i = 0; i < 4; ++i) {
            float w = weights[i];
            if (w > 0.0) {
                mat4 m = u_ueBoneMatrices[indices[i]];
                worldPos += (m * localPos) * w;
                mat3 m3 = mat3(m);
                worldNormal += (m3 * localNormal) * w;
                worldTangent += (m3 * localTangent) * w;
            }
        }
        worldNormal = normalize(worldNormal);
        worldTangent = normalize(worldTangent);
    } else {
        worldPos = gm_Matrices[MATRIX_WORLD] * localPos;
        mat3 worldMat3 = mat3(gm_Matrices[MATRIX_WORLD]);
        worldNormal = normalize(worldMat3 * localNormal);
        worldTangent = normalize(worldMat3 * localTangent);
    }

    // Vertex displacement
    if (u_ueHasDisplacementMap > 0.5 && abs(u_ueDisplacementScale) > 0.0001) {
        float h = texture2D(s_displacementMap, in_TextureCoord0).r;
        worldPos.xyz += worldNormal * (h * u_ueDisplacementScale + u_ueDisplacementBias);
    }

    vWorldPosition = worldPos.xyz;
    vWorldNormal = worldNormal;
    vWorldTangent = vec4(worldTangent, in_TextureCoord1.w);
    vTexcoord = in_TextureCoord0;
    vColour = in_Colour;

    vDirLightSpacePos = u_ueDirShadowMatrix * worldPos;
    
    // Apply a small normal bias to the spot light shadow position to prevent acne
    vec4 shadowWorldPos = worldPos;
    shadowWorldPos.xyz += worldNormal * 0.15;
    vSpotLightSpacePos = u_ueSpotShadowMatrix * shadowWorldPos;

    gl_Position = gm_Matrices[MATRIX_PROJECTION] * (gm_Matrices[MATRIX_VIEW] * worldPos);
}
