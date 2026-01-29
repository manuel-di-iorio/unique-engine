/**
 * 3D Sprite Shader
 * This shader is used for rendering 2D sprites within a 3D environment. It handles 
 * world-space transformations for the sprite geometry and supports basic texture mapping 
 * and color tinting.
 * Used by UeSpriteMaterial.
 */
attribute vec3 in_Position;                  // (x,y,z)
attribute vec2 in_TextureCoord;              // (u,v)
attribute vec4 in_Colour;                    // (r,g,b,a)

uniform vec3 u_ueModelPosition;
uniform float u_ueLockHorizontal;
uniform float u_ueLockVertical;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    mat4 viewMat = gm_Matrices[MATRIX_VIEW];
    
    // Extract scale from world matrix columns
    float scaleX = length(gm_Matrices[MATRIX_WORLD][0].xyz);
    float scaleY = length(gm_Matrices[MATRIX_WORLD][1].xyz);
    
    vec4 viewPos;
    
    // OPTIMAL BRANCHING: common case first
    if (u_ueLockHorizontal + u_ueLockVertical < 0.5) {
        // FAST PATH: Standard billboard using view-space calculation
        viewPos = viewMat * vec4(u_ueModelPosition, 1.0);
        viewPos.xy += in_Position.xy * vec2(scaleX, scaleY);
    } else {
        // COMPAT PATH: Axis locking requires world-space basis construction
        vec3 right, up;
        vec3 forward = vec3(viewMat[0].z, viewMat[1].z, viewMat[2].z); // Row 2 of view matrix (Forward)
        
        if (u_ueLockVertical > 0.5) {
            up = vec3(0.0, 0.0, -1.0); // Fixed Up (Z-up world, Y-down geometry)
            right = normalize(cross(forward, up));
        } else {
            // Lock Horizontal (X axis)
            right = vec3(1.0, 0.0, 0.0);
            up = normalize(cross(right, forward));
            
            // Stabilization: ensure 'up' points generally towards -Z (World Up for Y-down quad)
            // This prevents the sprite from flipping upside down when the camera moves across the axis
            if (up.z > 0.0) {
                up = -up;
                right = -right;
            }
        }
        
        vec3 worldPos = u_ueModelPosition + (in_Position.x * scaleX) * right + (in_Position.y * scaleY) * up;
        viewPos = viewMat * vec4(worldPos, 1.0);
    }
    
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * viewPos;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
