varying vec4 v_vColour;

uniform vec3 u_ueColor;

void main()
{
    gl_FragColor = vec4(v_vColour.rgb * u_ueColor, v_vColour.a);
}
