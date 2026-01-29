/**
 * Depth Restoration Shader
 * A utility shader used to reconstruct or fill the depth buffer from a depth texture. 
 * By rendering a full-screen quad with depth testing and writing enabled, it allows 
 * the engine to restore depth state between different rendering passes.
 * Used by UeRenderer.
 */
attribute vec3 in_Position;

void main() {
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
}
