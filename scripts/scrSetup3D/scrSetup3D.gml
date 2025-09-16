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

    scene.add(grid, objects);
}
