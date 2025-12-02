// Fragment shader for shadow map generation
// Outputs depth value to r32float surface

void main()
{
    // gl_FragCoord.z contains the depth value (0 to 1)
    // Store it in the red channel of the r32float surface
    gl_FragColor = vec4(gl_FragCoord.z, 1.0, 0.0, 0.0);
}
