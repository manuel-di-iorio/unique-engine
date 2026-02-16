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

    function getSelectableRoot(object, _topMost) {
        var _result = undefined;

        while (object != undefined && object[$ "isScene"] == undefined) {

            if (object == self.objects)
                break;

            if (object.selectable) {
                if (_topMost == true) {
                    _result = object;
                } else {
                    return object; // <-- STOP at FIRST selectable
                }
            }

            object = object.parent;
        }

        return _result;
    }

    /**
     * Handle mesh picking - TRUE Unity-like behaviour
     * @returns {bool}
     */
    function handleMeshPicking() {
        if (!mouse_check_button_pressed(mb_left) || !global.UI.Main.Scene.hovered)
            return false;

        // Don't pick if interacting with gizmo
        if (self.transformControls.hoveredAxis != undefined || self.transformControls.dragging)
            return false;

        var _editorManager = oSceneEditor.editorManager;

        // --- RAYCAST ---
        self.camera.updateMatrixWorld();
        self.raycaster.setFromCamera(self.camera);

        var _oldPrecise = self.raycaster.params.Mesh.precise;
        self.raycaster.params.Mesh.precise = true;
        var _hits = self.raycaster.intersectObjects(self.objects.children, true, true);
        self.raycaster.params.Mesh.precise = _oldPrecise;

        // --- BUILD SELECTABLE LIST (ONE PER HIT, ORDER PRESERVED) ---
        var _selectableObjects = [];
        var _addedUuids = {};
        var _topSelectable = undefined;
        var _isAltPressed = keyboard_check(vk_alt);

        for (var i = 0; i < array_length(_hits); i++) {

            var _curr = _hits[i].object;
            var _selectable = getSelectableRoot(_curr, _isAltPressed);

            if (_selectable == undefined)
                continue;

            if (_addedUuids[$ _selectable.uuid] == undefined) {
                _addedUuids[$ _selectable.uuid] = true;
                array_push(_selectableObjects, _selectable);
            }

            if (i == 0) {
                _topSelectable = _selectable;
            }
        }

        // --- NO HITS ---
        if (array_length(_selectableObjects) == 0) {

            _editorManager.pickLastHits = [];
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastTopSelectableUuid = undefined;

            if (_editorManager.activeScene != undefined) {
                _editorManager.setActiveAsset(
                    _editorManager.activeScene,
                    _editorManager.activeSceneTreeviewItem
                );

                var treeview = global.UI.Main.Assets.Treeview;

                if (_editorManager.activeSceneTreeviewItem != undefined) {
                    treeview.selectedItem = _editorManager.activeSceneTreeviewItem;

                    treeview.Items.traverseChildren(
                        method({ treeview }, function (child) {
                            child.selected = (child == treeview.selectedItem);
                        })
                    );
                }
            } else {
                _editorManager.clearActiveAsset();
            }

            global.UI.requestRedraw();
            return false;
        }

        // --- CYCLE CHECK ---
        var _shouldCycle = false;

        var _lastTopUuid = _editorManager.pickLastTopSelectableUuid;
        var _lastHits = _editorManager.pickLastHits;

        if (_lastTopUuid != undefined && _topSelectable != undefined) {

            var _sameTop = (_lastTopUuid == _topSelectable.uuid);
            var _sameLength = (array_length(_lastHits) == array_length(_selectableObjects));
            var _sameOrder = true;

            if (_sameLength) {
                for (var i = 0; i < array_length(_selectableObjects); i++) {
                    if (_lastHits[i].uuid != _selectableObjects[i].uuid) {
                        _sameOrder = false;
                        break;
                    }
                }
            } else {
                _sameOrder = false;
            }

            _shouldCycle = (_sameTop && _sameLength && _sameOrder);
        }

        if (_shouldCycle) {
            _editorManager.pickLastIndex =
                (_editorManager.pickLastIndex + 1) % array_length(_selectableObjects);
        } else {
            _editorManager.pickLastHits = _selectableObjects;
            _editorManager.pickLastIndex = 0;
            _editorManager.pickLastTopSelectableUuid =
                (_topSelectable != undefined) ? _topSelectable.uuid : undefined;
        }

        // --- FINAL SELECTION ---
        var _finalSelection = _selectableObjects[_editorManager.pickLastIndex];

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
