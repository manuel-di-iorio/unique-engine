function editorTreeviewOnRemoveAsset(treeviewItem, isSelected) {
    var assetType = treeviewItem.assetType;
    var asset = treeviewItem.asset;
    var editorManager = global.editor.editorManager;
    var assetManager = global.editor.assetManager;
    
    // === UNDO: Capture parent info BEFORE any removal ===
    var _undoParentAsset = (asset != undefined && asset.parent != undefined) ? asset.parent : undefined;
    var _undoParentTreeviewItem = undefined;
    if (treeviewItem.parent != undefined && treeviewItem.parent.parent != undefined) {
        var _containerParent = treeviewItem.parent.parent;
        if (_containerParent[$ "assetType"] != undefined || _containerParent.type == "UiTreeview.Item") {
            _undoParentTreeviewItem = _containerParent;
        }
    }
    
    // === 1. CHIUSURA INSPECTOR SE ASSET SELEZIONATO ===
    if (isSelected || (asset != undefined && editorManager.activeAsset == asset)) {
        var keepScene = editorManager.activeScene != undefined;
        
        // If we are deleting the active scene itself, don't keep it
        if (assetType == "Scene" && asset == editorManager.activeScene) {
            keepScene = false;
        }
        
        editorManager.clearActiveAsset(keepScene);
    }
    
    // === 2. GESTIONE RIMOZIONE PER TIPO ===
    // NOTE: dispose() is intentionally skipped for undoable deletes.
    // Assets are kept alive for potential undo. Disposal happens when
    // the undo entry is evicted from history via cleanup().
    
    // Texture: remove from AssetManager
    if (assetType == "Texture" && asset != undefined) {
        editorTreeviewUtil_removeTextureFromMaterials(asset);
        assetManager.removeAsset("Texture", asset);
    }
    
    // Material: remove from AssetManager
    else if (assetType == "Material" && asset != undefined) {
        editorTreeviewUtil_removeMaterialFromObjects(asset);
        assetManager.removeAsset("Material", asset);
    }
    
    // Mesh/Model: remove from parent or global list
    else if (assetType == "Mesh" && asset != undefined) {
        // Recursively remove children (if present in treeview)
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);

        // Unregister from prefab instances list (if this is a scene instance)
        editorTreeviewUtil_unregisterInstance(asset);
        // If this is a library prefab, detach all its instances
        if (asset[$ "prefab"] == undefined) editorTreeviewUtil_detachPrefabInstances(asset);

        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
            // Track the deletion
            assetManager.__trackChange("delete", asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Mesh", asset);
        }
    }
    
    // Object3D: remove from parent or global list
    else if (assetType == "Object3D" && asset != undefined) {
        // Recursively remove children (if present in treeview)
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);

        // Unregister from prefab instances list (if this is a scene instance)
        editorTreeviewUtil_unregisterInstance(asset);
        // If this is a library prefab, detach all its instances
        if (asset[$ "prefab"] == undefined) editorTreeviewUtil_detachPrefabInstances(asset);

        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            // Track the deletion BEFORE removing, so we can detect the parent scene
            assetManager.__trackChange("delete", asset);
            asset.parent.remove(asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Object3D", asset);
        }
    }
    
    // Scene: delete the scene (children will be automatically deleted)
    else if (assetType == "Scene" && asset != undefined) {
        // Recursively remove children (if present in treeview)
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);

        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
            // Track the deletion
            assetManager.__trackChange("delete", asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Scene", asset);
        }
    }
    
    // Folder: recursively remove all children
    else if (assetType == "Folder") {
        // Iterate on treeview item children to clean their assets
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);
        
        // Remove the folder from AssetManager
        assetManager.removeAsset("Folder", asset);
    }
    
    // === UNDO: Push delete command ===
    if (asset != undefined) {
        var _undoCmd = new UndoCommandTreeview("delete", assetType, asset, _undoParentAsset, _undoParentTreeviewItem);
        // Add cleanup callback for when the command is evicted from history
        _undoCmd.cleanup = method(_undoCmd, function() {
            // Only dispose if the asset is NOT currently in the scene
            if (self.asset != undefined && self.asset.parent == undefined) {
                if (struct_exists(self.asset, "dispose")) {
                    self.asset.dispose(true);
                }
            }
        });
        global.editor.undoManager.push(_undoCmd);
    }
}
// Helper functions moved to scrEditorTreeviewUtils
