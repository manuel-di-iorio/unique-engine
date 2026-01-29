/**
 * Normal View-Space Shader
 * This shader renders geometry normals transformed into view-space and encodes them into the RGB channels.
 * It is used to generate a normal buffer required for screen-space effects in forward rendering.
 * Used by UeSSAOPass for the normal pre-pass.
 */
attribute vec3 in_Position;
attribute vec3 in_Normal;

varying vec3 vViewNormal;

uniform mat4 uViewMatrix;

void main()
{
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
    
    // Normal in view space
    mat3 normalMatrix = mat3(gm_Matrices[MATRIX_WORLD_VIEW]);
    vViewNormal = normalize(normalMatrix * in_Normal);
}
