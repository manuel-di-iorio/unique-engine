varying vec3 v_vWorldPosition;
varying vec3 v_vWorldNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

/* Ambient light */
uniform vec3 u_ueAmbient;

/* Directional lights */

// 0
uniform vec3 u_ueDirLightDir0;
uniform vec3 u_ueDirLightColor0;
uniform float u_ueDirLightIntensity0;

// 1
uniform vec3 u_ueDirLightDir1;
uniform vec3 u_ueDirLightColor1;
uniform float u_ueDirLightIntensity1;

/* Point lights */

// 0
uniform vec3 u_uePointLightPosition0;
uniform vec3 u_uePointLightRange0;
uniform vec3 u_uePointLightColor0;
uniform float u_uePointLightIntensity0;

// 1
uniform vec3 u_uePointLightPosition1;
uniform vec3 u_uePointLightRange1;
uniform vec3 u_uePointLightColor1;
uniform float u_uePointLightIntensity1;

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
