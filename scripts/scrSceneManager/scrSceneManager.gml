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
            global.editor.projectManager.saver.saveEditorSettings(global.editor.projectManager);
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
        onDragStart: function () {
            // Store offsets for multi-object transforms
            var _selMgr = global.editor.selectionManager;
            if (_selMgr != undefined && _selMgr.isMultiSelect()) {
                _selMgr.storeTransformOffsets();
            }
        },
        onDrag: function () {
            // Sync rotation euler ONLY during gizmo interaction to update the inspector
            var asset = global.editor.sceneManager.transformControls.object;
            if (global.editor.sceneManager.transformControls.mode == "rotate" && asset != undefined && variable_struct_exists(asset, "__rotationEuler")) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
            }

            // Force Euler sync when dragging the gizmo to update the inspector
            global.editor.assetManager.editAsset(asset, true, false);
            
            // Apply transform to all selected objects (multi-select)
            var _selMgr = global.editor.selectionManager;
            if (_selMgr != undefined && _selMgr.isMultiSelect()) {
                var _mode = global.editor.sceneManager.transformControls.mode;
                switch (_mode) {
                    case "move": _selMgr.applyMultiTransformMove(); break;
                    case "rotate": _selMgr.applyMultiTransformRotate(); break;
                    case "scale": _selMgr.applyMultiTransformScale(); break;
                }
            }
        },
        onDragEnd: function () {
            global.UI.requestRedraw();
            global.editor.events.dispatch({ type: "assetChanged"/*, data: asset*/ });
            
            // Mark all selected assets as changed
            var _selMgr = global.editor.selectionManager;
            if (_selMgr != undefined && _selMgr.isMultiSelect()) {
                for (var i = 0; i < array_length(_selMgr.selectedAssets); i++) {
                    global.editor.assetManager.editAsset(_selMgr.selectedAssets[i]);
                }
            }
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

    // Rectangle selection state
    self.rectSelectActive = false;
    self.rectSelectStartX = 0;
    self.rectSelectStartY = 0;
    self.rectSelectEndX = 0;
    self.rectSelectEndY = 0;
    self.__rectSelectPending = false;
    self.__rectSelectPendingX = 0;
    self.__rectSelectPendingY = 0;

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
        
        // Don't pick if rectangle select is active
        if (self.rectSelectActive) return false;

        var _editorManager = global.editor.editorManager;
        var _selMgr = global.editor.selectionManager;
        var _isShiftPressed = keyboard_check(vk_shift);
        var _isCtrlPressed = keyboard_check(vk_control);

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

            // Shift/Ctrl click on empty space: don't clear multi-selection
            if (_isShiftPressed || _isCtrlPressed) {
                global.UI.requestRedraw();
                return false;
            }

            if (_editorManager.activeScene != undefined) {
                _selMgr.clear();
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

        // --- CYCLE CHECK (only for non-shift clicks) ---
        if (!_isShiftPressed && !_isCtrlPressed) {
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
        }

        // --- FINAL SELECTION ---
        var _finalSelection;
        if (_isShiftPressed || _isCtrlPressed) {
            _finalSelection = _selectableObjects[0]; // Use top hit for shift/ctrl
        } else {
            _finalSelection = _selectableObjects[_editorManager.pickLastIndex];
        }

        if (_finalSelection[$ "__treeviewItem"] != undefined) {
            var treeview = global.UI.Main.Assets.Treeview;
            
            if (_isShiftPressed || _isCtrlPressed) {
                // Ctrl = toggle, Shift = additive (add if not selected, no-op if already selected)
                if (_isCtrlPressed) {
                    _selMgr.toggle(_finalSelection, _finalSelection.__treeviewItem);
                } else {
                    // Shift: add to selection (don't remove if already there)
                    if (!_selMgr.isSelected(_finalSelection)) {
                        _selMgr.toggle(_finalSelection, _finalSelection.__treeviewItem);
                    }
                }
                
                // Update editor to track primary
                var primary = _selMgr.primaryAsset;
                var primaryTvItem = _selMgr.primaryTreeviewItem;
                treeview.selectedItem = primaryTvItem;
                
                if (primary != undefined && primaryTvItem != undefined) {
                    if (primary.type == "Mesh" || primary.type == "Object3D" || primary.type == "Bone") {
                        var rootAsset = primary;
                        var currSearch = primary;
                        while (currSearch.parent != undefined) {
                            var parentType = currSearch.parent[$ "type"];
                            if (parentType == "Scene") { rootAsset = currSearch.parent; break; }
                            if (parentType == "Folder") { rootAsset = currSearch; break; }
                            currSearch = currSearch.parent;
                            if (currSearch.parent == undefined) rootAsset = currSearch;
                        }
                        _editorManager.setActiveAsset(rootAsset, primaryTvItem, primary);
                    }
                }
                
                // Update inspector for multi-select
                if (_editorManager.inspector != undefined) {
                    if (_selMgr.count() > 1) {
                        _editorManager.inspector.inspectMultiple(_selMgr.selectedAssets, _selMgr.primaryAsset);
                    } else if (_selMgr.count() == 1 && primary != undefined) {
                        _editorManager.inspector.inspect(primary, false);
                    } else {
                        _editorManager.inspector.close();
                    }
                }
            } else {
                // Single select: normal flow through treeview
                treeview.__onItemSelected(_finalSelection.__treeviewItem);
            }
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

    // =========================================================================
    // RECTANGLE (MARQUEE) SELECTION
    // =========================================================================
    
    /// Begin rectangle selection (called on mouse press in the scene viewport)
    function rectSelectBegin(mouseX, mouseY) {
        self.rectSelectActive = true;
        self.rectSelectStartX = mouseX;
        self.rectSelectStartY = mouseY;
        self.rectSelectEndX = mouseX;
        self.rectSelectEndY = mouseY;
    }
    
    /// Update rectangle selection (called each frame during drag)
    function rectSelectUpdate(mouseX, mouseY) {
        if (!self.rectSelectActive) return;
        self.rectSelectEndX = mouseX;
        self.rectSelectEndY = mouseY;
    }
    
    /// End rectangle selection and finalize the selection
    function rectSelectEnd() {
        if (!self.rectSelectActive) return;
        self.rectSelectActive = false;
        
        var _editorManager = global.editor.editorManager;
        var _selMgr = global.editor.selectionManager;
        
        // Calculate screen-space rectangle bounds (normalized)
        var x1 = min(self.rectSelectStartX, self.rectSelectEndX);
        var y1 = min(self.rectSelectStartY, self.rectSelectEndY);
        var x2 = max(self.rectSelectStartX, self.rectSelectEndX);
        var y2 = max(self.rectSelectStartY, self.rectSelectEndY);
        
        // Ignore tiny rectangles (accidental clicks)
        if (abs(x2 - x1) < 5 && abs(y2 - y1) < 5) return;
        
        // Collect all selectable objects that are within the rectangle
        var selectedObjects = [];
        __collectObjectsInRect(self.objects.children, x1, y1, x2, y2, selectedObjects);
        
        if (array_length(selectedObjects) == 0) {
            // Empty rectangle: if no modifier key, clear selection
            if (!keyboard_check(vk_shift) && !keyboard_check(vk_control)) {
                _editorManager.clearActiveAsset(true);
            }
            return;
        }
        
        // If Shift held, add to existing selection (merge)
        if (keyboard_check(vk_shift)) {
            // Merge: existing + new (avoid duplicates)
            var mergedAssets = [];
            array_copy(mergedAssets, 0, _selMgr.selectedAssets, 0, array_length(_selMgr.selectedAssets));
            for (var i = 0; i < array_length(selectedObjects); i++) {
                if (!_selMgr.isSelected(selectedObjects[i])) {
                    array_push(mergedAssets, selectedObjects[i]);
                }
            }
            var lastObj = selectedObjects[array_length(selectedObjects) - 1];
            _selMgr.setSelection(mergedAssets, lastObj);
        } else {
            // Replace selection
            _selMgr.setSelection(selectedObjects);
        }
        
        // Update EditorManager to track primary
        var primary = _selMgr.primaryAsset;
        var primaryTvItem = _selMgr.primaryTreeviewItem;
        
        if (primary != undefined) {
            var treeview = global.UI.Main.Assets.Treeview;
            treeview.selectedItem = primaryTvItem;
            
            if (primary.type == "Mesh" || primary.type == "Object3D" || primary.type == "Bone") {
                var rootAsset = primary;
                var currSearch = primary;
                while (currSearch.parent != undefined) {
                    var parentType = currSearch.parent[$ "type"];
                    if (parentType == "Scene") { rootAsset = currSearch.parent; break; }
                    if (parentType == "Folder") { rootAsset = currSearch; break; }
                    currSearch = currSearch.parent;
                    if (currSearch.parent == undefined) rootAsset = currSearch;
                }
                _editorManager.setActiveAsset(rootAsset, primaryTvItem, primary);
            }
            
            if (_editorManager.inspector != undefined) {
                if (_selMgr.count() > 1) {
                    _editorManager.inspector.inspectMultiple(_selMgr.selectedAssets, _selMgr.primaryAsset);
                } else {
                    _editorManager.inspector.inspect(primary, false);
                }
            }
        }
        
        global.UI.requestRedraw();
    }
    
    /// Draw rectangle selection overlay (called from Draw GUI)
    function rectSelectDraw() {
        if (!self.rectSelectActive) return;
        
        var x1 = min(self.rectSelectStartX, self.rectSelectEndX);
        var y1 = min(self.rectSelectStartY, self.rectSelectEndY);
        var x2 = max(self.rectSelectStartX, self.rectSelectEndX);
        var y2 = max(self.rectSelectStartY, self.rectSelectEndY);
        
        // Draw filled semi-transparent rectangle
        draw_set_alpha(0.15);
        draw_set_color($FF9933); // Light blue fill
        draw_rectangle(x1, y1, x2, y2, false);
        
        // Draw border
        draw_set_alpha(0.8);
        draw_set_color($FFCC66);
        draw_rectangle(x1, y1, x2, y2, true);
        
        draw_set_alpha(1.0);
        draw_set_color(c_white);
    }
    
    /// Project a 3D world position to 2D screen coordinates (viewport-space).
    /// Uses vec3_project for consistency with UeMouse.worldToScreen.
    /// @returns {Array} [screenX, screenY] or undefined if behind camera
    function __worldToScreen(worldPos) {
        var temp = vec3_create(worldPos[0], worldPos[1], worldPos[2]);
        vec3_project(temp, self.camera);
        
        // Check if behind camera (NDC Z out of range)
        if (temp[2] < -1 || temp[2] > 1) return undefined;
        
        // Map NDC to viewport screen coords (same as UeMouse.worldToScreen)
        var vpX = view_xport[1];
        var vpY = view_yport[1];
        var vpW = view_wport[1];
        var vpH = view_hport[1];
        
        return [
            vpX + (temp[0] * 0.5 + 0.5) * vpW,
            vpY + (temp[1] * 0.5 + 0.5) * vpH
        ];
    }
    
    /// Collect all selectable objects whose screen-projected center is within the rectangle.
    /// Uses getSelectableRoot (like raycasting) to resolve the correct selectable ancestor.
    function __collectObjectsInRect(children, rx1, ry1, rx2, ry2, result) {
        for (var i = 0; i < array_length(children); i++) {
            var obj = children[i];
            
            // Project world position to screen
            if (obj[$ "matrixWorld"] != undefined) {
                var worldPos = [obj.matrixWorld[12], obj.matrixWorld[13], obj.matrixWorld[14]];
                var screenPos = __worldToScreen(worldPos);
                
                if (screenPos != undefined) {
                    if (screenPos[0] >= rx1 && screenPos[0] <= rx2 && 
                        screenPos[1] >= ry1 && screenPos[1] <= ry2) {
                        // Resolve selectable root (same as raycasting)
                        var selRoot = getSelectableRoot(obj, false);
                        if (selRoot != undefined) {
                            // Deduplicate
                            var already = false;
                            for (var j = 0; j < array_length(result); j++) {
                                if (result[j] == selRoot) { already = true; break; }
                            }
                            if (!already) {
                                array_push(result, selRoot);
                            }
                        }
                    }
                }
            }
            
            // Always recurse children (dedup handles parent+child via getSelectableRoot)
            if (obj[$ "children"] != undefined && array_length(obj.children) > 0) {
                __collectObjectsInRect(obj.children, rx1, ry1, rx2, ry2, result);
            }
        }
    }
}
