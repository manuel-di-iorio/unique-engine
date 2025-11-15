function editorTreeviewOnItemSelected(treeviewItem) {
    var editorManager = oSceneEditor.editorManager;
    
    // Handle folders (no asset)
    if (treeviewItem.asset == undefined) {
        if (treeviewItem.type == "Folder") {
            // Folders don't have an asset to inspect
            // editorManager.clearActiveAsset();
        }
        global.UI.needsRedraw = true;
        return;
    }
    
    switch (treeviewItem.asset.type) {
        case "ModelInstance":                
            var scene = treeviewItem.asset;
            while (scene == undefined || scene.type != "Scene") {
                scene = scene.parent;
            }
            if (scene != undefined && scene.type == "Scene") {
                editorManager.setActiveAsset(scene, treeviewItem);
            }
        break;

        case "Mesh":
            var currentAsset = treeviewItem.asset;
            while (currentAsset.parent != undefined && currentAsset.parent.type == "Mesh") {
                currentAsset = currentAsset.parent;
            }
            editorManager.setActiveAsset(currentAsset, treeviewItem);
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
