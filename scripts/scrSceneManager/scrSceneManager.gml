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
    
    /**
     * Handle mesh picking with mouse raycast
     * Performs contextual selection based on currently selected asset
     * @returns {bool} True if a mesh was selected, false otherwise
     */
    function handleMeshPicking() {
        if (!mouse_check_button_pressed(mb_left) || !global.UI.Main.Scene.hovered) return;

        var _mousePos = global.UE_MOUSE.get();
        var _editorManager = oSceneEditor.editorManager;

        /**
         * Pick System: 
         * - If there are no last hits, perform a new raycast
         * - If there are last hits, cycle through them
         */
        if (_editorManager.pickLastHits != undefined && _mousePos.x != _editorManager.pickLastPos.x || _mousePos.y != _editorManager.pickLastPos.y) {
            // Check if the mouse has moved
            if (_mousePos.x != _editorManager.pickLastPos.x || _mousePos.y != _editorManager.pickLastPos.y) {
                _editorManager.pickLastHits = undefined;
                return;
            }

            // Cycle through hits
            _editorManager.pickLastIndex = (_editorManager.pickLastIndex + 1) % array_length(_editorManager.pickLastHits);
        } else {
            // Perform a new raycast
            self.raycaster.setFromCamera(self.camera);
            
            _editorManager.pickLastHits = self.raycaster.intersectObjects(self.objects.children, true, true);
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastPos = _mousePos;
        }
        
        // Select the hit object (if available)
        if (array_length(_editorManager.pickLastHits) > 0) {
            var hitObject = _editorManager.pickLastHits[_editorManager.pickLastIndex].object;
            
            // Use the back-reference to get the treeview item directly
            if (hitObject[$ "__treeviewItem"] != undefined) {
                var treeview = global.UI.Main.Assets.Treeview;
                treeview.__onItemSelected(hitObject.__treeviewItem);
            }
        }
    }
    
    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }
}
