varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_ueColor;

void main()
{
    vec4 base = v_vColour * vec4(u_ueColor, 1.0);
    gl_FragColor = base * texture2D(gm_BaseTexture, v_vTexcoord);
    if (gl_FragColor.a < 0.1) discard;
}
