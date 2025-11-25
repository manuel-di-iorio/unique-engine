function editorTreeviewOnItemSelected(treeviewItem) {
    var editorManager = oSceneEditor.editorManager;
    
    switch (treeviewItem.asset.type) {
        case "ModelInstance":                
        case "Mesh":
            var currentAsset = treeviewItem.asset;
            // Find the root for rendering (Scene or top-level Mesh)
            var rootAsset = currentAsset;
            var curr = currentAsset;
            var safetyCounter = 0;
            
            while (curr.parent != undefined) {
                safetyCounter++;
                if (safetyCounter > 1000) {
                    show_debug_message("ERROR: Loop detected in hierarchy traversal for asset: " + string(currentAsset));
                    break;
                }
                
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
    }

    // Inspect the asset
    if (editorManager.inspector != undefined) {
        editorManager.inspector.inspect(treeviewItem.asset);
    }
};
