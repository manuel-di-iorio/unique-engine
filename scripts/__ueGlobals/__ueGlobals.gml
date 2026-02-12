global.UE_OBJECT_ID = 0;
global.UE_VERSION = "0.12.0";
global.UE_VFORMAT_PU = new UeVertexFormat().position().uv().build();
global.UE_VFORMAT_PC = new UeVertexFormat().position().color().build();
global.UE_VFORMAT_PUC = new UeVertexFormat().position().uv().color().build();
global.UE_VFORMAT_PNUC = new UeVertexFormat().position().normal().uv().color().build();
global.UE_VFORMAT_PNUTC = new UeVertexFormat().position().normal().uv().tangent().color().build();
global.UE_VFORMAT_PNUTCB = new UeVertexFormat().position().normal().uv().tangent().color().bones().build();
global.UE_MOUSE = new UeMouse();

// Uniform names configuration
global.UE_UNIFORM_NAMES_CONFIG = {
    modelPosition: "u_ueModelPosition",
    worldMatrix: "u_ueWorldMatrix",

    // Scene Data (Packed)
    sceneData: "u_ueSceneData",

    // Material Data (Packed)
    materialData: "u_ueMaterialData", // [toneMapping, toneMappingExposure, toneMapped]
    mapFlags: "u_ueMapFlags",         // [hasMap, hasAlphaMap, hasOrmMap, hasNormalMap]
    mapFlags2: "u_ueMapFlags2",       // [hasEmissiveMap, hasDisplacementMap, 0, 0]

    // Shadow (Directional)
    dirShadowMatrix: "u_ueDirShadowMatrix",
    dirShadowEnabled: "u_ueDirShadowEnabled",
    receiveShadow: "u_ueReceiveShadow",
    dirShadowQuality: "u_ueDirShadowQuality",
    dirShadowTexelSize: "u_ueDirShadowInvTexelSize",
    dirShadowMap: "s_dirShadowMap",

    // Shadow (Point)
    pointShadowEnabled: "u_uePointShadowEnabled",
    pointShadowMatrix: "u_uePointShadowMatrix",
    pointShadowFar: "u_uePointShadowFar",
    pointShadowNear: "u_uePointShadowNear",
    pointShadowPos: "u_uePointShadowPos",
    pointShadowTexelSize: "u_uePointShadowInvTexelSize",
    pointShadowQuality: "u_uePointShadowQuality",
    pointShadowMap: "s_pointShadowMap",

    // Point Light (Packed)
    pointLightsData: "u_uePointLightsData",

    // Spot Light (Packed)
    spotLightsData: "u_ueSpotLightsData",

    // Shadow (Spot)
    spotShadowEnabled: "u_ueSpotShadowEnabled",
    spotShadowMatrix: "u_ueSpotShadowMatrix",
    spotShadowFar: "u_ueSpotShadowFar",
    spotShadowNear: "u_ueSpotShadowNear",
    spotShadowPos: "u_ueSpotShadowPos",
    spotShadowQuality: "u_ueSpotShadowQuality",
    spotShadowTexelSize: "u_ueSpotShadowInvTexelSize",
    spotShadowMap: "s_spotShadowMap",

    // Bone Matrices (Skinning)
    boneMatrices: "u_ueBoneMatrices",
    numBones: "u_ueNumBones",

    // Hemisphere Light
    hemiLightDir: "u_ueHemiLightDirection",
    hemiLightSkyColor: "u_ueHemiLightSkyColor",
    hemiLightGroundColor: "u_ueHemiLightGroundColor",
    hemiLightIntensity: "u_ueHemiLightIntensity",
    
    // Billboards (UeSprite)
    lockHorizontal: "u_ueLockHorizontal",
    lockVertical: "u_ueLockVertical",
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
global.UE_MAX_POINT_LIGHTS = 8;
global.UE_MAX_SPOT_LIGHTS = 8;

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
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT] = array_create(8);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.SPOT_LIGHT_COUNT] = 0;
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT] = array_create(1);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.HEMI_LIGHT_COUNT] = 0;

global.UE_RENDERER_TONE_MAPPING = UE_TONE_MAPPING.NONE;
global.UE_RENDERER_TONE_MAPPING_EXPOSURE = 1.0;
global.UE_RENDERER_CAMERA_POSITION = array_create(3, 0);
// Pre-allocated buffer for packed scene data [5 * 4 values]
global.UE_SCENE_DATA_BUFFER = array_create(20, 0);
global.UE_RENDERER_SCENE_DATA = undefined;

// Pre-allocated buffers for lights data
global.UE_POINT_LIGHTS_DATA_BUFFER = array_create(8 * 16, 0);
global.UE_SPOT_LIGHTS_DATA_BUFFER = array_create(8 * 16, 0);
global.UE_POINT_SHADOW_MATRICES_BUFFER = array_create(6 * 16, 0);

// Hemisphere Light Cached Data
global.UE_HEMI_LIGHT_DATA = {
    direction: [0, 1, 0],
    skyColor: [1, 1, 1],
    groundColor: [0, 0, 0],
    intensity: 0
};

// Directional Light Cached Data (Primary)
global.UE_DIR_LIGHT_DATA = {
    direction: [0, 1, 0],
    color: [1, 1, 1],
    intensity: 0
};

// Global Uniform Caching
global.UE_CURRENT_SHADER = -1;
