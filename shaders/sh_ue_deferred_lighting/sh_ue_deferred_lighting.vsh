/**
 * Deferred Lighting Shader
 * This is the primary lighting shader for the deferred rendering pipeline. It processes 
 * a full-screen quad, sampling Albedo, Normal, ORM, and Depth from the G-Buffer to 
 * calculate PBR lighting (GGX), shadows, and fog for the entire scene in a single pass.
 * Used by UeRendererDeferred.
 */
attribute vec3 in_Position;
attribute vec2 in_TextureCoord0;

varying vec2 vTexcoord;

void main() {
    gl_Position = vec4(in_Position, 1.0);
    vTexcoord = in_TextureCoord0;
}
