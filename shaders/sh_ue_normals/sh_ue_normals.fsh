varying vec3 vWorldNormal;

void main() 
{
    gl_FragColor = vec4(normalize(vWorldNormal) * 0.5 + 0.5, 1.0);
}
