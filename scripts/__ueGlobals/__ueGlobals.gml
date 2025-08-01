global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();
global.UE_DEFAULT_TEXTURE = new UeTexture({ image: spr_ue_default_tex });
global.UE_OBJECT3D_DEFAULT_UP = new UeVector3(0, 0, -1);
global.UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE = true;
global.UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;
#macro UE_VECTOR3_ZERO new UeVector3(0, 0, 0)
global.UE_MOUSE = new UeMouse();

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

// Internal globals
#macro UE_EPSILON 0.00001
global.UE_OBJECT_ID = 0;
global.UE_DUMMY_VECTOR3 = new UeVector3();
global.UE_DUMMY_VECTOR3_B = new UeVector3();
global.UE_DUMMY_VECTOR3_C = new UeVector3();
global.UE_DUMMY_VECTOR3_D = new UeVector3();
global.UE_DUMMY_VECTOR3_E = new UeVector3();
global.UE_DUMMY_VECTOR3_F = new UeVector3();
global.UE_DUMMY_VECTOR3_G = new UeVector3();
global.UE_DUMMY_VECTOR3_H = new UeVector3();
global.UE_DUMMY_VECTOR3_J = new UeVector3();
global.UE_DUMMY_VECTOR3_K = new UeVector3();
global.UE_DUMMY_QUATERNION = new UeQuaternion();
global.UE_DUMMY_SPHERE = new UeSphere();
global.UE_DUMMY_DEFAULT_SPRITE_CENTER = new UeVector2(0.5, 0.5);
global.UE_DUMMY_RAY = new UeRay();
global.UE_DUMMY_MATRIX4 = new UeMatrix4();
global.UE_DUMMY_MATRIX4_B = new UeMatrix4();
global.UE_DUMMY_BOX = new UeBox3();
global.UE_DUMMY_ARRAY3 = array_create(3);

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