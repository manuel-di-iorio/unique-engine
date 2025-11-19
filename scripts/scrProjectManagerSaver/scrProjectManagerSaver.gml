function ProjectSaver() constructor {

    /**
     * Save the project.
     * If `projectManager` has no existing files, performs a full save.
     * Otherwise performs an incremental save when `projectManager.changes` is present.
     */
    function save(projectManager) {
        // Paths
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var assetsJsonPath = projectDir + "assets.json";
        var projectJsonPath = projectDir + "project.json";
        var assetsDir = projectDir + "assets/";

        directory_destroy(projectDir);

        // Ensure project dirs exists
        var isFirstSave = !directory_exists(projectDir);
        if (isFirstSave) directory_create(projectDir);
        if (!directory_exists(projectDir)) directory_create(projectDir);
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        // Get reference to treeview root
        var treeview = global.UI.Main.Assets.Treeview;

        var assetsMap = {}; // Unique map of assets UUIDs
        var assets = []; // List of assets to save in assets.json
        // Project structure to save in project.json
        var project = {
            settings: {},
            version: global.UE_VERSION,
            assets: []
        }

        // Build project.json structure from root Items
        self.__traverseTreeview(assetsDir, assetsMap, assets, treeview.Items.children, project.assets);        

        // Write assets.json and project.json
        self.__writeJson(assetsJsonPath, { assets, version: global.UE_VERSION });
        self.__writeJson(projectJsonPath, project);

        projectManager.markAsSaved();
    }

    function __traverseTreeview(assetsDir, assetsMap, assets, treeviewChildren, projectAssets) {
        for (var i = 0, il = array_length(treeviewChildren); i < il; i++) {
            var treeviewChild = treeviewChildren[i];

            var asset = treeviewChild[$ "asset"];
            var assetNode = undefined;

            if (asset != undefined) {
                var assetUuid = asset.uuid;
                var assetType = asset.type;

                if (assetType != "Folder" && assetType != "ModelInstance") {
                    // If this treeview item is not a folder, push it into assets.json
                    if (assetsMap[$ assetUuid] == undefined){
                        assetsMap[$ assetUuid] = true;
                        array_push(assets, { uuid: assetUuid, type: assetType, name: asset.name } );
                    }

                    // Export asset metadata into the assets folder, along with the resource file if needed
                    var assetPath = assetsDir + assetUuid;
                    if (!directory_exists(assetPath)) directory_create(assetPath);

                    var assetToJSON = asset[$ "toJSON"];
                    self.__writeJson(assetPath + "/metadata.json", is_callable(assetToJSON) ? assetToJSON() : asset);
                    
                    switch (assetType) {
                        case "Texture":
                            asset.export(assetPath + "/texture.png");
                            break;
                        case "Mesh":  
                            var assetGeometry = asset[$ "geometry"];
                            if (assetGeometry != undefined) assetGeometry.export(assetPath + "/geometry.buf");
                    }
                }

                // Push child into project.json structure (skip ModelInstance as they're in scene metadata)
                if (assetType != "ModelInstance") {
                    assetNode = { 
                        uuid: asset.uuid,
                        type: asset.type, 
                        name: asset.name,
                        children: []
                    };

                    array_push(projectAssets, assetNode);
                }
            }

            var childProjectAssets = projectAssets;
            if (assetNode != undefined) childProjectAssets = assetNode.children;

            if (array_length(treeviewChild.children)) {                
                self.__traverseTreeview(assetsDir, assetsMap, assets, treeviewChild.children, childProjectAssets);
            }
        }
    }

    function __writeJson(path, data) {
        var jsonString = json_stringify(data, true);
        var buf = buffer_create(string_byte_length(jsonString), buffer_fixed, 1);
        buffer_write(buf, buffer_text, jsonString);
        buffer_save(buf, path);
        buffer_delete(buf);
    }
}
