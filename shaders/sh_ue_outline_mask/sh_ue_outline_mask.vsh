/**
 * Selection Mask Shader
 * This shader renders object silhouettes as solid white colors. It is used to create 
 * a selection mask on a separate surface, which serves as the input for the final 
 * edge-detection outline post-process.
 * Used by UeOutlinePass.
 */
attribute vec3 in_Position;

void main()
{
    vec4 object_space_pos = vec4(in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
}
