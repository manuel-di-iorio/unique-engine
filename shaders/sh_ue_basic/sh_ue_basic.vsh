attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

void main()
{
    vec4 worldPosition = gm_Matrices[MATRIX_WORLD] * vec4(in_Position.xyz, 1.0);
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    v_vNormal = in_Normal;
    
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
}
