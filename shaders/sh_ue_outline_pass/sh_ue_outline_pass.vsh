/**
 * Outline Post-Process Shader
 * This shader implements edge detection (Sobel) on a selection mask texture. It draws 
 * colored outlines around masked objects and blends them onto the final scene. It 
 * supports adjustable thickness, color, and optional G-Buffer normal enhancement.
 * Used by UeOutlinePass.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vTexcoord = in_TextureCoord;
}
