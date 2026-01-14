attribute vec3 in_Position;      // SpawnPos
attribute vec4 in_Colour;        // ColorStart (U8x4)
attribute vec2 in_TextureCoord;  // CornerXY (-0.5 a 0.5)
attribute vec4 in_TextureCoord1; // x: vX, y: vY, z: vZ, w: spawnTime
attribute vec3 in_TextureCoord2; // x: maxLife, y: sStart, z: rStart

// Uniforms (Costanti per emitter)
uniform vec3 u_ueCameraRight;
uniform vec3 u_ueCameraUp;
uniform vec4 u_ueUVRegion;
uniform float u_ueTime;

uniform vec3 u_ueGravity;
uniform float u_ueSizeEnd;
uniform vec3 u_ueColorMid;
uniform vec4 u_ueColorEnd;
uniform vec2 u_ueColorTimes; // x: midTime, y: glow
uniform float u_ueRotSpeed;
uniform float u_ueDrag;
uniform vec3 u_ueAnimData; // x: framesX, y: framesY, z: animSpeed

uniform mat4 u_ueShadowMatrix;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying float v_vSoftness;
varying float v_vGlow;
varying vec4 v_vScreenPos;
varying vec4 v_vShadowPos;

void main() {
    float age = u_ueTime - in_TextureCoord1.w;
    float maxLife = in_TextureCoord2.x;
    
    // Auto-discard if killed (moved out of clip space)
    if (age < 0.0 || age > maxLife) {
        gl_Position = vec4(2e5, 2e5, 2e5, 1.0);
        return;
    }

    float t = age / maxLife;

    // 1. Physics with Linear Drag
    float dragFactor = (u_ueDrag > 0.01) ? (1.0 - exp(-u_ueDrag * age)) / u_ueDrag : age;
    vec3 basePos = in_Position + (in_TextureCoord1.xyz * dragFactor) + (0.5 * u_ueGravity * age * age);

    // 2. Visuals (3-Way Color interpolation)
    float midT = u_ueColorTimes.x;
    vec3 finalRGB;
    if (t < midT) {
        finalRGB = mix(in_Colour.rgb, u_ueColorMid, t / midT);
    } else {
        finalRGB = mix(u_ueColorMid, u_ueColorEnd.rgb, (t - midT) / (1.0 - midT));
    }
    
    v_vColour = vec4(finalRGB, mix(in_Colour.a, u_ueColorEnd.a, t));
    v_vGlow = u_ueColorTimes.y;

    float size = mix(in_TextureCoord2.y, u_ueSizeEnd, t);
    float rot  = in_TextureCoord2.z + (u_ueRotSpeed * age);

    // 3. Billboard
    float s = sin(rot); float c = cos(rot);
    vec2 rotatedCorner = vec2(in_TextureCoord.x * c - in_TextureCoord.y * s, in_TextureCoord.x * s + in_TextureCoord.y * c);
    vec3 worldPos = basePos + (u_ueCameraRight * rotatedCorner.x + u_ueCameraUp * rotatedCorner.y) * size;

    // 4. UV Flipbook Animation
    float totalFrames = u_ueAnimData.x * u_ueAnimData.y;
    float currentFrame = floor(mod(t * u_ueAnimData.z * totalFrames, totalFrames));
    
    float frameX = mod(currentFrame, u_ueAnimData.x);
    float frameY = floor(currentFrame / u_ueAnimData.x);
    
    vec2 frameSize = vec2(1.0 / u_ueAnimData.x, 1.0 / u_ueAnimData.y);
    vec2 frameOffset = vec2(frameX, frameY) * frameSize;
    
    // Adjust local UV (0-1) to frame-local UV
    vec2 localUV = in_TextureCoord + 0.5;
    vec2 animatedUV = frameOffset + localUV * frameSize;
    
    v_vTexcoord = u_ueUVRegion.xy + animatedUV * u_ueUVRegion.zw;
    
    v_vSoftness = clamp(worldPos.z / (size * 0.5), 0.0, 1.0);
    vec4 viewPos = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4(worldPos, 1.0);
    gl_Position = viewPos;
    v_vScreenPos = viewPos;
    v_vShadowPos = u_ueShadowMatrix * vec4(worldPos, 1.0);
}
