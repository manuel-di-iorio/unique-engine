/**
 * Spot Light Shadow Mapping Shader
 * This shader renders geometry depth from the perspective of a spot light. It transforms 
 * vertices into the light's view-projection space and outputs linearized depth to a 
 * shadow map texture.
 * Used by UeSpotLightShadow.
 */
attribute vec3 in_Position;
attribute vec4 in_TextureCoord2; // Bone Indices
attribute vec4 in_TextureCoord3; // Bone Weights

uniform mat4 uLightViewProj;
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

    gl_Position = uLightViewProj * worldPos;
}
