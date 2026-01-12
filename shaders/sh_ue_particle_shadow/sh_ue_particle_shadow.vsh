attribute vec3 in_Position;                  // (x,y,z) center position
attribute vec2 in_TextureCoord;              // (u,v) - Local UVs (0..2)
attribute vec3 in_Normal;                    // size, rotation, 0

uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;

void main()
{
    float size = in_Normal.x;
    float rotation = in_Normal.y;
    
    // Perform same billboard expansion as main shader so shadows are correctly shaped
    vec2 corner = vec2(in_TextureCoord.x - 0.5, 0.5 - in_TextureCoord.y);

    float cosR = cos(rotation);
    float sinR = sin(rotation);
    vec2 rotatedCorner = vec2(
        corner.x * cosR - corner.y * sinR,
        corner.x * sinR + corner.y * cosR
    );

    vec3 worldPos = in_Position.xyz;
    worldPos += u_ueCameraRight * rotatedCorner.x * size;
    worldPos += u_ueCameraUp * rotatedCorner.y * size;

    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
}
