attribute vec3 in_Position;

uniform mat4 uLightViewProj;

void main()
{
    vec4 worldPos = gm_Matrices[MATRIX_WORLD] * vec4(in_Position, 1.0);
    gl_Position = uLightViewProj * worldPos;
}
