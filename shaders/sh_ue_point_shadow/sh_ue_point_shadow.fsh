varying float v_dist;
varying vec2 v_vTexcoord;

uniform float u_near;
uniform float u_far;

uniform sampler2D s_alphaMap;
uniform vec4 u_ueMapFlags;  // [hasMap, hasAlphaMap, hasOrmMap, hasNormalMap]
#define u_ueHasMap              u_ueMapFlags.x
#define u_ueHasAlphaMap         u_ueMapFlags.y

uniform vec4 u_ueMapFlags2; // [hasEmissiveMap, hasDisplacementMap, alphaTest, 0]
#define u_ueAlphaTest           u_ueMapFlags2.z

void main()
{
    float alpha = 1.0;
    if (u_ueHasMap > 0.5) alpha *= texture2D(gm_BaseTexture, v_vTexcoord).a;
    if (u_ueHasAlphaMap > 0.5) alpha *= texture2D(s_alphaMap, v_vTexcoord).r;
    
    if (alpha < u_ueAlphaTest) discard;

    float depth = (v_dist - u_near) / (u_far - u_near);
    gl_FragColor = vec4(depth, 0.0, 0.0, 1.0);
}
