attribute vec3 in_Position;
varying float v_dist;

uniform vec3 u_lightPos;

void main()
{
    vec4 worldPos = gm_Matrices[MATRIX_WORLD] * vec4(in_Position, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);
    v_dist = length(worldPos.xyz - u_lightPos);
}
