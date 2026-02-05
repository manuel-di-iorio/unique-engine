/// @description Scene Manager - Manages 3D scene, camera, renderer, and controls
function SceneManager() constructor {
    self.renderer = new UeRenderer({
      toneMapping: UE_TONE_MAPPING.REINHARD,
      shadowMap: {
        enabled: true
      }
    });
    self.camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 }).use();
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
    self.objects = new UeObject3D({ matrixAutoUpdate: false });
    self.transformControls = new UeTransformControls(self.camera, {
        view: 1,
        onDrag: function() {
            // Sync rotation euler ONLY during gizmo interaction to update the inspector
            var asset = oSceneEditor.sceneManager.transformControls.object;
            if (oSceneEditor.sceneManager.transformControls.mode == "rotate" && asset != undefined && variable_struct_exists(asset, "__rotationEuler")) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
            }

            // Force Euler sync when dragging the gizmo to update the inspector
            oSceneEditor.assetManager.editAsset(asset, true, false);
        },
        onDragEnd: function() {
            global.UI.requestRedraw();
            oSceneEditor.events.dispatch({ type: "assetChanged"/*, data: asset*/ });
        }
    });

    self.boxHelper = new UeBoxHelper();
    with (self.boxHelper.material) {
        transparent = true;
        depthWrite = false;
        depthTest = false;
    }
    
    // Assimp loader
    self.assimp = new UeAssimpLoader({ canFreeze: false });
    
    self.scene.add(self.grid, self.objects, self.boxHelper);
    
    // Configure mouse
    global.UE_MOUSE.view = 1;
    
    // Test lights
    var dirLight = new UeDirectionalLight(c_ltgray, 1, { x: -300, y: 300, z: 200, castShadow: true });
    self.scene.add(new UeAmbientLight(c_gray, { name: "UeAmbientLight", matrixAutoUpdate: false }), dirLight);

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

        // Don't pick objects if the user is interacting with the gizmo
        if (self.transformControls.hoveredAxis != undefined || self.transformControls.dragging) return;

        var _mousePos = global.UE_MOUSE.get();
        var _editorManager = oSceneEditor.editorManager;

        /**
         * Pick System: 
         * - If there are no last hits, perform a new raycast
         * - If there are last hits, cycle through them
         */
        var _prevHitsLength = array_length(_editorManager.pickLastHits);
        if (_prevHitsLength && _mousePos.x == _editorManager.pickLastPos.x && _mousePos.y == _editorManager.pickLastPos.y) {
            // Cycle through hits
            _editorManager.pickLastIndex = (_editorManager.pickLastIndex + 1) % _prevHitsLength;
        } else {
            // Perform a new raycast
            self.camera.updateMatrixWorld();
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
