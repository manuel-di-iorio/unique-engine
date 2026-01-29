/**
 * Text Rendering Shader
 * This shader is responsible for rendering font glyphs. It transforms text geometry 
 * into screen or world space and applies color tinting and alpha transparency from 
 * the font texture in the fragment stage.
 * Used by oSceneText for in-game labels.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;            // (u,v)
attribute vec4 in_Colour;                  // (r,g,b,a)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
