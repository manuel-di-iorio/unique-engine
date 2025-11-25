/// @description Scene Manager - Manages 3D scene, camera, renderer, and controls

function SceneManager() constructor {
    self.renderer = new UeRenderer();
    self.camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 });
    self.orbit = new UeOrbitControls(self.camera, {
        shouldHandleInput: function() {
            return global.UI.Main.Scene.hovered;
        },
        onChange: function() {
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        }
    });
    self.scene = new UeScene();
    
    // Helpers
    self.grid = new UeGridHelper(10000, 50);
    self.gridEnabled = true;
    self.showBoxColliders = true;
    self.objects = new UeObject3D();
    self.transformControls = new UeTransformControls(self.camera, {
        onDrag: function() {
            oSceneEditor.assetManager.editAsset(oSceneEditor.sceneManager.transformControls.object);
        },
        onDragEnd: function() {
            global.UI.needsRedraw = true;
        }
    });

    self.boxHelper = new UeBoxHelper(undefined, c_yellow, { matrixAutoUpdate: false });
    // with (self.boxHelper) {
    //     function onBeforeRender() {
    //         if (self.needsUpdate) self.update();
    //     }
    // }
    
    // Assimp loader
    self.assimp = new UeAssimpLoader();
    
    self.scene.add(self.transformControls.getHelper());
    self.scene.add(self.grid, self.objects, self.boxHelper);
    
    // Configure mouse
    global.UE_MOUSE.view = 1;
    
    // Test lights
    self.scene.add(new UeAmbientLight(c_dkgray));
    self.scene.add(new UeDirectionalLight(30, 60));

    // Create raycaster and set from camera
    self.raycaster = new UeRaycaster();
    self.raycaster.setFromCamera(self.camera);
    
    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }
}
