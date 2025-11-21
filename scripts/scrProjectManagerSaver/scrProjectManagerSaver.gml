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

        // Check if this is the first save (no existing project files)
        var isFirstSave = !file_exists(projectJsonPath) || !file_exists(assetsJsonPath);
        
        if (isFirstSave) {
            // Full save
            show_debug_message("Performing FULL save...");
            __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath);
        } else {
            // Incremental save
            show_debug_message("Performing INCREMENTAL save...");
            __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath);
        }

        projectManager.markAsSaved();
    }
    
    /**
     * Perform a full save of all assets
     */
    function __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath) {
        directory_destroy(projectDir);

        // Ensure project dirs exists
        if (!directory_exists(projectDir)) directory_create(projectDir);
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        // Get reference to treeview root
        var treeview = global.UI.Main.Assets.Treeview;

        var assetsMap = {}; // Unique map of assets UUIDs
        var assets = []; // List of assets to save in assets.json
        // Project structure to save in project.json
        var project = {
            settings: self.__getProjectSettings(),
            version: global.UE_VERSION,
            assets: []
        }

        // Build project.json structure from root Items
        self.__traverseTreeview(assetsDir, assetsMap, assets, treeview.Items.children, project.assets);        

        // Write assets.json and project.json
        self.__writeJson(assetsJsonPath, { assets, version: global.UE_VERSION });
        self.__writeJson(projectJsonPath, project);
    }
    
    /**
     * Perform an incremental save of only changed assets
     */
    function __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath) {
        var changes = projectManager.changes;
        var changeUUIDs = struct_get_names(changes);
        
        show_debug_message($"Processing {array_length(changeUUIDs)} changes");
        
        // Load existing assets.json
        var assetsJson = json_parse(self.__readFile(assetsJsonPath));
        var assets = assetsJson.assets;
        
        for (var i = 0; i < array_length(changeUUIDs); i++) {
            var uuid = changeUUIDs[i];
            var change = changes[$ uuid];
            var action = change.action;
            var asset = change.asset;
            
            show_debug_message($"  {action}: {asset.name} ({uuid})");
            
            switch (action) {
                case "create":
                case "edit":
                    // Update or add to assets.json
                    var assetIndex = -1;
                    for (var j = 0; j < array_length(assets); j++) {
                        if (assets[j].uuid == uuid) {
                            assetIndex = j;
                            break;
                        }
                    }
                    
                    if (assetIndex == -1) {
                        // Add new asset
                        array_push(assets, { uuid: uuid, type: asset.type, name: asset.name });
                    } else {
                        // Update existing
                        assets[assetIndex].name = asset.name;
                        assets[assetIndex].type = asset.type;
                    }
                    
                    // Save asset metadata and resources
                    var assetPath = assetsDir + uuid;
                    if (!directory_exists(assetPath)) directory_create(assetPath);
                    
                    var assetToJSON = asset[$ "toJSON"];
                    self.__writeJson(assetPath + "/metadata.json", is_callable(assetToJSON) ? assetToJSON() : asset);
                    
                    // Export binary resources
                    switch (asset.type) {
                        case "Texture":
                            asset.export(assetPath + "/texture.png");
                            break;
                        case "Mesh":  
                            var assetGeometry = asset[$ "geometry"];
                            if (assetGeometry != undefined) assetGeometry.export(assetPath + "/geometry.buf");
                            break;
                    }
                    break;
                    
                case "delete":
                    // Remove from assets.json
                    for (var j = array_length(assets) - 1; j >= 0; j--) {
                        if (assets[j].uuid == uuid) {
                            array_delete(assets, j, 1);
                            break;
                        }
                    }
                    
                    // Delete asset directory
                    var assetPath = assetsDir + uuid;
                    if (directory_exists(assetPath)) {
                        directory_destroy(assetPath);
                    }
                    break;
            }
        }
        
        // Write updated assets.json
        self.__writeJson(assetsJsonPath, { assets, version: global.UE_VERSION });
        
        // Rebuild and update project.json structure from treeview
        var treeview = global.UI.Main.Assets.Treeview;
        var project = {
            settings: self.__getProjectSettings(),
            version: global.UE_VERSION,
            assets: []
        };
        
        // Rebuild the project structure from the current treeview state
        var assetsMap = {}; // Not used here but required by __traverseTreeview
        self.__traverseTreeview(assetsDir, assetsMap, assets, treeview.Items.children, project.assets);
        
        self.__writeJson(projectJsonPath, project);
    }

    function __getProjectSettings() {
        var sm = oSceneEditor.sceneManager;
        var cameraSettings = {
            position: [100, -300, 70],
            target: [0, 0, 0],
            damping: true
        };

        cameraSettings.position = [sm.camera.position.x, sm.camera.position.y, sm.camera.position.z];

        if (sm.orbit != undefined) {
            cameraSettings.target = [sm.orbit.target.x, sm.orbit.target.y, sm.orbit.target.z];
            cameraSettings.dampingFactor = sm.orbit.dampingFactor;
        }

        var counters = {
            textures: global.UI_ASSETS_TEXTURES_ID ?? 0,
            materials: global.UI_ASSETS_MATERIALS_ID ?? 0,
            models: global.UI_ASSETS_MODELS_ID ?? 0,
            lights: global.UI_ASSETS_LIGHTS_ID ?? 0,
            cameras: global.UI_ASSETS_CAMERAS_ID ?? 0,
            scenes: global.UI_ASSETS_SCENES_ID ?? 0,
            instances: global.UI_ASSETS_INSTANCE_ID ?? 0,
            folders: global.UI_ASSETS_FOLDERS_ID ?? 0
        };

        return {
            camera: cameraSettings,
            counters: counters,
            activeTool: oSceneEditor.editorManager.activeTool,
            gridEnabled: sm.gridEnabled
        };
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
    
    function __readFile(path) {
        if (!file_exists(path)) return "";
        var buf = buffer_load(path);
        var text = buffer_read(buf, buffer_text);
        buffer_delete(buf);
        return text;
    }
}
