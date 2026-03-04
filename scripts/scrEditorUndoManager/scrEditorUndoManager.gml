/// @description Undo Manager - Command pattern undo/redo system for the editor

function UndoManager() constructor {
    self.undoStack = [];
    self.redoStack = [];
    self.maxHistory = 50;
    
    /// Push a command onto the undo stack (clears redo stack)
    function push(command) {
        array_push(self.undoStack, command);
        
        // Clear redo stack (new action invalidates redo history)
        self.redoStack = [];
        
        // Evict oldest entries if over limit
        while (array_length(self.undoStack) > self.maxHistory) {
            var evicted = self.undoStack[0];
            array_delete(self.undoStack, 0, 1);
            // If the evicted command has a cleanup method, call it
            if (variable_struct_exists(evicted, "cleanup")) {
                evicted.cleanup();
            }
        }
    }
    
    /// Undo the last action
    function undo() {
        if (array_length(self.undoStack) == 0) return;
        
        var command = array_pop(self.undoStack);
        command.undo();
        array_push(self.redoStack, command);
    }
    
    /// Redo the last undone action
    function redo() {
        if (array_length(self.redoStack) == 0) return;
        
        var command = array_pop(self.redoStack);
        command.redo();
        array_push(self.undoStack, command);
    }
    
    /// Check if undo is available
    function canUndo() {
        return array_length(self.undoStack) > 0;
    }
    
    /// Check if redo is available
    function canRedo() {
        return array_length(self.redoStack) > 0;
    }
    
    /// Clear all history
    function clear() {
        self.undoStack = [];
        self.redoStack = [];
    }
}

// =====================================================
// COMMAND: Property Change (Inspector fields)
// =====================================================

/// @param {Struct} asset The asset being modified
/// @param {String} field The field name being changed
/// @param {Any} oldValue The value before the change
/// @param {Any} newValue The value after the change
function UndoCommandPropertyChange(asset, field, oldValue, newValue) constructor {
    self.asset = asset;
    self.field = field;
    self.oldValue = oldValue;
    self.newValue = newValue;
    
    function undo() {
        self.asset[$ self.field] = self.oldValue;
        global.editor.assetManager.editAsset(self.asset);
        __refreshInspector();
    }
    
    function redo() {
        self.asset[$ self.field] = self.newValue;
        global.editor.assetManager.editAsset(self.asset);
        __refreshInspector();
    }
    
    function __refreshInspector() {
        var inspector = global.editor.editorManager.inspector;
        if (inspector != undefined && inspector.asset == self.asset) {
            inspector.inspect(self.asset);
        }
        global.UI.requestRedraw();
    }
}

// =====================================================
// COMMAND: Transform Change (Gizmo & Inspector XYZ)
// =====================================================

/// @param {Array} entries Array of { asset, oldPos, oldRot, oldScale, newPos, newRot, newScale }
function UndoCommandTransform(entries) constructor {
    self.entries = entries;
    
    function undo() {
        for (var i = 0; i < array_length(self.entries); i++) {
            var e = self.entries[i];
            vec3_copy(e.asset.position, e.oldPos);
            quat_copy(e.asset.rotation, e.oldRot);
            vec3_copy(e.asset.scale, e.oldScale);
            
            // Sync euler
            if (e.asset[$ "__rotationEuler"] != undefined) {
                euler_set_from_quaternion(e.asset.__rotationEuler, e.asset.rotation);
            }
            
            e.asset.matrixWorldNeedsUpdate = true;
            if (e.asset[$ "updateWorldMatrix"] != undefined) {
                e.asset.updateWorldMatrix(true, false);
            }
            global.editor.assetManager.editAsset(e.asset, true, false);
        }
        __afterTransform();
    }
    
    function redo() {
        for (var i = 0; i < array_length(self.entries); i++) {
            var e = self.entries[i];
            vec3_copy(e.asset.position, e.newPos);
            quat_copy(e.asset.rotation, e.newRot);
            vec3_copy(e.asset.scale, e.newScale);
            
            // Sync euler
            if (e.asset[$ "__rotationEuler"] != undefined) {
                euler_set_from_quaternion(e.asset.__rotationEuler, e.asset.rotation);
            }
            
            e.asset.matrixWorldNeedsUpdate = true;
            if (e.asset[$ "updateWorldMatrix"] != undefined) {
                e.asset.updateWorldMatrix(true, false);
            }
            global.editor.assetManager.editAsset(e.asset, true, false);
        }
        __afterTransform();
    }
    
    function __afterTransform() {
        // Update box helper
        var edMgr = global.editor.editorManager;
        var sm = global.editor.sceneManager;
        sm.boxHelper.dispose();
        
        if (edMgr.gizmoTarget != undefined) {
            var gt = edMgr.gizmoTarget;
            var hasGeometry = gt[$ "geometry"] != undefined && gt.geometry[$ "vb"] != undefined;
            var hasChildren = array_length(gt.children) > 0;
            if (hasGeometry || hasChildren) {
                sm.boxHelper.object = gt;
                if (edMgr.activeScene != undefined) global.editor.assetManager.updateAssetMatrix(edMgr.activeScene);
                if (gt != edMgr.activeScene) global.editor.assetManager.updateAssetMatrix(gt);
            }
        }
        
        // Refresh inspector
        var inspector = edMgr.inspector;
        if (inspector != undefined && inspector.asset != undefined) {
            inspector.inspect(inspector.asset);
        }
        
        global.editor.events.dispatch({ type: "assetChanged" });
        global.UI.requestRedraw();
    }
}

