/// @description Selection Manager - Handles multi-selection state for the editor
/// Centralizes all selection logic: single select, toggle (Ctrl+click), range (Shift+click),
/// rectangle select, and multi-select gizmo transforms.

function EditorSelectionManager() constructor {
    /// @type {Array<Struct>} All currently selected 3D assets
    self.selectedAssets = [];
    
    /// @type {Struct|undefined} The primary selected asset (last clicked, drives gizmo + inspector)
    self.primaryAsset = undefined;
    
    /// @type {Struct|undefined} The primary selected treeview item
    self.primaryTreeviewItem = undefined;
    
    /// @type {Array<Struct>} All selected treeview items (parallel to selectedAssets)
    self.selectedTreeviewItems = [];
    
    /// @type {Array<Struct>} Box helpers for each selected asset (besides primary)
    self.boxHelpers = [];
    
    /// @type {Array<Struct>} Stored initial offsets for multi-object gizmo transforms
    self.transformOffsets = [];
    
    /// @type {Array} Primary pivot initial state (for delta computation during multi-transforms)
    self.__pivotInitPos = [0, 0, 0];
    self.__pivotInitRot = [0, 0, 0, 1];
    self.__pivotInitScale = [1, 1, 1];
    
    // =========================================================================
    // CORE SELECTION API
    // =========================================================================
    
    /// Replace entire selection with a single asset (normal click)
    /// @param {Struct} asset The 3D asset to select
    /// @param {Struct} treeviewItem The corresponding treeview item
    function select(asset, treeviewItem = undefined) {
        // Clear existing selection visuals
        __clearTreeviewHighlights();
        __clearBoxHelpers();
        
        self.selectedAssets = [asset];
        self.primaryAsset = asset;
        self.primaryTreeviewItem = treeviewItem;
        self.selectedTreeviewItems = treeviewItem != undefined ? [treeviewItem] : [];
        
        // Highlight the selected treeview item
        if (treeviewItem != undefined) {
            treeviewItem.selected = true;
        }
        
        __dispatchSelectionChanged();
    }
    
    /// Toggle an asset in the selection (Ctrl+click behavior)
    /// @param {Struct} asset The 3D asset to toggle
    /// @param {Struct} treeviewItem The corresponding treeview item
    function toggle(asset, treeviewItem = undefined) {
        var idx = __indexOf(asset);
        
        if (idx >= 0) {
            // Remove from selection
            array_delete(self.selectedAssets, idx, 1);
            
            // Remove treeview item
            var tvIdx = __indexOfTreeviewItem(treeviewItem);
            if (tvIdx >= 0) array_delete(self.selectedTreeviewItems, tvIdx, 1);
            
            // Un-highlight
            if (treeviewItem != undefined) treeviewItem.selected = false;
            
            // Remove box helper for this asset
            __removeBoxHelperFor(asset);
            
            // If we removed the primary, pick the last one (or clear)
            if (self.primaryAsset == asset) {
                if (array_length(self.selectedAssets) > 0) {
                    self.primaryAsset = self.selectedAssets[array_length(self.selectedAssets) - 1];
                    self.primaryTreeviewItem = array_length(self.selectedTreeviewItems) > 0 
                        ? self.selectedTreeviewItems[array_length(self.selectedTreeviewItems) - 1] 
                        : undefined;
                } else {
                    self.primaryAsset = undefined;
                    self.primaryTreeviewItem = undefined;
                }
            }
        } else {
            // Add to selection
            array_push(self.selectedAssets, asset);
            if (treeviewItem != undefined) {
                array_push(self.selectedTreeviewItems, treeviewItem);
                treeviewItem.selected = true;
            }
            
            // Update primary to the newly added
            self.primaryAsset = asset;
            self.primaryTreeviewItem = treeviewItem;
            
            // Create box helper for previous primary (if any)
            __syncBoxHelpers();
        }
        
        __dispatchSelectionChanged();
    }
    
    /// Add an asset to the selection without changing primary (used by rect select)
    /// @param {Struct} asset The 3D asset to add
    /// @param {Struct} treeviewItem The corresponding treeview item
    function addToSelection(asset, treeviewItem = undefined) {
        if (__indexOf(asset) >= 0) return; // Already selected
        
        array_push(self.selectedAssets, asset);
        if (treeviewItem != undefined) {
            array_push(self.selectedTreeviewItems, treeviewItem);
            treeviewItem.selected = true;
        }
    }
    
    /// Set selection from an array of assets (used by rectangle select)
    /// @param {Array<Struct>} assets Array of assets to select
    /// @param {Struct} primary Optional primary asset (defaults to first)
    function setSelection(assets, primary = undefined) {
        __clearTreeviewHighlights();
        __clearBoxHelpers();
        
        self.selectedAssets = [];
        self.selectedTreeviewItems = [];
        
        for (var i = 0; i < array_length(assets); i++) {
            var asset = assets[i];
            array_push(self.selectedAssets, asset);
            
            var tvItem = asset[$ "__treeviewItem"];
            if (tvItem != undefined) {
                array_push(self.selectedTreeviewItems, tvItem);
                tvItem.selected = true;
            }
        }
        
        if (primary != undefined) {
            self.primaryAsset = primary;
            self.primaryTreeviewItem = primary[$ "__treeviewItem"];
        } else if (array_length(self.selectedAssets) > 0) {
            self.primaryAsset = self.selectedAssets[0];
            self.primaryTreeviewItem = self.selectedAssets[0][$ "__treeviewItem"];
        } else {
            self.primaryAsset = undefined;
            self.primaryTreeviewItem = undefined;
        }
        
        __syncBoxHelpers();
        __dispatchSelectionChanged();
    }
    
    /// Select a range of items in the treeview (Shift+click)
    /// @param {Struct} fromItem Starting treeview item
    /// @param {Struct} toItem Ending treeview item (the newly shift-clicked one)
    /// @param {Struct} treeview The UiTreeview containing the items
    function selectRange(fromItem, toItem, treeview) {
        if (fromItem == undefined || toItem == undefined) {
            // Fallback to single select
            if (toItem != undefined) select(toItem.asset, toItem);
            return;
        }
        
        // Collect all visible items in order via tree traversal
        var allItems = [];
        __collectVisibleItems(treeview.Items, allItems);
        
        // Find indices
        var fromIdx = -1;
        var toIdx = -1;
        for (var i = 0; i < array_length(allItems); i++) {
            if (allItems[i] == fromItem) fromIdx = i;
            if (allItems[i] == toItem) toIdx = i;
        }
        
        if (fromIdx < 0 || toIdx < 0) {
            select(toItem.asset, toItem);
            return;
        }
        
        // Get range bounds
        var rangeStart = min(fromIdx, toIdx);
        var rangeEnd = max(fromIdx, toIdx);
        
        // Clear current highlights
        __clearTreeviewHighlights();
        __clearBoxHelpers();
        
        self.selectedAssets = [];
        self.selectedTreeviewItems = [];
        
        for (var i = rangeStart; i <= rangeEnd; i++) {
            var item = allItems[i];
            if (item[$ "asset"] == undefined) continue;
            
            // Only select transformable 3D items (not Folders)
            var assetType = item.asset[$ "type"] ?? "";
            if (assetType == "Mesh" || assetType == "Object3D" || assetType == "Bone" ||
                assetType == "Scene") {
                array_push(self.selectedAssets, item.asset);
                array_push(self.selectedTreeviewItems, item);
                item.selected = true;
            }
        }
        
        // Primary is the newly clicked item
        self.primaryAsset = toItem.asset;
        self.primaryTreeviewItem = toItem;
        
        __syncBoxHelpers();
        __dispatchSelectionChanged();
    }
    
    /// Clear entire selection
    function clear() {
        __clearTreeviewHighlights();
        __clearBoxHelpers();
        
        self.selectedAssets = [];
        self.selectedTreeviewItems = [];
        self.primaryAsset = undefined;
        self.primaryTreeviewItem = undefined;
        self.transformOffsets = [];
        
        __dispatchSelectionChanged();
    }
    
    /// Check if an asset is currently selected
    /// @param {Struct} asset
    /// @returns {Bool}
    function isSelected(asset) {
        return __indexOf(asset) >= 0;
    }
    
    /// Get the number of selected assets
    /// @returns {Real}
    function count() {
        return array_length(self.selectedAssets);
    }
    
    /// Check if we have a multi-selection (more than 1)
    /// @returns {Bool}
    function isMultiSelect() {
        return array_length(self.selectedAssets) > 1;
    }
    
    // =========================================================================
    // MULTI-TRANSFORM SUPPORT
    // =========================================================================
    
    /// Store initial position offsets from gizmo target for multi-object transforms.
    /// Called when gizmo drag starts.
    function storeTransformOffsets() {
        self.transformOffsets = [];
        if (self.primaryAsset == undefined) return;
        
        var pivotPos = self.primaryAsset.position;
        
        // Store primary's initial state for delta computation
        self.__pivotInitPos = [pivotPos[0], pivotPos[1], pivotPos[2]];
        self.__pivotInitRot = quat_clone(self.primaryAsset.rotation);
        self.__pivotInitScale = [self.primaryAsset.scale[0], self.primaryAsset.scale[1], self.primaryAsset.scale[2]];
        
        for (var i = 0; i < array_length(self.selectedAssets); i++) {
            var asset = self.selectedAssets[i];
            if (asset == self.primaryAsset) continue;
            if (asset[$ "position"] == undefined) continue; // Skip non-transformable
            
            array_push(self.transformOffsets, {
                asset: asset,
                offsetX: asset.position[0] - pivotPos[0],
                offsetY: asset.position[1] - pivotPos[1],
                offsetZ: asset.position[2] - pivotPos[2],
                initScaleX: asset.scale[0],
                initScaleY: asset.scale[1],
                initScaleZ: asset.scale[2],
                initRotX: asset.rotation[0],
                initRotY: asset.rotation[1],
                initRotZ: asset.rotation[2],
                initRotW: asset.rotation[3],
            });
        }
    }
    
    /// Apply gizmo movement to all selected assets (called during gizmo drag).
    /// The primary asset is already moved by TransformControls; this syncs the rest.
    function applyMultiTransformMove() {
        if (!isMultiSelect() || self.primaryAsset == undefined) return;
        
        var pivotPos = self.primaryAsset.position;
        
        for (var i = 0; i < array_length(self.transformOffsets); i++) {
            var data = self.transformOffsets[i];
            var asset = data.asset;
            
            asset.position[@ 0] = pivotPos[0] + data.offsetX;
            asset.position[@ 1] = pivotPos[1] + data.offsetY;
            asset.position[@ 2] = pivotPos[2] + data.offsetZ;
            
            asset.matrixWorldNeedsUpdate = true;
            
            // Sync euler if available
            if (asset[$ "__rotationEuler"] != undefined) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
            }
            
            global.editor.assetManager.editAsset(asset, true, false);
        }
    }
    
    /// Apply gizmo rotation to all selected assets (rotate around pivot).
    /// Computes the delta quaternion from primary's initial to current rotation,
    /// then applies it to each secondary's initial rotation and orbits positions.
    function applyMultiTransformRotate() {
        if (!isMultiSelect() || self.primaryAsset == undefined) return;
        
        // Compute delta quaternion: deltaQ = currentRot * inverse(initRot)
        var _initRotInv = quat_clone(self.__pivotInitRot);
        quat_invert(_initRotInv);
        var _deltaQ = quat_clone(self.primaryAsset.rotation);
        quat_multiply(_deltaQ, _initRotInv);
        
        var pivotPos = self.primaryAsset.position;
        
        for (var i = 0; i < array_length(self.transformOffsets); i++) {
            var data = self.transformOffsets[i];
            var asset = data.asset;
            
            // 1. Rotate position offset around pivot
            var offsetVec = [data.offsetX, data.offsetY, data.offsetZ];
            var rotatedOffset = vec3_apply_quaternion(offsetVec, _deltaQ);
            
            asset.position[@ 0] = pivotPos[0] + rotatedOffset[0];
            asset.position[@ 1] = pivotPos[1] + rotatedOffset[1];
            asset.position[@ 2] = pivotPos[2] + rotatedOffset[2];
            
            // 2. Apply rotation delta to asset's initial rotation
            var newRot = quat_create();
            quat_set(newRot, data.initRotX, data.initRotY, data.initRotZ, data.initRotW);
            quat_premultiply(newRot, _deltaQ);
            quat_copy(asset.rotation, newRot);
            
            asset.matrixWorldNeedsUpdate = true;
            
            // Sync euler if available
            if (asset[$ "__rotationEuler"] != undefined) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
            }
            
            global.editor.assetManager.editAsset(asset, true, false);
        }
    }
    
    /// Apply gizmo scale to all selected assets.
    /// Computes scale ratio from primary's current vs initial scale,
    /// then applies it to each secondary's initial scale and scales position offsets.
    function applyMultiTransformScale() {
        if (!isMultiSelect() || self.primaryAsset == undefined) return;
        
        // Compute scale ratio per axis
        var ratioX = self.__pivotInitScale[0] != 0 ? (self.primaryAsset.scale[0] / self.__pivotInitScale[0]) : 1;
        var ratioY = self.__pivotInitScale[1] != 0 ? (self.primaryAsset.scale[1] / self.__pivotInitScale[1]) : 1;
        var ratioZ = self.__pivotInitScale[2] != 0 ? (self.primaryAsset.scale[2] / self.__pivotInitScale[2]) : 1;
        
        var pivotPos = self.primaryAsset.position;
        
        for (var i = 0; i < array_length(self.transformOffsets); i++) {
            var data = self.transformOffsets[i];
            var asset = data.asset;
            
            // Scale position offset from pivot
            asset.position[@ 0] = pivotPos[0] + data.offsetX * ratioX;
            asset.position[@ 1] = pivotPos[1] + data.offsetY * ratioY;
            asset.position[@ 2] = pivotPos[2] + data.offsetZ * ratioZ;
            
            // Apply scale ratio to initial scale
            asset.scale[@ 0] = data.initScaleX * ratioX;
            asset.scale[@ 1] = data.initScaleY * ratioY;
            asset.scale[@ 2] = data.initScaleZ * ratioZ;
            
            asset.matrixWorldNeedsUpdate = true;
            
            global.editor.assetManager.editAsset(asset, true, false);
        }
    }
    
    // =========================================================================
    // BOX HELPERS
    // =========================================================================
    
    /// Sync box helpers for all selected assets (uniform yellow).
    function __syncBoxHelpers() {
        __clearBoxHelpers();
        
        var sm = global.editor.sceneManager;
        var scene = global.editor.editorManager.activeScene;
        if (scene == undefined) return;

        for (var i = 0; i < array_length(self.selectedAssets); i++) {
            var asset = self.selectedAssets[i];
            if (asset == self.primaryAsset) continue; // primary uses EditorManager's boxHelper
            
            if (asset.type == "Mesh" || asset.type == "Object3D" || asset.type == "Bone") {
                // Only show box helpers if the asset is actually in the active scene
                var inScene = false;
                var curr = asset;
                while (curr != undefined) {
                    if (curr == scene) { inScene = true; break; }
                    curr = curr.parent;
                }
                
                if (!inScene) continue;

                var hasGeometry = asset[$ "geometry"] != undefined && asset.geometry[$ "vb"] != undefined;
                var hasChildren = array_length(asset.children) > 0;
                
                if (hasGeometry || hasChildren) {
                    var helper = new UeBoxHelper(asset, c_yellow);  // Same yellow as primary
                    with (helper.material) {
                        transparent = true;
                        depthWrite = false;
                        depthTest = false;
                    }
                    
                    // Update matrix for accurate bbox
                    global.editor.assetManager.updateAssetMatrix(asset);
                    
                    sm.scene.add(helper);
                    array_push(self.boxHelpers, { asset: asset, helper: helper });
                }
            }
        }
    }
    
    /// Remove box helper for a specific asset
    function __removeBoxHelperFor(asset) {
        var sm = global.editor.sceneManager;
        for (var i = array_length(self.boxHelpers) - 1; i >= 0; i--) {
            if (self.boxHelpers[i].asset == asset) {
                self.boxHelpers[i].helper.dispose();
                sm.scene.remove(self.boxHelpers[i].helper);
                array_delete(self.boxHelpers, i, 1);
            }
        }
    }
    
    /// Clear all secondary box helpers
    function __clearBoxHelpers() {
        var sm = global.editor.sceneManager;
        for (var i = 0; i < array_length(self.boxHelpers); i++) {
            self.boxHelpers[i].helper.dispose();
            sm.scene.remove(self.boxHelpers[i].helper);
        }
        self.boxHelpers = [];
    }
    
    /// Update box helpers (call each frame or when objects move)
    function updateBoxHelpers() {
        for (var i = 0; i < array_length(self.boxHelpers); i++) {
            self.boxHelpers[i].helper.update();
        }
    }
    
    // =========================================================================
    // TREEVIEW HELPERS
    // =========================================================================
    
    /// Clear all treeview selection highlights
    function __clearTreeviewHighlights() {
        for (var i = 0; i < array_length(self.selectedTreeviewItems); i++) {
            if (self.selectedTreeviewItems[i] != undefined) {
                self.selectedTreeviewItems[i].selected = false;
            }
        }
    }
    
    /// Collect all visible treeview items in display order (for range select)
    function __collectVisibleItems(container, result) {
        if (container[$ "children"] == undefined) return;
        
        var children = container.children;
        for (var i = 0; i < array_length(children); i++) {
            var child = children[i];
            if (child[$ "isScrollbar"] == true) continue;
            if (child[$ "display"] == false) continue;
            
            // If it's a UiTreeviewItem (has asset property), add it
            if (child[$ "asset"] != undefined || child[$ "assetType"] != undefined) {
                array_push(result, child);
                
                // Recurse into its Items container (if expanded)
                if (child[$ "collapsed"] == false && child[$ "Items"] != undefined) {
                    __collectVisibleItems(child.Items, result);
                }
            }
        }
    }
    
    // =========================================================================
    // INTERNAL HELPERS
    // =========================================================================
    
    function __indexOf(asset) {
        for (var i = 0; i < array_length(self.selectedAssets); i++) {
            if (self.selectedAssets[i] == asset) return i;
        }
        return -1;
    }
    
    function __indexOfTreeviewItem(item) {
        for (var i = 0; i < array_length(self.selectedTreeviewItems); i++) {
            if (self.selectedTreeviewItems[i] == item) return i;
        }
        return -1;
    }
    
    function __dispatchSelectionChanged() {
        global.editor.events.dispatch({ 
            type: "selectionChanged",
            selectedAssets: self.selectedAssets,
            primaryAsset: self.primaryAsset,
            count: array_length(self.selectedAssets),
        });
        global.UI.requestRedraw();
    }
}
