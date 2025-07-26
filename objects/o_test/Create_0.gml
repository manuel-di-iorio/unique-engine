display_reset(4, false);
show_debug_overlay(true);

bgLayer = layer_background_get_id("Background");
demo = 4;
demoMax = 4;
scenes = [
    { obj: obj_scene_0, bg: c_black }, 
    { obj: obj_scene_1, bg: #D6FFF9 },
    { obj: obj_scene_2, bg: #147FCC },
    { obj: obj_scene_3, bg: #147FCC },
    { obj: obj_scene_4, bg: #333333 },
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