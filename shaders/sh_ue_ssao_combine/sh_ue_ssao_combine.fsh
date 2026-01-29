varying vec2 v_vTexcoord;
uniform sampler2D uAOTex;
uniform float uIntensity;

void main() {
    vec4 sceneColor = texture2D(gm_BaseTexture, v_vTexcoord);
    float ao = texture2D(uAOTex, v_vTexcoord).r;
    
    // Apply AO intensity
    ao = mix(1.0, ao, uIntensity);
    
    gl_FragColor = vec4(sceneColor.rgb * ao, sceneColor.a);
}
