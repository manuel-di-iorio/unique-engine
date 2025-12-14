global.UE_OBJECT_ID = 0;
global.UE_VERSION = "0.2.0";
global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();
global.UE_TEXTURE_MAP = new UeTexture(sprUeMapTex);
global.UE_TEXTURE_EMISSIVE = new UeTexture(sprUeEmissiveTex);
global.UE_MOUSE = new UeMouse();

// Uniform names configuration
global.UE_UNIFORM_NAMES_CONFIG = {
    modelPosition: "u_ueModelPosition",
    ambient: "u_ueAmbient",
    emissiveIntensity: "u_ueEmissiveIntensity",
    
    // Shadow
    lightSpaceMatrix: "u_ueLightSpaceMatrix",
    shadowEnabled: "u_ueShadowEnabled",
    receiveShadow: "u_ueReceiveShadow",
    shadowQuality: "u_ueShadowQuality",
    shadowTexelSize: "u_ueShadowTexelSize",
    shadowMapSampler: "s_shadowMap", // Sampler
    
    // Directional Light Prefixes
    dirLightDir: "u_ueDirLightDir",
    dirLightColor: "u_ueDirLightColor",
    dirLightIntensity: "u_ueDirLightIntensity",
    
    // Point Light Prefixes
    pointLightPosition: "u_uePointLightPosition",
    pointLightColor: "u_uePointLightColor",
    pointLightRange: "u_uePointLightRange",
    pointLightIntensity: "u_uePointLightIntensity"
};

global.UE_DEFAULT_MATERIAL = new UeMeshBasicMaterial();
global.UE_DEFAULT_MATERIAL_WIREFRAME = new UeMeshBasicMaterial();

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
