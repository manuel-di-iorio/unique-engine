global.UE_OBJECT_ID = 0;
global.UE_VERSION = "0.6.0";
global.UE_VFORMAT_PNUC = new UeVertexFormat().position().normal().uv().color().build();
global.UE_VFORMAT_PNUTC = new UeVertexFormat().position().normal().uv().tangent().color().build();
global.UE_VFORMAT_PU = new UeVertexFormat().position().uv().build();
global.UE_MOUSE = new UeMouse();

// Uniform names configuration
global.UE_UNIFORM_NAMES_CONFIG = {
    modelPosition: "u_ueModelPosition",
    worldMatrix: "u_ueWorldMatrix",
    cameraPosition: "u_ueCameraPosition",
    ambient: "u_ueAmbient",
    emissiveIntensity: "u_ueEmissiveIntensity",
    aoIntensity: "u_ueAoIntensity",
    aoMapIntensity: "u_ueAoMapIntensity",
    
    // Shadow (Directional)
    lightSpaceMatrix: "u_ueDirShadowMatrix",
    shadowEnabled: "u_ueDirShadowEnabled",
    receiveShadow: "u_ueReceiveShadow",
    shadowQuality: "u_ueDirShadowQuality",
    shadowTexelSize: "u_ueDirShadowInvTexelSize",
    shadowMapSampler: "s_dirShadowMap",
    
    // Shadow (Point)
    pointShadowEnabled: "u_uePointShadowEnabled",
    pointShadowMatrix: "u_uePointShadowMatrix",
    pointShadowFar: "u_uePointShadowFar",
    pointShadowNear: "u_uePointShadowNear",
    pointShadowPos: "u_uePointShadowPos",
    pointShadowTexelSize: "u_uePointShadowInvTexelSize",
    pointShadowQuality: "u_uePointShadowQuality",
    pointShadowMapSampler: "s_pointShadowMap",
    
    // Directional Light Prefixes
    dirLightDir: "u_ueDirLightDir",
    dirLightColor: "u_ueDirLightColor",
    dirLightIntensity: "u_ueDirLightIntensity",
    
    // Point Light Prefixes
    pointLightPosition: "u_uePointLightPosition",
    pointLightColor: "u_uePointLightColor",
    pointLightRange: "u_uePointLightRange",
    pointLightIntensity: "u_uePointLightIntensity",
    pointLightDecay: "u_uePointLightDecay",

    // Spot Light Prefixes
    spotLightPosition: "u_ueSpotLightPosition",
    spotLightDirection: "u_ueSpotLightDirection",
    spotLightColor: "u_ueSpotLightColor",
    spotLightRange: "u_ueSpotLightRange",
    spotLightIntensity: "u_ueSpotLightIntensity",
    spotLightDecay: "u_ueSpotLightDecay",
    spotLightAngle: "u_ueSpotLightAngle",
    spotLightPenumbra: "u_ueSpotLightPenumbra",

    // Shadow (Spot)
    spotShadowEnabled: "u_ueSpotShadowEnabled",
    spotShadowMatrix: "u_ueSpotShadowMatrix",
    spotShadowFar: "u_ueSpotShadowFar",
    spotShadowNear: "u_ueSpotShadowNear",
    spotShadowPos: "u_ueSpotShadowPos",
    spotShadowQuality: "u_ueSpotShadowQuality",
    spotShadowTexelSize: "u_ueSpotShadowInvTexelSize",
    spotShadowMapSampler: "s_spotShadowMap",

    // Hemisphere Light
    hemiLightDirection: "u_ueHemiLightDirection",
    hemiLightSkyColor: "u_ueHemiLightSkyColor",
    hemiLightGroundColor: "u_ueHemiLightGroundColor",
    hemiLightIntensity: "u_ueHemiLightIntensity",

    // Fog
    fogColor: "u_ueFogColor",
    fogDensity: "u_ueFogDensity",
    fogNear: "u_ueFogNear",
    fogFar: "u_ueFogFar",
    
    // Tone Mapping
    toneMapping: "u_ueToneMapping",
    toneMappingExposure: "u_ueToneMappingExposure",
    toneMapped: "u_ueToneMapped",
    
    // Has maps
    hasMap: "u_ueHasMap",
    hasAlphaMap: "u_ueHasAlphaMap",
    hasOrmMap: "u_ueHasOrmMap",
    hasNormalMap: "u_ueHasNormalMap",
    hasEmissiveMap: "u_ueHasEmissiveMap",
    hasDisplacementMap: "u_ueHasDisplacementMap"
};

global.UE_DEFAULT_MATERIAL = new UeMeshStandardMaterial();
global.UE_FALLBACK_MATERIAL = new UeMeshBasicMaterial({ shader: sh_ue_fallback });
global.UE_DEFAULT_MATERIAL_WIREFRAME = new UeMeshBasicMaterial();

global.UE_FULLSCREEN_QUAD = new UeFullscreenQuad();

enum UE_UNIFORM_TYPE {
    FLOAT = 0,
    VEC2 = 1,
    VEC3 = 2,
    VEC4 = 3,
    MAT4 = 4,
    ARRAY = 5,
    BUFFER = 6
}

enum UE_FORMAT_ATTR {
    POSITION = 0,
    NORMAL = 1,
    UV = 2,
    COLOR = 3,
    CUSTOM = 4
}

enum UE_TEXTURE_WRAP {
    REPEAT,
    CLAMP_TO_EDGE,
    MIRRORED_REPEAT
}

enum UE_SHADOW_QUALITY {
    LOW = 0,    // No PCF, hard shadows (1 sample)
    MEDIUM = 1, // Light PCF, soft shadows (4 samples)
    HIGH = 2    // Full PCF, very soft shadows (16 samples)
}

enum UE_TONE_MAPPING {
    NONE,
    LINEAR,
    REINHARD,
    CINEON,
    ACES,
    AGX,
    NEUTRAL
}

enum UE_RENDER_PATH {
    FORWARD,
    DEFERRED
}

// Internal globals
global.UE_RENDERER_LIGHT_STATE = array_create(9);
enum UE_RENDERER_LIGHT_STATE_ENUM {
    AMBIENT,
    DIRECTIONAL,
    DIRECTIONAL_COUNT,
    POINT_LIGHT,
    POINT_LIGHT_COUNT,
    SPOT_LIGHT,
    SPOT_LIGHT_COUNT,
    HEMI_LIGHT,
    HEMI_LIGHT_COUNT
}
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT] = array_create(3, 0);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL] = array_create(1);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = 0;
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT] = array_create(8);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = 0;
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT] = array_create(4);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT] = 0;
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT] = array_create(1);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT_COUNT] = 0;

global.UE_RENDERER_TONE_MAPPING = UE_TONE_MAPPING.NONE;
global.UE_RENDERER_TONE_MAPPING_EXPOSURE = 1.0;
global.UE_RENDERER_CAMERA_POSITION = array_create(3, 0);
global.UE_RENDERER_FOG_STATE = {
    color: [0, 0, 0],
    density: 0,
    near: 1,
    far: 1000,
    enabled: false
};
