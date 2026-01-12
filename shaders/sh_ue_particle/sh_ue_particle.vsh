attribute vec3 in_Position;                  // (x,y,z) center position
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v) - Local UVs (0..2)
attribute vec3 in_Normal;                    // size, rotation, 0

varying vec2 v_vTexcoord;    // Atlas UVs
varying vec2 v_vLocalUV;     // Local UVs (for discard)
varying vec4 v_vColour;
// varying vec4 v_vShadowCoord;
varying float v_vDepth;

uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;
// uniform mat4 u_ueDirShadowMatrix;
uniform vec4 u_ueUVRegion;   // x, y, w, h on texture page (for atlas mapping)

void main()
{
    float size = in_Normal.x;
    float rotation = in_Normal.y;
    
    // 1. Calculate Local Offset for Billboarding in Camera Plane
    vec2 corner = vec2(in_TextureCoord.x - 0.5, 0.5 - in_TextureCoord.y);

    // 2. Rotate in camera plane
    float cosR = cos(rotation);
    float sinR = sin(rotation);
    vec2 rotatedCorner = vec2(
        corner.x * cosR - corner.y * sinR,
        corner.x * sinR + corner.y * cosR
    );

    // 3. Expand World Position
    vec3 worldPos = in_Position.xyz;
    worldPos += u_ueCameraRight * rotatedCorner.x * size;
    worldPos += u_ueCameraUp * rotatedCorner.y * size;

    vec4 mvpPos = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
    gl_Position = mvpPos;
    
    // 4. Map Local UV [0..2] to Atlas UV
    v_vLocalUV = in_TextureCoord;
    v_vTexcoord = u_ueUVRegion.xy + (in_TextureCoord * u_ueUVRegion.zw);
    
    v_vColour = in_Colour;
    v_vDepth = mvpPos.z / mvpPos.w;
    
    // Shadow logic commented out
    // v_vShadowCoord = u_ueDirShadowMatrix * vec4(worldPos, 1.0);
}
