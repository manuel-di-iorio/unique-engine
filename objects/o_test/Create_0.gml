display_reset(4, false);
currentDemo = undefined;
bgLayer = layer_background_get_id("Background");
selectorW = 300;
show_debug_overlay(true)

scenes = [
    { name: "Cube", obj: oSceneCube, bg: c_black }, 
    { name: "Tree with basic geometries", obj: oSceneTree, bg: #D6FFF9 },
    { name: "Pyramids, sprites and orbit", obj: oScenePyramids, bg: #147FCC },
    { name: "Lines raycasting", obj: oSceneLinesRaycasting, bg: #333333 },
    { name: "Mesh raycasting", obj: oSceneMeshRaycasting, bg: #333333 },
    { name: "Assimp Loader", obj: oSceneAssimpLoader, bg: #147FCC },
    { name: "OBJ Loader", obj: oSceneObjLoader, bg: #147FCC },
    { name: "TransformControls", obj: oSceneTransformControls, bg: #333333 },
];

setScene = function(idx) {
    if (currentDemo != undefined) {
        var oldSceneObj = currentDemo.obj;
        oldSceneObj.camera.dispose();
        with (oldSceneObj) instance_destroy();
    }

    currentDemo = scenes[idx];
    currentDemoIdx = idx;
    instance_create_layer(0, 0, "Instances", currentDemo.obj);
    layer_background_blend(bgLayer, currentDemo.bg);
}

setScene(5);