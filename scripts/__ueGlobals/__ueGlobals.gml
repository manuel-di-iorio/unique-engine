global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();
global.UE_DEFAULT_TEXTURE = new UeTexture({ image: spr_ue_default_tex });
global.UE_OBJECT3D_DEFAULT_UP = new UeVector3(0, 0, -1); // @MissingDoc
global.UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE = true; // @MissingDoc
global.UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true; // @MissingDoc
#macro UE_MACRO_VECTOR3_ZERO new UeVector3(0, 0, 0)
global.UE_VECTOR3_ZERO = UE_MACRO_VECTOR3_ZERO; // @MissingDoc

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


// Internal globals
global.UE_OBJECT_ID = 0;
global.UE_EPSILON = math_get_epsilon();
global.UE_DUMMY_VECTOR3 = new UeVector3();
global.UE_DUMMY_VECTOR3_B = new UeVector3();
global.UE_DUMMY_QUATERNION = new UeQuaternion();
global.UE_DUMMY_SPHERE = new UeSphere();
global.UE_DUMMY_DEFAULT_SPRITE_CENTER = new UeVector2(0.5, 0.5);

enum UE_MATERIAL_GPU_STATE_ENUM {
    SIDE,
    DEPTH_TEST,
    DEPTH_WRITE,
    DEPTH_FUNC,
    TRANSPARENT,
    ALPHA_TEST,
    COLOR_WRITE,
    BLENDING,
    BLEND_EQUATION,
    BLEND_EQUATION_ALPHA,
    BLEND_SRC,
    BLEND_DST,
    BLEND_SRC_ALPHA,
    BLEND_DST_ALPHA
}
global.UE_MATERIAL_GPU_STATE = array_create(14);
global.UE_MATERIAL_UNIFORMS_SET_CACHE = array_create(3);

global.UE_RENDERER_STATE = array_create(1);
enum UE_RENDERER_STATE_ENUM {
    CAMERA,
}

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

var opaqueQueue = array_create(512);
        var transparentQueue = array_create(512);
        var lights = array_create(8);

global.UE_RENDERER_OPAQUE_QUEUE = array_create(512);
global.UE_RENDERER_TRANSPARENT_QUEUE = array_create(256);
global.UE_RENDERER_LIGHTS = array_create(2);