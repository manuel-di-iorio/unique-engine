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
        shouldHandleInput: function () {
            return global.UI.Main.Scene != undefined && global.UI.Main.Scene.hovered;
        },
        onChange: function () {
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
        onDrag: function () {
            // Sync rotation euler ONLY during gizmo interaction to update the inspector
            var asset = oSceneEditor.sceneManager.transformControls.object;
            if (oSceneEditor.sceneManager.transformControls.mode == "rotate" && asset != undefined && variable_struct_exists(asset, "__rotationEuler")) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
            }

            // Force Euler sync when dragging the gizmo to update the inspector
            oSceneEditor.assetManager.editAsset(asset, true, false);
        },
        onDragEnd: function () {
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

    function getSelectableRoot(object) {
        var lastSelectable = undefined;

        while (object != undefined && object[$ "isScene"] == undefined) {
            if (object == self.objects) break;

            if (object.selectable) {
                lastSelectable = object;
            }

            object = object.parent;
        }

        return lastSelectable;
    }

    /**
     * Get the selectable chain of an object (self + parents)
     * @param {UeObject3D} object The object to start from
     * @returns {Array<UeObject3D>} The selectable chain
     */
    function getSelectableChain(object) {
        var chain = [];
        while (object != undefined && object[$ "isScene"] == undefined) {
            // Avoid system containers
            if (object == self.objects) break;

            if (object.selectable) {
                array_insert(chain, 0, object);
            }
            object = object.parent;
        }
        return chain;
    }

    /**
 * Handle mesh picking with true Unity-like cycling
 * @returns {bool}
 */
    function handleMeshPicking() {

        if (!mouse_check_button_pressed(mb_left) || !global.UI.Main.Scene.hovered)
            return false;

        // Don't pick if interacting with gizmo
        if (self.transformControls.hoveredAxis != undefined || self.transformControls.dragging)
            return false;

        var _editorManager = oSceneEditor.editorManager;

        // 1. hits = raycastAllSorted(mousePos)
        self.camera.updateMatrixWorld();
        self.raycaster.setFromCamera(self.camera);
        
        // 1:1 Unity-like precise picking (triangle-level)
        var _oldPrecise = self.raycaster.params.Mesh.precise;
        self.raycaster.params.Mesh.precise = true;
        var _hits = self.raycaster.intersectObjects(self.objects.children, true, true);
        self.raycaster.params.Mesh.precise = _oldPrecise;

        // 2. Build unique selectable objects list (ALL HITS)
        var _selectableObjects = [];
        var _addedUuids = {}; 
        var _topSelectable = undefined;

        for (var i = 0, il = array_length(_hits); i < il; i++) {
            var _curr = _hits[i].object;
            var _chain = getSelectableChain(_curr);

            // Identify the topmost selectable of the first hit for Unity-like sticky cycling
            // We take the FIRST element (the most root-like) to maintain consistency across submeshes
            if (i == 0 && array_length(_chain) > 0) {
                _topSelectable = _chain[0];
            }

            for (var j = 0, jl = array_length(_chain); j < jl; j++) {
                var _obj = _chain[j];

                if (_addedUuids[$ _obj.uuid] == undefined) {
                    _addedUuids[$ _obj.uuid] = true;
                    array_push(_selectableObjects, _obj);
                }
            }
        }

        // 3. Clear if empty
        if (array_length(_selectableObjects) == 0) {
            _editorManager.pickLastHits = [];
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastTopSelectableUuid = undefined;
            
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
            return false;
        }

        // 4. Cycle logic (Unity-like)
        var _shouldCycle = false;
        var _lastTopUuid = _editorManager[$ "pickLastTopSelectableUuid"];
        if (_topSelectable != undefined && _lastTopUuid != undefined && _lastTopUuid == _topSelectable.uuid) {
            _shouldCycle = true;
        }

        if (_shouldCycle) {
            _editorManager.pickLastIndex = (_editorManager.pickLastIndex + 1) % array_length(_selectableObjects);
        } else {
            _editorManager.pickLastHits = _selectableObjects;
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastTopSelectableUuid = _topSelectable != undefined ? _topSelectable.uuid : undefined;
        }

        // 5. Determine final selection from the cycle
        var _finalSelection = _selectableObjects[_editorManager.pickLastIndex];

        // 8. Select the final object
        if (_finalSelection[$ "__treeviewItem"] != undefined) {
            var treeview = global.UI.Main.Assets.Treeview;
            treeview.__onItemSelected(_finalSelection.__treeviewItem);
        }

        global.UI.requestRedraw();
        return true;
    }


    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }

    /**
     * Performs a precise 1:1 raycast from the mouse position.
     * Returns the closest hit with detailed info (point, normal, uv, faceIndex).
     * @returns {Struct|Undefined}
     */
    function raycastFromMouse() {
        self.camera.updateMatrixWorld();
        self.raycaster.setFromCamera(self.camera);
        
        var _oldPrecise = self.raycaster.params.Mesh.precise;
        self.raycaster.params.Mesh.precise = true;
        var _hits = self.raycaster.intersectObjects(self.objects.children, true, true);
        self.raycaster.params.Mesh.precise = _oldPrecise;
        
        return (array_length(_hits) > 0) ? _hits[0] : undefined;
    }
}
