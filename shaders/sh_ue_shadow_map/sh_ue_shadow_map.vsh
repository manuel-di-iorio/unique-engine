attribute vec3 in_Position;
varying float v_depth;
uniform float u_near;
uniform float u_far;

void main()
{
     vec4 clip = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(in_Position, 1.0);

    gl_Position = clip;


    float ndc = clip.z / clip.w;    
    v_depth = ndc * 0.5 + 0.5; 
    
    // Convert to linear depth
    //float linear = (2.0 * u_near) /
                   //(u_far + u_near - v_depth * (u_far - u_near));
    //
    //v_depth = linear / u_far;
}
