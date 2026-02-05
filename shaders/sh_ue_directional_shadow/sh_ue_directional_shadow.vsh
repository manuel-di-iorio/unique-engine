/**
 * Directional Light Shadow Mapping Shader
 * This shader renders geometry depth from the perspective of a directional light. It uses 
 * an orthographic projection to transform vertices into light-space and stores the 
 * linearized depth in a shadow map for global lighting.
 * Used by UeDirectionalLightShadow.
 */
attribute vec3 in_Position;
attribute vec2 in_TextureCoord0;
attribute vec4 in_TextureCoord2; // Bone Indices
attribute vec4 in_TextureCoord3; // Bone Weights

varying float v_depth;
varying vec2 v_vTexcoord;

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

    vec4 clip = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(pos, 1.0);
    gl_Position = clip;

    float ndc = clip.z / clip.w;    
    v_depth = ndc * 0.5 + 0.5; 
    v_vTexcoord = in_TextureCoord0;
}
