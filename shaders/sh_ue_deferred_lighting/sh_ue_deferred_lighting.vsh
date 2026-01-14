attribute vec3 in_Position;
attribute vec2 in_TextureCoord0;

varying vec2 vTexcoord;

void main() {
    gl_Position = vec4(in_Position, 1.0);
    vTexcoord = in_TextureCoord0;
}
