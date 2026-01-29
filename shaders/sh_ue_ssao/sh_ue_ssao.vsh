/**
 * SSAO Generation Shader
 * This shader calculates Screen Space Ambient Occlusion (SSAO). It reconstructs view-space positions 
 * from the depth buffer, generates a TBN matrix from normal and noise textures, and samples a 
 * hemispherical kernel to determine the occlusion factor for each pixel.
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
