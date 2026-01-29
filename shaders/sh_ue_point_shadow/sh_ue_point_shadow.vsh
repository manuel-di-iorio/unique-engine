/**
 * Point Light Shadow Mapping Shader
 * This shader renders geometry depth for one of the six faces of a point light's cubemap. 
 * It transforms vertices into the appropriate light-space for the current face and 
 * calculates linearized depth for the shadow map.
 * Used by UePointLightShadow.
 */
attribute vec3 in_Position;
attribute vec4 in_TextureCoord2; // Bone Indices
attribute vec4 in_TextureCoord3; // Bone Weights

varying float v_dist;

uniform vec3 u_lightPos;
uniform float u_ueNumBones;
uniform mat4 u_ueBoneMatrices[128];

void main()
{
    vec3 pos = in_Position;

    if (u_ueNumBones > 0.5) {
        ivec4 indices = ivec4(in_TextureCoord2 + 0.5);
        vec4 weights = in_TextureCoord3;
        vec4 skinnedPos = vec4(0.0);

        for (int i = 0; i < 4; ++i) {
            float w = weights[i];
            if (w > 0.0) {
                skinnedPos += (u_ueBoneMatrices[indices[i]] * vec4(pos, 1.0)) * w;
            }
        }
        pos = skinnedPos.xyz;
    }

    vec4 worldPos;
    if (u_ueNumBones > 0.5) {
        worldPos = vec4(pos, 1.0);
    } else {
        worldPos = gm_Matrices[MATRIX_WORLD] * vec4(pos, 1.0);
    }
    
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 1.0);
    v_dist = length(worldPos.xyz - u_lightPos);
}
