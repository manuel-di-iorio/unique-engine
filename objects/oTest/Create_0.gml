// Antialiasing
if (display_aa >= 8) {
    display_reset(8, true);
} else if (display_aa >= 4) {
    display_reset(4, true);
}

randomize();
currentDemo = undefined;
bgLayer = layer_background_get_id("Background");
selectorW = view_xport[0];
selectorMouseStart = false;
showDebug = false;
global.UE_MOUSE.view = 0;

scenes = [
    { name: "Cube", obj: oSceneCube, bg: c_black }, // 0
    { name: "Tree with basic geometries", obj: oSceneTree, bg: #D6FFF9 }, // 1
    { name: "Pyramids, sprites and orbit", obj: oScenePyramids, bg: #147FCC }, // 2
    { name: "Lines raycasting", obj: oSceneLinesRaycasting, bg: #333333 }, // 3
    { name: "Mesh raycasting", obj: oSceneMeshRaycasting, bg: #333333 }, // 4
    { name: "Assimp Loader", obj: oSceneAssimpLoader, bg: #147FCC }, // 5
    { name: "OBJ Loader", obj: oSceneObjLoader, bg: #147FCC }, // 6
    { name: "TransformControls", obj: oSceneTransformControls, bg: #333333 }, // 7
    { name: "Project Loader", obj: oSceneProjectLoader, bg: #147FCC }, // 8
    { name: "Shadow Mapping", obj: oSceneShadowMapping, bg: #147FCC }, // 9
    { name: "Post Processing", obj: oScenePostprocessing, bg: c_black }, // 10
    { name: "PBR Material", obj: oScenePBR, bg: c_ltgray }, // 11
    { name: "Platform Game", obj: oScenePlatformGame, bg: #66DDDD }, // 12
    { name: "Particles", obj: oSceneParticles, bg: #111111 }, // 13
    { name: "LOD", obj: oSceneLOD, bg: #111111 }, // 14
    { name: "Animations", obj: oSceneAnimations, bg: #111111 }, // 15
    //{ name: "3D Text", obj: oSceneText, bg: #111111 }, // 16
];

setScene = function(idx) {
    audio_stop_all();
  
    if (currentDemo != undefined) {
        var oldSceneObj = currentDemo.obj;
        oldSceneObj.camera.dispose();
        with (oldSceneObj) instance_destroy();
    }

    currentDemo = scenes[idx];
    currentDemoIdx = idx;
    layer_background_blend(bgLayer, currentDemo.bg); 
    instance_create_layer(0, 0, "Instances", currentDemo.obj); 
}

setScene(0);
