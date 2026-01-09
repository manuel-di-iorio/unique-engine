varying float v_dist;
uniform float u_near;
uniform float u_far;

void main()
{
    float depth = (v_dist - u_near) / (u_far - u_near);
    gl_FragColor = vec4(depth, 0.0, 0.0, 1.0);
}
