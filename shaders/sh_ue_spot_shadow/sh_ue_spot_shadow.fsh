precision highp float;

uniform float u_near;
uniform float u_far;

float LinearizeDepth(float depth, float zparam) 
{ 
#if !defined(_YY_HLSL11_) 
    depth = depth * 2.0 - 1.0; 
#endif 
    return 1.0 / ((1.0 - zparam) * depth + zparam); 
}

void main()
{
    // We write the linearized depth to the color buffer for debugging/viewer purposes.
    float zparam = u_far / u_near;
    float depth = LinearizeDepth(gl_FragCoord.z, zparam);
    
    gl_FragColor = vec4(depth, 0.0, 0.0, 1.0);
}
