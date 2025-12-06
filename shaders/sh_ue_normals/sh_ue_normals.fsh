varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;
varying vec3 v_vNormal;

void main() 
{
    vec3 normal = normalize(v_vWorldNormal);
    gl_FragColor = vec4(abs(normal), 1.0); return;
}
