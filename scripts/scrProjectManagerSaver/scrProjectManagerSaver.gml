function ProjectSaver() constructor {
    
    // Debounce tracking for saveEditorSettings
    self.__lastCallTime = 0;
    self.__pendingSave = false;
    self.__debounceDelay = 500; // milliseconds

    /**
     * Save the project.
     * If `projectManager` has no existing files, performs a full save.
     * Otherwise performs an incremental save when `projectManager.changes` is present.
     */
    function save(projectManager) {
        // Paths
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var assetsJsonPath = projectDir + "assets.json";
        var assetsDir = projectDir + "assets/";

        // Check if this is the first save (no existing project files)
        var isFirstSave = !file_exists(assetsJsonPath);
        
        if (isFirstSave) {
            // Full save
            __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath);
        } else {
            // Incremental save
            __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath);
        }

        projectManager.markAsSaved();
    }
    
    /**
     * Save editor settings (camera easing, grid, box colliders) to assets.json
     * This is called when toggling these settings and doesn't mark the project as unsaved
     */
    function saveEditorSettings(projectManager) {
        // DEBOUNCE: Track last call time to prevent excessive saves
        var currentTime = current_time;
        self.__lastCallTime = currentTime;
        
        // If there's already a pending save, it will be handled by the scheduled call
        if (self.__pendingSave) {
            return;
        }
        
        // Mark that we have a pending save
        self.__pendingSave = true;
        
        // Schedule the actual save after the debounce delay
        var _this = self;
        runLater(method({ 
            projectManager,
            scheduledTime: currentTime,
            _this, 
        }, function() {
            // Only save if no new calls were made during the debounce period
            if (current_time - _this.__lastCallTime >= _this.__debounceDelay - 50) { // 50ms tolerance
                _this.__performSaveEditorSettings(projectManager);
                _this.__pendingSave = false;
            } else {
                // Reschedule if there were new calls
                _this.__pendingSave = false;
                projectManager.saver.saveEditorSettings(projectManager);
            }
        }), self.__debounceDelay);
    }
    
    /**
     * Internal function that actually performs the save
     */
    function __performSaveEditorSettings(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var assetsJsonPath = projectDir + "assets.json";
        
        // Exit if project file doesn't exist yet
        if (!file_exists(assetsJsonPath)) return;
        
        // Load existing assets.json
        var assetsJson = json_parse(self.__readFile(assetsJsonPath));
        
        // Update editor settings
        var sm = oSceneEditor.sceneManager;

        // Initialize settings if not present
        if (assetsJson[$ "settings"] == undefined) {
            assetsJson.settings = {};
        }

        // Update camera position and target
        if (assetsJson.settings[$ "camera"] != undefined && sm.orbit != undefined) {
            assetsJson.settings.camera.position = [sm.camera.position.x, sm.camera.position.y, sm.camera.position.z];
            assetsJson.settings.camera.target = [sm.orbit.target.x, sm.orbit.target.y, sm.orbit.target.z];
        }
        
        // Update camera damping factor
        if (assetsJson.settings[$ "camera"] != undefined && sm.orbit != undefined) {
            assetsJson.settings.camera.dampingFactor = sm.orbit.dampingFactor;
        }
        
        // Update grid visibility
        assetsJson.settings.gridEnabled = sm.gridEnabled;
        
        // Update box colliders visibility
        if (assetsJson.settings[$ "gizmos"] == undefined) {
            assetsJson.settings.gizmos = {};
        }
        assetsJson.settings.gizmos.showBoxColliders = sm.showBoxColliders;
        
        // Write back to file
        self.__writeJson(assetsJsonPath, assetsJson);
    }
    
    /**
     * Perform a full save of all assets
     */
    function __performFullSave(projectManager, projectDir, assetsDir, assetsJsonPath) {
        directory_destroy(projectDir);

        // Ensure project dirs exists
        if (!directory_exists(projectDir)) directory_create(projectDir);
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        var assets = []; // List of asset objects to save in assets.json
        var folders = {}; // Folders map

        // Get all assets from AssetManager
        var am = oSceneEditor.assetManager;
        var allAssets = am.assets;
        
        for (var i = 0; i < array_length(allAssets); i++) {
            var asset = allAssets[i];
            
            // Skip folders (they're saved separately in folders map)
            if (asset[$ "type"] == "Folder") continue;
            
            // Skip ModelInstance (they're saved in Scene metadata)
            if (asset[$ "type"] == "ModelInstance") continue;
            
            // Add asset object to assets.json list
            array_push(assets, {
                id: asset.uuid,
                name: asset.name,
                type: asset.type
            });
            
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
            
            // Add static field for meshes (used for export)
            if (asset.type == "Mesh" && asset[$ "__matrixAutoUpdate"] != undefined) {
                metadata.matrixAutoUpdate = asset.__matrixAutoUpdate;
            }

            // Save folder UUID if asset is in a folder
            if (asset[$ "__parentUI"] != undefined) {
                metadata.__parentUI = asset.__parentUI.uuid;
            }
            
            self.__writeJson(assetPath + "/metadata.json", metadata);
            
            // Export binary resources
            switch (asset.type) {
                case "Texture":
                    asset.export(assetPath + "/texture.png");
                    break;
                case "Mesh":  
                    var assetGeometry = asset[$ "geometry"];
                    if (assetGeometry == undefined) break;
                    var assetGeometryVb = assetGeometry[$ "vb"];
                    if (assetGeometryVb == undefined) break;
                    assetGeometry.vb = assetGeometry.__vbClone; // Use unfrozen VB for export
                    assetGeometry.export(assetPath + "/geometry.buf");
                    assetGeometry.vb = assetGeometryVb; // Restore original VB
                    break;
            }
        }

        // Collect folders
        var allFolders = oSceneEditor.assetManager.getAssetsByType("Folder");
        for (var i = 0; i < array_length(allFolders); i++) {
            var folder = allFolders[i];
            folders[$ folder.uuid] = {
                uuid: folder.uuid,
                name: folder.name,
                __parentUI: (folder[$ "__parentUI"] != undefined && folder.__parentUI[$ "type"] == "Folder") ? folder.__parentUI.uuid : undefined
            };
        }

        // Write assets.json with all data
        self.__writeJson(assetsJsonPath, { 
            assets, 
            folders,
            settings: self.__getProjectSettings(),
            version: global.UE_VERSION 
        });
    }
    
    /**
     * Perform an incremental save of only changed assets
     */
    function __performIncrementalSave(projectManager, projectDir, assetsDir, assetsJsonPath) {
        var changes = projectManager.changes;
        var changeIds = struct_get_names(changes);
        
        // Load existing assets.json
        var assetsJson = json_parse(self.__readFile(assetsJsonPath));
        var assets = assetsJson.assets;
        var foldersMap = assetsJson[$ "folders"] ?? {};
        
        for (var i = 0; i < array_length(changeIds); i++) {
            var uuid = changeIds[i];
            
            var change = changes[$ uuid];
            var action = change.action;
            var asset = change.asset;
            
            // VALIDATION: Skip invalid assets
            if (asset == undefined) {
                continue;
            }
            
            // VALIDATION: Skip assets without a name (except for delete action)
            if (action != "delete" && (asset[$ "name"] == undefined || asset.name == "")) {
                continue;
            }
            
            // VALIDATION: Skip generic Object3D types (these should not be saved directly)
            if (action != "delete" && asset[$ "type"] == "Object3D") {
                continue;
            }
            
            switch (action) {
                case "create":
                case "edit":
                    // Handle Folder updates
                    if (asset.type == "Folder") {
                        var folderParentUuid = (asset[$ "__parentUI"] != undefined && asset.__parentUI[$ "type"] == "Folder") ? asset.__parentUI.uuid : undefined;

                        foldersMap[$ asset.uuid] = {
                            uuid: asset.uuid,
                            name: asset.name,
                            __parentUI: folderParentUuid
                        };
                        break;
                    }
                    
                    // Skip ModelInstance (they're saved in Scene metadata)
                    if (asset.type == "ModelInstance") {
                        break;
                    }

                    // Update or add to assets.json (store objects with id, name, type)
                    var assetIndex = -1;
                    for (var j = 0; j < array_length(assets); j++) {
                        if (assets[j].id == uuid) {
                            assetIndex = j;
                            break;
                        }
                    }
                    if (assetIndex == -1) {
                        array_push(assets, {
                            id: asset.uuid,
                            name: asset.name,
                            type: asset.type
                        });
                    } else {
                        // Update existing entry in case name or type changed
                        assets[assetIndex] = {
                            id: asset.uuid,
                            name: asset.name,
                            type: asset.type
                        };
                    }
                    
                    var assetPath = assetsDir + uuid;
                    if (!directory_exists(assetPath)) {
                        directory_create(assetPath);
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

                    // Add static field for meshes (used for export)
                    if (asset.type == "Mesh" && asset[$ "__matrixAutoUpdate"] != undefined) {
                        metadata.matrixAutoUpdate = asset.__matrixAutoUpdate;
                    }

                    // Save parent UUID if asset has one (set by AssetManager)
                    if (asset[$ "__parentUI"] != undefined) {
                        metadata.__parentUI = asset.__parentUI.uuid;
                    }
                    
                    self.__writeJson(assetPath + "/metadata.json", metadata);
                    
                    // Export binary resources
                    switch (asset.type) {
                        case "Texture":
                            asset.export(assetPath + "/texture.png");
                            break;
                        case "Mesh":  
                            var assetGeometry = asset[$ "geometry"];
                            if (assetGeometry != undefined) {
                                var assetGeometryVb = assetGeometry[$ "vb"];
                                if (assetGeometryVb != undefined) {
                                    var originalVb = assetGeometryVb;
                                    assetGeometry.vb = assetGeometry.__vbClone; // Use unfrozen VB for export
                                    assetGeometry.export(assetPath + "/geometry.buf");
                                    assetGeometry.vb = originalVb; // Restore original VB
                                }
                            }
                            break;
                    }
                    break;
                    
                case "delete":
                    if (asset.type == "Folder") {
                        variable_struct_remove(foldersMap, asset.uuid);
                        break;
                    }
                    
                    // Skip ModelInstance (they're managed in Scene metadata)
                    if (asset.type == "ModelInstance") {
                        break;
                    }

                    // Remove from assets.json (object list)
                    for (var j = array_length(assets) - 1; j >= 0; j--) {
                        if (assets[j].id == uuid) {
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
        
        // Write assets.json with all data
        self.__writeJson(assetsJsonPath, { 
            assets, 
            folders: foldersMap,
            settings: self.__getProjectSettings(),
            version: global.UE_VERSION 
        });
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
            counters,
            gridEnabled: sm.gridEnabled,
            gizmos: {
                showBoxColliders: sm.showBoxColliders
            }
        };
    }

    function __writeJson(path, data) {
        var jsonString = json_stringify_ordered(data, true);
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
