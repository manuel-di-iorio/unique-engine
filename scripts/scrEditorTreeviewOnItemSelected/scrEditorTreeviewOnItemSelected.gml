function editorTreeviewOnItemSelected(treeviewItem) {
    switch (treeviewItem.asset.type) {
        case "ModelInstance":                
            var scene = treeviewItem.asset;
            while (scene == undefined || scene.type != "Scene") {
                scene = scene.parent;
            }
            oSceneEditor.setActiveAsset(scene);
        break;

        case "Mesh":
            var currentAsset = treeviewItem.asset;
            while (currentAsset.parent != undefined && currentAsset.parent.type == "Mesh") {
                currentAsset = currentAsset.parent;
            }
        log(currentAsset)
            oSceneEditor.setActiveAsset(currentAsset);
        break;

        case "Scene":
            oSceneEditor.setActiveAsset(treeviewItem.asset);
        break;
    }

    oSceneEditor.inspector.inspect(treeviewItem.asset);
};
