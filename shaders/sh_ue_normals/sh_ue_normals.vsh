attribute vec3 in_Position;                  // (x,y,z)
attribute vec3 in_Normal;                    // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;

void main()
{
    vec4 worldPosition = gm_Matrices[MATRIX_WORLD] * vec4(in_Position.xyz, 1.0);
    v_vWorldPosition = worldPosition.xyz;
    v_vWorldNormal = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
    
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position.xyz, 1.0);
}
