precision highp float;

void main()
{
    // Depth is handled automatically by GameMaker for depth-only shaders if configured correctly,
    // but we can explicitly write it if needed. For standard depth textures, 
    // the fragment shader just needs to exist.
    gl_FragColor = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
