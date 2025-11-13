function editorTreeviewOnItemSelected(treeviewItem) {
    var editorState = global.EditorState;
    
    // Handle folders (no asset)
    if (treeviewItem.asset == undefined) {
        if (treeviewItem.type == "Folder") {
            // Folders don't have an asset to inspect
            editorState.clearActiveAsset();
        }
        return;
    }
    
    switch (treeviewItem.asset.type) {
        case "ModelInstance":                
            var scene = treeviewItem.asset;
            while (scene == undefined || scene.type != "Scene") {
                scene = scene.parent;
            }
            editorState.setActiveAsset(scene, treeviewItem);
        break;

        case "Mesh":
            var currentAsset = treeviewItem.asset;
            while (currentAsset.parent != undefined && currentAsset.parent.type == "Mesh") {
                currentAsset = currentAsset.parent;
            }
            editorState.setActiveAsset(currentAsset, treeviewItem);
        break;

        case "Scene":
            editorState.setActiveAsset(treeviewItem.asset, treeviewItem);
        break;
    }

    // Inspect the asset
    if (editorState.inspector != undefined) {
        editorState.inspector.inspect(treeviewItem.asset);
    }
};
