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
            var mesh = treeviewItem.asset;
            while (mesh != undefined && mesh.isInstance == true) {
                mesh = mesh.parent;
            }
            oSceneEditor.setActiveAsset(mesh);
            // oSceneEditor.setActiveAsset(treeviewItem.asset);
        break;

        case "Scene":
            oSceneEditor.setActiveAsset(treeviewItem.asset);
        break;
    }

    oSceneEditor.inspector.inspect(treeviewItem.asset);
};