// =====================================================
// COMMAND: Treeview Create/Delete (Create, Duplicate, Delete)
// =====================================================

/// @param {String} action "create" or "delete"
/// @param {String} assetType The asset type string (e.g. "Object3D", "Mesh", etc.)
/// @param {Struct} asset The asset struct (kept alive for undo)
/// @param {Struct|undefined} parentAsset The parent asset (or undefined for root)
/// @param {Struct|undefined} parentTreeviewItem The parent treeview item for re-insertion
function UndoCommandTreeview(action, assetType, asset, parentAsset, parentTreeviewItem) constructor {
    self.action = action;
    self.assetType = assetType;
    self.asset = asset;
    self.parentAsset = parentAsset;
    self.parentTreeviewItem = parentTreeviewItem;
    
    function undo() {
        if (self.action == "create") {
            // Undo create = remove the asset
            __removeAsset();
        } else if (self.action == "delete") {
            // Undo delete = re-add the asset
            __addAsset();
        }
    }
    
    function redo() {
        if (self.action == "create") {
            // Redo create = re-add the asset
            __addAsset();
        } else if (self.action == "delete") {
            // Redo delete = re-remove the asset
            __removeAsset();
        }
    }
    
    function __addAsset() {
        var treeview = (self.assetType == "Scene") ? global.UI.Main.Assets.Treeview : global.UI.Main.Resources.Treeview;
        var assetManager = global.editor.assetManager;
        
        // Re-add to asset manager
        assetManager.addAsset(self.assetType, self.asset, self.parentAsset);
        
        // Re-create treeview item hierarchy
        var newItem = __createTreeviewItemRecursive(treeview, self.asset, self.parentTreeviewItem);
        
        // Select the re-added item
        treeview.__onItemSelected(newItem, false);
        global.UI.requestRedraw();
    }
    
    function __removeAsset() {
        var treeview = (self.assetType == "Scene") ? global.UI.Main.Assets.Treeview : global.UI.Main.Resources.Treeview;
        var assetManager = global.editor.assetManager;
        var editorManager = global.editor.editorManager;
        
        // Clear selection if this asset is selected
        if (editorManager.activeAsset == self.asset || editorManager.gizmoTarget == self.asset) {
            var keepScene = editorManager.activeScene != undefined && self.assetType != "Scene";
            editorManager.clearActiveAsset(keepScene);
        }
        
        // Remove the treeview item
        var tvItem = self.asset[$ "__treeviewItem"];
        if (tvItem != undefined) {
            var _parent = tvItem.parent;
            tvItem.destroy();
            if (_parent != undefined && _parent.parent != undefined) {
                var parentItem = _parent.parent;
                if (variable_struct_exists(parentItem, "__updateArrowVisibility")) {
                    parentItem.__updateArrowVisibility();
                }
            }
        }
        
        // Remove from 3D parent
        if (self.parentAsset != undefined && self.asset.parent == self.parentAsset) {
            self.parentAsset.remove(self.asset);
        }
        
        // Remove from asset manager
        assetManager.removeAsset(self.assetType, self.asset);
        
        global.UI.requestRedraw();
    }
    
    function __createTreeviewItemRecursive(treeview, asset, parentUiItem) {
        var icon = undefined;
        var type = asset[$ "type"] ?? "Object3D";
        
        if (type == "Folder") icon = sprUiFolder;
        else if (type == "Mesh" || type == "Object3D") icon = sprUiObject;
        else if (type == "Material") icon = sprUiMaterial;
        else if (type == "Texture") icon = sprUiTexture;
        else if (type == "Scene") icon = sprUiScene;
        
        var newItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
            treeview: treeview,
            assetType: type,
            type: type,
            icon: icon,
            asset: asset,
            name: asset.name
        });
        
        if (parentUiItem != undefined) {
            parentUiItem.addChild(newItem);
        } else {
            treeview.Items.add(newItem);
        }
        
        // Recurse for children
        if (variable_struct_exists(asset, "children")) {
            for (var i = 0; i < array_length(asset.children); i++) {
                __createTreeviewItemRecursive(treeview, asset.children[i], newItem);
            }
        }
        
        return newItem;
    }
}
