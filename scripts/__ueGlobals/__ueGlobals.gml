global.UE_OBJECT_ID = 0;
global.UE_VERSION = "0.4.0";
global.UE_VFORMAT_PNUC = new UeVertexFormat().position().normal().uv().color().build();
global.UE_VFORMAT_PNUCT = new UeVertexFormat().position().normal().uv().color().tangent().build();
global.UE_VFORMAT_PU = new UeVertexFormat().position().uv().build();
global.UE_TEXTURE_DEFAULT_WHITE = new UeTexture(sprUeWhiteTex);
global.UE_TEXTURE_DEFAULT_BLACK = new UeTexture(sprUeBlackTex);
global.UE_TEXTURE_DEFAULT_NORMAL = new UeTexture(sprUeNormalTex);
global.UE_TEXTURE_DEFAULT_ORM = new UeTexture(sprUeOrmTex);
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
    
    // Shadow
    lightSpaceMatrix: "u_ueLightSpaceMatrix",
    shadowEnabled: "u_ueShadowEnabled",
    receiveShadow: "u_ueReceiveShadow",
    shadowQuality: "u_ueShadowQuality",
    shadowTexelSize: "u_ueShadowTexelSize",
    shadowMapSampler: "s_shadowMap",
    
    // Directional Light Prefixes
    dirLightDir: "u_ueDirLightDir",
    dirLightColor: "u_ueDirLightColor",
    dirLightIntensity: "u_ueDirLightIntensity",
    
    // Point Light Prefixes
    pointLightPosition: "u_uePointLightPosition",
    pointLightColor: "u_uePointLightColor",
    pointLightRange: "u_uePointLightRange",
    pointLightIntensity: "u_uePointLightIntensity",

    // Fog
    fogColor: "u_ueFogColor",
    fogDensity: "u_ueFogDensity",
    fogNear: "u_ueFogNear",
    fogFar: "u_ueFogFar"
};

global.UE_DEFAULT_MATERIAL = new UeMeshStandardMaterial();
global.UE_FALLBACK_MATERIAL = new UeMeshBasicMaterial({ shader: sh_ue_fallback });
global.UE_DEFAULT_MATERIAL_WIREFRAME = new UeMeshBasicMaterial();

enum UE_NORMAL_MAP_TYPE {
  TANGENT_SPACE_NORMAL_MAP,
  OBJECT_SPACE_NORMAL_MAP
}

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

// Internal globals
global.UE_RENDERER_LIGHT_STATE = array_create(5);
enum UE_RENDERER_LIGHT_STATE_ENUM {
    AMBIENT,
    DIRECTIONAL,
    DIRECTIONAL_COUNT,
    POINT_LIGHT,
    POINT_LIGHT_COUNT 
}
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.AMBIENT] = array_create(3, 0);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL] = array_create(2);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.DIRECTIONAL_COUNT] = 0;
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT] = array_create(2);
global.UE_RENDERER_LIGHT_STATE[UE_RENDERER_LIGHT_STATE_ENUM.POINT_LIGHT_COUNT] = 0;

global.UE_RENDERER_CAMERA_POSITION = array_create(3, 0);
global.UE_RENDERER_FOG_STATE = {
    color: [0, 0, 0],
    density: 0,
    near: 1,
    far: 1000,
    enabled: false
};
