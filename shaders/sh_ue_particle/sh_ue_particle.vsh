attribute vec3 in_Position;                  // (x,y,z) center position
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)
attribute vec3 in_Normal;                    // size, rotation, 0
// attribute vec4 in_TextureCoord1;          // Not needed anymore

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec4 v_vShadowCoord;
varying float v_vDepth;

uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;
uniform mat4 u_ueDirShadowMatrix;

void main()
{
    float size = in_Normal.x;
    float rotation = in_Normal.y;
    
    // Determine corner offset based on UV
    // UV (0,0) -> (-0.5,  0.5)
    // UV (1,0) -> ( 0.5,  0.5)
    // UV (0,1) -> (-0.5, -0.5)
    // UV (1,1) -> ( 0.5, -0.5)
    vec2 corner = vec2(in_TextureCoord.x - 0.5, 0.5 - in_TextureCoord.y);

    // Rotate the corner
    float cosR = cos(rotation);
    float sinR = sin(rotation);
    vec2 rotatedCorner = vec2(
        corner.x * cosR - corner.y * sinR,
        corner.x * sinR + corner.y * cosR
    );

    // Calculate billboard world position
    vec3 worldPos = in_Position.xyz;
    worldPos += u_ueCameraRight * rotatedCorner.x * size;
    worldPos += u_ueCameraUp * rotatedCorner.y * size;

    vec4 mvpPos = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
    gl_Position = mvpPos;
    
    v_vTexcoord = in_TextureCoord;
    v_vColour = in_Colour;
    v_vDepth = mvpPos.z / mvpPos.w;
    
    // Shadow coordinates
    v_vShadowCoord = u_ueDirShadowMatrix * vec4(worldPos, 1.0);
}
