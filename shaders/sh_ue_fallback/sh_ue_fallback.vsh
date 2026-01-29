/**
 * Fallback/Error Shader
 * This is a safety shader that renders objects in a solid magenta color. It is 
 * automatically used by the engine when a material's primary shader is missing or 
 * fails to compile, providing a clear visual indicator of a technical error.
 * Used globally as a fallback mechanism.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
}
