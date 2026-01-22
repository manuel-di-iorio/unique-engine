function editorTreeviewOnItemSelected(treeviewItem, focus = false) {
    var editorManager = oSceneEditor.editorManager;
    
    if (treeviewItem == undefined || treeviewItem.asset == undefined) {
        editorManager.clearActiveAsset(true);
        return;
    }
    
    switch (treeviewItem.asset.type) {
        case "Mesh":
        case "Bone":
        case "Object3D":
        // case "Light":
            var currentAsset = treeviewItem.asset;
            // Find the root for rendering (Scene or top-level Mesh)
            var rootAsset = currentAsset;
            var curr = currentAsset;
            
            while (curr.parent != undefined) {
                var parentType = curr.parent[$ "type"];
                
                if (parentType == "Scene") {
                    rootAsset = curr.parent; // Found a scene, use it as root
                    break;
                }
                
                if (parentType == "Folder") {
                    // Parent is a folder, so 'curr' is the top-level asset
                    rootAsset = curr;
                    break;
                }
                
                // Move up
                curr = curr.parent;
                
                // If we reached the top without hitting Scene or Folder (e.g. root asset)
                if (curr.parent == undefined) {
                    rootAsset = curr;
                }
            }
            
            // Pass the clicked submesh as gizmo target (third argument)
            editorManager.setActiveAsset(rootAsset, treeviewItem, treeviewItem.asset);
        break;

        case "Scene":
            editorManager.setActiveAsset(treeviewItem.asset, treeviewItem);
        break;

        default:
            // For other types (Texture, Material, Folder, etc.), clear the active 3D asset 
            // but keep the current scene loaded and MAINTAIN the treeview selection.
            editorManager.clearActiveAsset(true, false);
            editorManager.selectedTreeviewItem = treeviewItem;
        break;
    }

    // Inspect the asset
    if (editorManager.inspector != undefined) {
        editorManager.inspector.inspect(treeviewItem.asset, focus);
    }
};
