attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

uniform vec3 u_ueModelPosition;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    //gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    //
    //v_vColour = in_Colour;
    //v_vTexcoord = in_TextureCoord;
    //
    
    // Estrai le matrici utili
    mat4 viewMat = gm_Matrices[MATRIX_VIEW];
    mat4 worldViewProj = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION];

    vec3 right = vec3(viewMat[0][0], viewMat[1][0], viewMat[2][0]);
    vec3 up    = vec3(viewMat[0][1], viewMat[1][1], viewMat[2][1]);

    // Costruzione della posizione offset
    vec3 offset = in_Position.x * right + in_Position.y * up;
    vec3 worldPos = u_ueModelPosition + offset;

    // Proiezione finale
    v_vColour = in_Colour;
    gl_Position = worldViewProj * vec4(worldPos, 1.0);
    v_vTexcoord = in_TextureCoord;
}
