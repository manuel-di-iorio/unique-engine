function scrSetup3D(){
    renderer = new UeRenderer();
    camera = new UePerspectiveCamera({ x: 30, z: 50, far: 10000, yt: 200, view: 1 });
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