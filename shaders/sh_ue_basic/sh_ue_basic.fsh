varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

uniform vec3 u_ueModelPosition;
uniform vec3 u_ueCameraPosition;

uniform sampler2D s_map;

void main()
{
    vec3 finalColor = v_vColour.rgb;
    
    // Diffuse texture
    finalColor *= texture2D(s_map, v_vTexcoord).rgb;
     
    gl_FragColor = vec4(finalColor, v_vColour.a);
}
