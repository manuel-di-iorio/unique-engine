/**
 * SSAO Combine Shader
 * This shader is the final composition pass for SSAO. It samples the original scene texture 
 * and the calculated AO texture, then multiplies the scene's color by the occlusion factor 
 * based on the specified intensity.
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
