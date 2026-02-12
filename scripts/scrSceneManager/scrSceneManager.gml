/// @description Scene Manager - Manages 3D scene, camera, renderer, and controls
function SceneManager() constructor {
    self.renderer = new UeRenderer({
      toneMapping: UE_TONE_MAPPING.REINHARD,
      shadowMap: {
        enabled: true
      }
    });
    self.camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 }).use();
    // Note: UI.Main.Scene doesn't exist yet at this point, will be set later
    self.orbit = new UeOrbitControls(self.camera, undefined, {
        shouldHandleInput: function() {
            return global.UI.Main.Scene != undefined && global.UI.Main.Scene.hovered;
        },
        onChange: function() {
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        }
    });
    self.scene = new UeScene();
    
    // Helpers
    self.grid = new UeGridHelper(10000, 50);
    self.gridEnabled = true;
    self.gridSnapEnabled = false;
    self.gridSnapSize = 10;
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
        var _activeAsset = _editorManager.activeAsset;

        // 1. hits = raycastAllSorted(mousePos)
        self.camera.updateMatrixWorld();
        self.raycaster.setFromCamera(self.camera);
        var _hits = self.raycaster.intersectObjects(self.objects.children, true, true);

        // 2. Build unique selectable objects list (ALL HITS)
        var _selectableObjects = [];
        var _addedUuids = {}; 

        for (var i = 0, il = array_length(_hits); i < il; i++) {
            var _curr = _hits[i].object;
            if (_addedUuids[$ _curr.uuid] == undefined) {
                _addedUuids[$ _curr.uuid] = true;
                array_push(_selectableObjects, _curr);
            }
        }

        // 3. Clear if empty
        if (array_length(_selectableObjects) == 0) {
            _editorManager.pickLastHits = [];
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastPos = _mousePos;
            
            // If we have an active scene, revert selection to the scene instead of clearing everything
            if (_editorManager.activeScene != undefined) {
                 _editorManager.setActiveAsset(_editorManager.activeScene, _editorManager.activeSceneTreeviewItem);
                 
                 // Update treeview selection visually without triggering side effects
                 var treeview = global.UI.Main.Assets.Treeview;
                 if (_editorManager.activeSceneTreeviewItem != undefined) {
                     treeview.selectedItem = _editorManager.activeSceneTreeviewItem;
                     treeview.Items.traverseChildren(method({ treeview }, function(child) {
                         child.selected = (child == treeview.selectedItem);
                     }));
                 }
            } else {
                _editorManager.clearActiveAsset();
            }

            global.UI.requestRedraw();
            return;
        }

        // 4. Cycle logic (between different hits)
        var _shouldCycle = false;
        if (_editorManager.pickLastPos != undefined) {
             var _dist = point_distance(_mousePos.x, _mousePos.y, _editorManager.pickLastPos.x, _editorManager.pickLastPos.y);
             if (_dist < 2) {
                 var _prevHits = _editorManager.pickLastHits;
                 if (array_length(_selectableObjects) == array_length(_prevHits)) {
                     _shouldCycle = true;
                     for (var i = 0, l = array_length(_selectableObjects); i < l; i++) {
                         if (_selectableObjects[i] != _prevHits[i]) {
                             _shouldCycle = false;
                             break;
                         }
                     }
                 }
             }
        }

        if (_shouldCycle) {
            _editorManager.pickLastIndex = (_editorManager.pickLastIndex + 1) % array_length(_selectableObjects);
        } else {
            _editorManager.pickLastHits = _selectableObjects;
            _editorManager.pickLastIndex = 0;
        }

        // 5. Determine final selection from the cycle
        var _finalSelection = _selectableObjects[_editorManager.pickLastIndex];

        // 7. Update last click pixel
        _editorManager.pickLastPos = _mousePos;

        // 8. Select the final object
        if (_finalSelection[$ "__treeviewItem"] != undefined) {
            var treeview = global.UI.Main.Assets.Treeview;
            treeview.__onItemSelected(_finalSelection.__treeviewItem);
        }
    }
    
    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }
}
