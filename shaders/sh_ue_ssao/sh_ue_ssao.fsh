varying vec2 v_vTexcoord;

uniform sampler2D uDepthTex;
uniform sampler2D uNormalTex;
uniform sampler2D uNoiseTex;

uniform vec3 uKernel[32];
uniform vec2 uNoiseScale;
uniform float uRadius;
uniform float uBias;
uniform float uPower;
uniform mat4 uProjectionMatrix;
uniform mat4 uInvProjectionMatrix;

// Reconstruct View-Space position from Depth
vec3 get_view_pos(vec2 uv) {
    float depth = texture2D(uDepthTex, uv).r;
    // In GameMaker, depth is usually [0, 1]
    vec4 clip_space_pos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view_space_pos = uInvProjectionMatrix * clip_space_pos;
    return view_space_pos.xyz / view_space_pos.w;
}

void main() {
    vec3 fragPos = get_view_pos(v_vTexcoord);
    vec3 normal = normalize(texture2D(uNormalTex, v_vTexcoord).xyz * 2.0 - 1.0);
    vec3 randomVec = normalize(texture2D(uNoiseTex, v_vTexcoord * uNoiseScale).xyz * 2.0 - 1.0);

    // Create TBN matrix (Tangent-Bitangent-Normal) to transform kernel to view-space oriented with normal
    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
    for(int i = 0; i < 32; ++i) {
        // From tangent to view-space
        vec3 samplePos = TBN * uKernel[i]; 
        samplePos = fragPos + samplePos * uRadius; 
        
        // Project sample position to screen space
        vec4 offset = vec4(samplePos, 1.0);
        offset = uProjectionMatrix * offset;
        offset.xyz /= offset.w;
        offset.xyz = offset.xyz * 0.5 + 0.5;
        
        // Get sample depth
        float sampleDepth = get_view_pos(offset.xy).z;
        
        // Range check (prevents occlusion from objects far behind)
        float rangeCheck = smoothstep(0.0, 1.0, uRadius / abs(fragPos.z - sampleDepth));
        occlusion += (sampleDepth >= samplePos.z + uBias ? 1.0 : 0.0) * rangeCheck;           
    }
    
    occlusion = 1.0 - (occlusion / 32.0);
    gl_FragColor = vec4(vec3(pow(occlusion, uPower)), 1.0);
}
