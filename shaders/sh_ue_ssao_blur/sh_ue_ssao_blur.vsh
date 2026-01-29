/**
 * SSAO Bilateral Blur Shader
 * This shader performs a spatial blur on the SSAO texture to reduce sampling noise.
 * It uses a multi-tap sampling approach to smooth the occlusion factor while attempting
 * to preserve important geometric edges.
 * Used by UeSSAOPass.
 */
attribute vec3 in_Position;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;

void main()
{
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
    v_vTexcoord = in_TextureCoord;
}
