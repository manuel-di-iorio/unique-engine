varying vec3 v_vWorldPosition;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

// Lights
uniform vec3 u_ueAmbient;

uniform vec3 u_ueDirLightDir0;
uniform vec3 u_ueDirLightColor0;
uniform float u_ueDirLightIntensity0;

uniform vec3 u_uePointLightPosition0;
uniform vec3 u_uePointLightRange0;
uniform vec3 u_uePointLightColor0;
uniform float u_uePointLightIntensity0;

void main()
{
    vec3 finalColor = v_vColour.rgb * u_ueAmbient;
    vec3 norm = normalize(v_vNormal);
    
    // DirectionalLight 0
    vec3 lightDir0 = normalize(-u_ueDirLightDir0);
    float lightDiff0 = max(dot(norm, lightDir0), 0.0);
    finalColor += u_ueDirLightColor0 * lightDiff0 * u_ueDirLightIntensity0;
    
    // PointLight 0
    vec3 toLight = u_uePointLightPosition0 - v_vWorldPosition;
    float dist = length(toLight);
    vec3 lightDir1 = normalize(toLight); 
    float attenuation = 1.0 - clamp(dist / u_uePointLightRange0.x, 0.0, 1.0);
    float lightDiff1 = max(dot(norm, lightDir1), 0.0); 
    finalColor += u_uePointLightColor0 * lightDiff1 * attenuation * u_uePointLightIntensity0;
     
    gl_FragColor = vec4(finalColor, v_vColour.a);
}
