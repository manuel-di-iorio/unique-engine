function scrSetup3D(){
    renderer = new UeRenderer();
    camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 });
    orbit = new UeOrbitControls(camera, {
        shouldHandleInput: function() {
            return global.UI.Main.Scene.hovered;
        }
    });
    scene = new UeScene();
    
    grid = new UeGridHelper(10000, 50);
    
    objects = new UeObject3D();

    // Create the TransformControls helper (gizmo)
    transformControls = new UeTransformControls(camera);

    transformControls.onDrag = function() {
        global.UI.needsRedraw = true;
    }

    scene.add(transformControls.getHelper());

    scene.add(grid, objects);

    assimp = new UeAssimpLoader();

    global.UE_MOUSE.view = 1;
}