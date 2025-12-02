// Vertex shader for shadow map generation
// This shader only outputs depth information (distance from light)

attribute vec3 in_Position;                  // (x,y,z)

void main()
{
    // Transform vertex to clip space using world-view-projection matrix
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
}
