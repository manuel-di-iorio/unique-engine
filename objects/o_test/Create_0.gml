bgLayer = layer_background_get_id("Background");
demo = 2;
demoMax = 2;
scenes = [
    { obj: obj_scene_0, bg: #147FCC }, 
    { obj: obj_scene_1, bg: #D6FFF9 },
    { obj: obj_scene_2, bg: #147FCC },
];

setScene = function(incr = 0) {
    if (incr != 0) {
        var oldSceneObj = scenes[demo].obj;
        oldSceneObj.camera.dispose();
        with (oldSceneObj) instance_destroy();
    
        demo += incr;
    }

    var newScene = scenes[demo];
    instance_create_layer(0, 0, "Instances", newScene.obj);
    layer_background_blend(bgLayer, newScene.bg);
}

setScene();