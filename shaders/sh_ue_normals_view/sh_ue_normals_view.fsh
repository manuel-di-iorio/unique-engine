varying vec3 vViewNormal;

void main()
{
    gl_FragColor = vec4(vViewNormal * 0.5 + 0.5, 1.0);
}
