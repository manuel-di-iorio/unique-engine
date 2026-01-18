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
uniform mat4 u_ueBoneMatrices[64];

// Displacement
uniform sampler2D s_displacementMap;
uniform float u_ueDisplacementScale;
uniform float u_ueDisplacementBias;
uniform float u_ueHasDisplacementMap;

void main() {
    vec3 pos = in_Position;
    vec3 normal = in_Normal;
    vec3 tangent = in_TextureCoord1.xyz;

    // Skinning
    if (u_ueNumBones > 0.5) {
        ivec4 indices = ivec4(in_TextureCoord2 * 255.0 + 0.5);
        vec4 weights = in_TextureCoord3;
        
        
        vec4 skinnedPos = vec4(0.0);
        vec3 skinnedNormal = vec3(0.0);
        vec3 skinnedTangent = vec3(0.0);

        for (int i = 0; i < 4; ++i) {
            int idx = indices[i];
            float w = weights[i];
            if (w > 0.0) {
                mat4 m = u_ueBoneMatrices[idx];
                skinnedPos += (m * vec4(pos, 1.0)) * w;
                skinnedNormal += (mat3(m) * normal) * w;
                skinnedTangent += (mat3(m) * tangent) * w;
            }
        }

        pos = skinnedPos.xyz;
        normal = normalize(skinnedNormal);
        tangent = normalize(skinnedTangent);

    }

    // Vertex displacement
    if (u_ueHasDisplacementMap > 0.5 && abs(u_ueDisplacementScale) > 0.0001) {
        float h = texture2D(s_displacementMap, in_TextureCoord0).r;
        pos += normal * (h * u_ueDisplacementScale + u_ueDisplacementBias);
    }

    vec4 worldPos;
    if (u_ueNumBones > 0.5) {
        // worldPos = vec4(pos, 1.0);
        worldPos = gm_Matrices[MATRIX_WORLD] * vec4(pos, 1.0);
    } else {
        worldPos = gm_Matrices[MATRIX_WORLD] * vec4(pos, 1.0);
    }

    vWorldPosition  = worldPos.xyz;
    
    if (u_ueNumBones > 0.5) {
        vWorldNormal = normalize(normal);
        vWorldTangent.xyz = normalize(tangent);
    } else {
        vWorldNormal = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
        vWorldTangent.xyz = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_TextureCoord1.xyz, 0.0)).xyz);
    }
    
    vTexcoord       = in_TextureCoord0;
    vColour        = in_Colour;
    vWorldTangent.w   = in_TextureCoord1.w;

    vDirLightSpacePos = u_ueDirShadowMatrix * worldPos;
    
    // Apply a small normal bias to the spot light shadow position to prevent acne
    vec4 shadowWorldPos = worldPos;
    shadowWorldPos.xyz += vWorldNormal * 0.15;
    vSpotLightSpacePos = u_ueSpotShadowMatrix * shadowWorldPos;

    // gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 1.0);
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * (gm_Matrices[MATRIX_VIEW] * worldPos);
}
