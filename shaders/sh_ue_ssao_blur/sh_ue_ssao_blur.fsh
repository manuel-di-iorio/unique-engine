varying vec2 v_vTexcoord;
uniform vec2 uTexelSize;

void main() {
    vec2 texelSize = uTexelSize;
    float result = 0.0;
    for (int x = -2; x < 2; ++x) {
        for (int y = -2; y < 2; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture2D(gm_BaseTexture, v_vTexcoord + offset).r;
        }
    }
    gl_FragColor = vec4(vec3(result / 16.0), 1.0);
}
