global.UE_MATH_VERSION = "2.1.0";
global.UE_OBJECT3D_DEFAULT_UP = new UeVector3(0, 0, -1);
global.UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE = true;
global.UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;
#macro UE_VECTOR3_ZERO new UeVector3(0, 0, 0)

#macro UE_EPSILON 0.00001
global.UE_DUMMY_VECTOR3 = new UeVector3();
global.UE_DUMMY_VECTOR3_B = new UeVector3();
global.UE_DUMMY_VECTOR3_C = new UeVector3();
global.UE_DUMMY_VECTOR3_D = new UeVector3();
global.UE_DUMMY_VECTOR3_E = new UeVector3();
global.UE_DUMMY_VECTOR3_F = new UeVector3();
global.UE_DUMMY_VECTOR3_G = new UeVector3();
global.UE_DUMMY_VECTOR3_H = new UeVector3();
global.UE_DUMMY_VECTOR3_J = new UeVector3();
global.UE_DUMMY_QUATERNION = new UeQuaternion();
global.UE_DUMMY_SPHERE = new UeSphere();
global.UE_DUMMY_DEFAULT_SPRITE_CENTER = new UeVector2(0.5, 0.5);
global.UE_DUMMY_RAY = new UeRay();
global.UE_DUMMY_MATRIX4 = new UeMatrix4();
global.UE_DUMMY_MATRIX4_B = new UeMatrix4();
global.UE_DUMMY_BOX = new UeBox3();
global.UE_DUMMY_ARRAY3 = array_create(3);
global.UE_DUMMY_ARRAY16 = array_create(16); // Used by matrix functions to reuse the array for temp calculations
global.UE_MATRIX_IDENTITY = matrix_build_identity();
