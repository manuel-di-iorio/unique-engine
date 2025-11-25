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
            __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath);
        } else {
            // Incremental save
            __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath);
        }

        projectManager.markAsSaved();
    }
    
    /**
     * Save only the camera position and target to project.json
     * This is called frequently (e.g., on camera movement) and doesn't mark the project as unsaved
     */
    function saveCameraPosition(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var projectJsonPath = projectDir + "project.json";
        
        // Exit if project file doesn't exist yet
        if (!file_exists(projectJsonPath)) return;
        
        // Load existing project.json
        var projectJson = json_parse(self.__readFile(projectJsonPath));
        
        // Update only camera settings
        var sm = oSceneEditor.sceneManager;
        var cameraSettings = {
            position: [sm.camera.position.x, sm.camera.position.y, sm.camera.position.z],
            target: [sm.orbit.target.x, sm.orbit.target.y, sm.orbit.target.z],
            dampingFactor: sm.orbit.dampingFactor
        };
        
        projectJson.settings.camera = cameraSettings;
        
        // Write back to file
        self.__writeJson(projectJsonPath, projectJson);
    }
    
    /**
     * Perform a full save of all assets
     */
    function __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath) {
        directory_destroy(projectDir);

        // Ensure project dirs exists
        if (!directory_exists(projectDir)) directory_create(projectDir);
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        var assets = []; // List of asset UUIDs to save in assets.json
        
        // Project structure to save in project.json
        var project = {
            settings: self.__getProjectSettings(),
            folders: {} // Folders map
        }

        // Get all assets from AssetManager (now a flat array)
        var am = oSceneEditor.assetManager;
        var allAssets = am.assets;
        
        for (var i = 0; i < array_length(allAssets); i++) {
            var asset = allAssets[i];
            
            // Skip folders (they're saved separately in project.json)
            if (asset[$ "type"] == "Folder") continue;
            
            // Add UUID to assets.json list (we store only UUIDs now)
            array_push(assets, asset.uuid);
            
            // Save asset metadata and resources
            var assetPath = assetsDir + asset.uuid;
            if (!directory_exists(assetPath)) directory_create(assetPath);
            
            var assetToJSON = asset[$ "toJSON"];
            var metadata = is_callable(assetToJSON) ? assetToJSON() : asset;
            
            // Add Euler rotation to metadata if it exists (editor-only data)
            if (asset[$ "__rotationEuler"] != undefined) {
                metadata.ex = asset.__rotationEuler.x;
                metadata.ey = asset.__rotationEuler.y;
                metadata.ez = asset.__rotationEuler.z;
                metadata.eo = asset.__rotationEuler.order;
            }

            // Save folder UUID if asset is in a folder
            if (asset[$ "__folder"] != undefined) {
                metadata.__folder = asset.__folder;
            }
            
            self.__writeJson(assetPath + "/metadata.json", metadata);
            
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
        }

        // Collect folders
        var allFolders = oSceneEditor.assetManager.getAssetsByType("Folder");
        for (var i = 0; i < array_length(allFolders); i++) {
            var folder = allFolders[i];
            project.folders[$ folder.uuid] = {
                uuid: folder.uuid,
                name: folder.name,
                parent: (folder[$ "parent"] != undefined && folder.parent[$ "type"] == "Folder") ? folder.parent.uuid : undefined
            };
        }

        // Write assets.json and project.json
        self.__writeJson(assetsJsonPath, { assets, version: global.UE_VERSION });
        self.__writeJson(projectJsonPath, project);
    }
    
    /**
     * Perform an incremental save of only changed assets
     */
    function __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath, projectJsonPath) {
        var changes = projectManager.changes;
        var changeIds = struct_get_names(changes);
        
        // Load existing assets.json
        var assetsJson = json_parse(self.__readFile(assetsJsonPath));
        var assets = assetsJson.assets;
        
        // Load existing project.json
        var projectJson = {};
        if (file_exists(projectJsonPath)) {
            projectJson = json_parse(self.__readFile(projectJsonPath));
        }
        var foldersMap = projectJson[$ "folders"] ?? {};
        
        for (var i = 0; i < array_length(changeIds); i++) {
            var uuid = changeIds[i];
            var change = changes[$ uuid];
            var action = change.action;
            var asset = change.asset;
            
            switch (action) {
                case "create":
                case "edit":
                    // Handle Folder updates
                    if (asset.type == "Folder") {
                        foldersMap[$ asset.uuid] = {
                            uuid: asset.uuid,
                            name: asset.name,
                            parent: (asset[$ "parent"] != undefined && asset.parent[$ "type"] == "Folder") ? asset.parent.uuid : undefined
                        };
                        break;
                    }

                    // Update or add to assets.json (store only UUIDs)
                    var assetIndex = -1;
                    for (var j = 0; j < array_length(assets); j++) {
                        if (assets[j] == uuid) {
                            assetIndex = j;
                            break;
                        }
                    }
                    if (assetIndex == -1) {
                        array_push(assets, uuid);
                    }
                    
                    var assetPath = assetsDir + uuid;
                    if (!directory_exists(assetPath)) directory_create(assetPath);
                    
                    // Check if asset is in a folder using __treeviewItem
                    var folderUUID = undefined;
                    if (asset[$ "__treeviewItem"] != undefined && asset.__treeviewItem[$ "parent"] != undefined) {
                        var parentItem = asset.__treeviewItem.parent;
                        if (parentItem[$ "asset"] != undefined && parentItem.asset[$ "type"] == "Folder") {
                            folderUUID = parentItem.asset.uuid;
                        }
                    }
                    
                    var assetToJSON = asset[$ "toJSON"];
                    var metadata = is_callable(assetToJSON) ? assetToJSON() : asset;
                    
                    // Add Euler rotation to metadata if it exists (editor-only data)
                    if (asset[$ "__rotationEuler"] != undefined) {
                        metadata.ex = asset.__rotationEuler.x;
                        metadata.ey = asset.__rotationEuler.y;
                        metadata.ez = asset.__rotationEuler.z;
                        metadata.eo = asset.__rotationEuler.order;
                    }

                    // Save folder UUID if we found one
                    if (folderUUID != undefined) {
                        metadata.folder = folderUUID;
                    }
                    
                    self.__writeJson(assetPath + "/metadata.json", metadata);
                    
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
                    if (asset.type == "Folder") {
                        variable_struct_remove(foldersMap, asset.uuid);
                        break;
                    }

                    // Remove from assets.json (UUID list)
                    for (var j = array_length(assets) - 1; j >= 0; j--) {
                        if (assets[j] == uuid) {
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
        
        // Update project.json with new folders map
        projectJson.folders = foldersMap;
        self.__writeJson(projectJsonPath, projectJson);
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
            gridEnabled: sm.gridEnabled,
            gizmos: {
                showBoxColliders: sm.showBoxColliders
            }
        };
    }

    function __traverseTreeview(assetsDir, assetsMap, assets, treeviewChildren, parentTreeviewItem) {
        for (var i = 0, il = array_length(treeviewChildren); i < il; i++) {
            var treeviewChild = treeviewChildren[i];

            var asset = treeviewChild[$ "asset"];

            if (asset != undefined) {
                var assetUuid = asset.uuid;
                var assetType = asset.type;

                    if (assetType != "Folder" && assetType != "ModelInstance") {
                    // If this treeview item is not a folder, push its UUID into assets.json
                    if (assetsMap[$ assetUuid] == undefined){
                        assetsMap[$ assetUuid] = true;
                        array_push(assets, assetUuid);
                    }

                    // Export asset metadata into the assets folder, along with the resource file if needed
                    var assetPath = assetsDir + assetUuid;
                    if (!directory_exists(assetPath)) directory_create(assetPath);

                    // Check if parent treeview item is a Folder (UI organization, not 3D hierarchy)
                    var folderUUID = undefined;
                    if (parentTreeviewItem != undefined && parentTreeviewItem[$ "asset"] != undefined) {
                        var parentAsset = parentTreeviewItem.asset;
                        if (parentAsset[$ "type"] == "Folder") {
                            folderUUID = parentAsset.uuid;
                        }
                    }
                    
                    var assetToJSON = asset[$ "toJSON"];
                    var metadata = is_callable(assetToJSON) ? assetToJSON() : asset;
                    
                    // Add Euler rotation to metadata if it exists (editor-only data)
                    if (asset[$ "__rotationEuler"] != undefined) {
                        metadata.ex = asset.__rotationEuler.x;
                        metadata.ey = asset.__rotationEuler.y;
                        metadata.ez = asset.__rotationEuler.z;
                        metadata.eo = asset.__rotationEuler.order;
                    }

                    // Save folder UUID if we found one
                    if (folderUUID != undefined) {
                        metadata.folder = folderUUID;
                    }
                    
                    self.__writeJson(assetPath + "/metadata.json", metadata);
                    
                    switch (assetType) {
                        case "Texture":
                            asset.export(assetPath + "/texture.png");
                            break;
                        case "Mesh":  
                            var assetGeometry = asset[$ "geometry"];
                            if (assetGeometry != undefined) assetGeometry.export(assetPath + "/geometry.buf");
                    }
                }
            }

            if (array_length(treeviewChild.children)) {                
                self.__traverseTreeview(assetsDir, assetsMap, assets, treeviewChild.children, treeviewChild);
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
