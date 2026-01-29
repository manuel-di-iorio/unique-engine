/**
 * G-Buffer Generation Shader
 * This shader populates the G-Buffer for the deferred rendering pipeline. It handles 
 * skeletal skinning and displacement mapping to output world-space positions, normals, 
 * albedo, and material properties (Roughness, Metalness, AO) into multiple render targets.
 * Used by UeDeferredGBufferMaterial.
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

// Skinning
uniform float u_ueNumBones;
uniform mat4 u_ueBoneMatrices[128];

// Displacement
uniform sampler2D s_displacementMap;
uniform float u_ueDisplacementScale;
uniform float u_ueDisplacementBias;
uniform vec4 u_ueMapFlags2;
#define u_ueHasDisplacementMap u_ueMapFlags2.y

void main() {
    vec3 pos = in_Position;
    vec3 normal = in_Normal;
    vec3 tangent = in_TextureCoord1.xyz;

    // Skinning
    if (u_ueNumBones > 0.5) {
        ivec4 indices = ivec4(in_TextureCoord2 + 0.5);
        vec4 weights = in_TextureCoord3;
        
        mat4 skinMatrix = 
            u_ueBoneMatrices[indices.x] * weights.x +
            u_ueBoneMatrices[indices.y] * weights.y +
            u_ueBoneMatrices[indices.z] * weights.z +
            u_ueBoneMatrices[indices.w] * weights.w;
            
        pos = (skinMatrix * vec4(pos, 1.0)).xyz;
        normal = (skinMatrix * vec4(normal, 0.0)).xyz;
        tangent = (skinMatrix * vec4(tangent, 0.0)).xyz;
    }

    // Vertex displacement
    if (u_ueHasDisplacementMap > 0.5 && abs(u_ueDisplacementScale) > 0.0001) {
        float h = texture2D(s_displacementMap, in_TextureCoord0).r;
        pos += normal * (h * u_ueDisplacementScale + u_ueDisplacementBias);
    }

    vec4 worldPos;
    if (u_ueNumBones > 0.5) {
        worldPos = vec4(pos, 1.0);
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

    gl_Position = gm_Matrices[MATRIX_PROJECTION] * (gm_Matrices[MATRIX_VIEW] * worldPos);
}
