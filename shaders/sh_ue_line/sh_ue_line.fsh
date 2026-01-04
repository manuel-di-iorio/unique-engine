varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

uniform vec3 u_ueColor;

void main()
{
    vec4 baseColor = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    vec3 finalColor = v_vColour.rgb * u_ueColor;
    gl_FragColor = vec4(finalColor, v_vColour.a);
}
