function editorTreeviewOnItemSelected(treeviewItem) {
    var editorManager = oSceneEditor.editorManager;
    
    switch (treeviewItem.asset.type) {
        case "ModelInstance":                
        case "Mesh":
            var currentAsset = treeviewItem.asset;
            // Find the root mesh for rendering
            var rootMesh = currentAsset;
            while (rootMesh.parent != undefined && (rootMesh.parent.type == "Mesh" || rootMesh.parent.type == "ModelInstance")) {
                rootMesh = rootMesh.parent;
            }
            // Pass the clicked submesh as gizmo target (third argument)
            editorManager.setActiveAsset(rootMesh, treeviewItem, treeviewItem.asset);
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
