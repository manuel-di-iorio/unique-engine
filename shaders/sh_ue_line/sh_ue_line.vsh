/**
 * Line Rendering Shader
 * A simple shader designed for rendering line primitives and wireframe geometry. 
 * It combines vertex colors with a uniform color multiplier to output a final solid color.
 * Used by UeLineBasicMaterial.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)

varying vec4 v_vColour;

void main()
{
    vec4 worldPosition = gm_Matrices[MATRIX_WORLD] * vec4(in_Position.xyz, 1.0);
    
    v_vColour = in_Colour;
    
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
}
