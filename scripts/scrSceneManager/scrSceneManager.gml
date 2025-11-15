/// @description Scene Manager - Manages 3D scene, camera, renderer, and controls

function SceneManager() constructor {
    // 3D Scene components
    self.renderer = new UeRenderer();
    self.camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 });
    self.orbit = new UeOrbitControls(self.camera, {
        shouldHandleInput: function() {
            return global.UI.Main.Scene.hovered;
        }
    });
    self.scene = new UeScene();
    
    // Helpers
    self.grid = new UeGridHelper(10000, 50);
    self.objects = new UeObject3D();
    self.transformControls = new UeTransformControls(self.camera);
    
    // Assimp loader
    self.assimp = new UeAssimpLoader();
    
    // Setup scene
    self.transformControls.onDrag = function() {
        global.UI.needsRedraw = true;
    }
    
    self.scene.add(self.transformControls.getHelper());
    self.scene.add(self.grid, self.objects);
    
    // Configure mouse
    global.UE_MOUSE.view = 1;

    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }
}
