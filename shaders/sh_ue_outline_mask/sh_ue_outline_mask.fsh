// Mask Fragment Shader - Outputs solid white for silhouette mask
// Used to render selected objects as white on black background

void main()
{
    // Output solid white - this creates the mask for edge detection
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
