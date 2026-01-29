/**
 * 3D Sprite Shader
 * This shader is used for rendering 2D sprites within a 3D environment. It handles 
 * world-space transformations for the sprite geometry and supports basic texture mapping 
 * and color tinting.
 * Used by UeSpriteMaterial.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)
attribute vec4 in_TextureCoord1;             // (tangent)
attribute vec4 in_Colour;                    // (r,g,b,a)

uniform vec3 u_ueModelPosition;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    mat4 modelMat = gm_Matrices[MATRIX_WORLD];
    mat4 viewMat = gm_Matrices[MATRIX_VIEW];
    mat4 projMat = gm_Matrices[MATRIX_PROJECTION];
    
    // Estrai la scala come modulo dei vettori colonna (ignora la rotazione)
    float scaleX = length(vec3(modelMat[0][0], modelMat[1][0], modelMat[2][0]));
    float scaleY = length(vec3(modelMat[0][1], modelMat[1][1], modelMat[2][1]));
    
    // Usa i vettori della view matrix per orientare il quad verso la camera
    vec3 right = normalize(vec3(viewMat[0][0], viewMat[1][0], viewMat[2][0]));
    vec3 up    = normalize(vec3(viewMat[0][1], viewMat[1][1], viewMat[2][1]));
    
    // Calcola offset
    vec3 offset = in_Position.x * scaleX * right + in_Position.y * scaleY * up;
    
    // Componi la posizione finale
    vec4 finalWorld = vec4(u_ueModelPosition  + offset, 1.0);
    gl_Position = projMat * viewMat * finalWorld;

    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
