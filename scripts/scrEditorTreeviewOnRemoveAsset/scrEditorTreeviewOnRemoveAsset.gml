function editorTreeviewOnRemoveAsset(treeviewItem, isSelected) {
    var assetType = treeviewItem.assetType;
    var asset = treeviewItem.asset;
    var editorManager = global.editor.editorManager;
    var assetManager = global.editor.assetManager;
    
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

        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
            // Track the deletion
            assetManager.__trackChange("delete", asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Mesh", asset);
        }
        
        // Dispose resources
        if (asset != undefined && struct_exists(asset, "dispose")) {
            asset.dispose(true);
        }
    }
    
    // Object3D: remove from parent or global list
    else if (assetType == "Object3D" && asset != undefined) {
        // Recursively remove children (if present in treeview)
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);

        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            // Track the deletion BEFORE removing, so we can detect the parent scene
            assetManager.__trackChange("delete", asset);
            asset.parent.remove(asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Object3D", asset);
        }
        
        // Dispose resources
        if (asset != undefined && struct_exists(asset, "dispose")) {
            asset.dispose(true);
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
        
        // Dispose resources
        if (asset != undefined && struct_exists(asset, "dispose")) {
            asset.dispose(true);
        }
    }
    
    // Folder: recursively remove all children
    else if (assetType == "Folder") {
        // Iterate on treeview item children to clean their assets
        editorTreeviewUtil_removeChildrenRecursive(treeviewItem);
        
        // Remove the folder from AssetManager
        assetManager.removeAsset("Folder", asset);
    }
}
// Helper functions moved to scrEditorTreeviewUtils
