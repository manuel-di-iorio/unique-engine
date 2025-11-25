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
     * Save editor settings (camera easing, grid, box colliders) to project.json
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
        call_later(self.__debounceDelay, time_source_units_frames, method({ 
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
        }));
    }
    
    /**
     * Internal function that actually performs the save
     */
    function __performSaveEditorSettings(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var projectJsonPath = projectDir + "project.json";
        
        // Exit if project file doesn't exist yet
        if (!file_exists(projectJsonPath)) return;
        
        // Load existing project.json
        var projectJson = json_parse(self.__readFile(projectJsonPath));
        
        // Update editor settings
        var sm = oSceneEditor.sceneManager;

        // Update camera position and target
        if (projectJson.settings[$ "camera"] != undefined && sm.orbit != undefined) {
            projectJson.settings.camera.position = [sm.camera.position.x, sm.camera.position.y, sm.camera.position.z];
            projectJson.settings.camera.target = [sm.orbit.target.x, sm.orbit.target.y, sm.orbit.target.z];
        }
        
        // Update camera damping factor
        if (projectJson.settings[$ "camera"] != undefined && sm.orbit != undefined) {
            projectJson.settings.camera.dampingFactor = sm.orbit.dampingFactor;
        }
        
        // Update grid visibility
        projectJson.settings.gridEnabled = sm.gridEnabled;
        
        // Update box colliders visibility
        if (projectJson.settings[$ "gizmos"] == undefined) {
            projectJson.settings.gizmos = {};
        }
        projectJson.settings.gizmos.showBoxColliders = sm.showBoxColliders;
        
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
            
            // Add static field for meshes (used for export)
            if (asset.type == "Mesh" && asset[$ "__matrixAutoUpdate"] != undefined) {
                metadata.matrixAutoUpdate = asset.__matrixAutoUpdate;
            }

            // Save folder UUID if asset is in a folder
            if (asset[$ "__parentUI"] != undefined) {
                metadata.__parentUI = asset.__parentUI;
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
        
        show_debug_message("[SAVE] Starting incremental save with " + string(array_length(changeIds)) + " changes");
        
        // Load existing assets.json
        var assetsJson = json_parse(self.__readFile(assetsJsonPath));
        var assets = assetsJson.assets;
        
        show_debug_message("[SAVE] Loaded assets.json with " + string(array_length(assets)) + " assets");
        
        // Load existing project.json
        var projectJson = {};
        if (file_exists(projectJsonPath)) {
            projectJson = json_parse(self.__readFile(projectJsonPath));
        }
        var foldersMap = projectJson[$ "folders"] ?? {};
        
        show_debug_message("[SAVE] Loaded project.json with " + string(struct_names_count(foldersMap)) + " folders");
        
        for (var i = 0; i < array_length(changeIds); i++) {
            var uuid = changeIds[i];
            
            var change = changes[$ uuid];
            var action = change.action;
            var asset = change.asset;
            
            // VALIDATION: Skip invalid assets
            if (asset == undefined) {
                show_debug_message("[SAVE] WARNING: Skipping undefined asset with UUID: " + uuid);
                continue;
            }
            
            // VALIDATION: Skip assets without a name (except for delete action)
            if (action != "delete" && (asset[$ "name"] == undefined || asset.name == "")) {
                show_debug_message("[SAVE] WARNING: Skipping asset with empty name. UUID: " + uuid + ", Type: " + (asset[$ "type"] ?? "undefined"));
                continue;
            }
            
            // VALIDATION: Skip generic Object3D types (these should not be saved directly)
            if (action != "delete" && asset[$ "type"] == "Object3D") {
                show_debug_message("[SAVE] WARNING: Skipping Object3D asset (should not be saved directly). UUID: " + uuid + ", Name: " + (asset[$ "name"] ?? ""));
                continue;
            }
            
            show_debug_message("[SAVE] Processing change #" + string(i) + ": UUID=" + uuid + ", Action=" + action + ", Type=" + asset.type + ", Name=" + asset.name);
            
            switch (action) {
                case "create":
                case "edit":
                    // Handle Folder updates
                    if (asset.type == "Folder") {
                        var folderParentUuid = (asset[$ "parent"] != undefined && asset.parent[$ "type"] == "Folder") ? asset.parent.uuid : undefined;
                        show_debug_message("[SAVE] Updating folder: " + asset.name + " (parent: " + (folderParentUuid ?? "none") + ")");
                        foldersMap[$ asset.uuid] = {
                            uuid: asset.uuid,
                            name: asset.name,
                            parent: folderParentUuid
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
                        show_debug_message("[SAVE] Adding new asset to assets.json: " + asset.name);
                        array_push(assets, uuid);
                    } else {
                        show_debug_message("[SAVE] Asset already in assets.json: " + asset.name);
                    }
                    
                    var assetPath = assetsDir + uuid;
                    show_debug_message("[SAVE] Creating/checking asset directory: " + assetPath);
                    if (!directory_exists(assetPath)) {
                        directory_create(assetPath);
                        show_debug_message("[SAVE] Created directory: " + assetPath);
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
                        show_debug_message("[SAVE] Asset " + asset.name + " has __parentUI: " + asset.__parentUI);
                        metadata.__parentUI = asset.__parentUI;
                    } else {
                        show_debug_message("[SAVE] Asset " + asset.name + " has no __parentUI");
                    }
                    
                    show_debug_message("[SAVE] Writing metadata.json for: " + asset.name);
                    self.__writeJson(assetPath + "/metadata.json", metadata);
                    
                    // Export binary resources
                    switch (asset.type) {
                        case "Texture":
                            show_debug_message("[SAVE] Exporting texture: " + asset.name);
                            asset.export(assetPath + "/texture.png");
                            break;
                        case "Mesh":  
                            var assetGeometry = asset[$ "geometry"];
                            if (assetGeometry != undefined) {
                                var assetGeometryVb = assetGeometry[$ "vb"];
                                if (assetGeometryVb != undefined) {
                                    show_debug_message("[SAVE] Exporting mesh geometry: " + asset.name);
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
                    show_debug_message("[SAVE] Deleting asset: " + asset.name + " (" + asset.type + ")");
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
                        show_debug_message("[SAVE] Deleting directory: " + assetPath);
                        directory_destroy(assetPath);
                    }
                    break;
            }
        }
        
        show_debug_message("[SAVE] Writing assets.json with " + string(array_length(assets)) + " assets");
        // Write updated assets.json
        self.__writeJson(assetsJsonPath, { assets, version: global.UE_VERSION });
        
        show_debug_message("[SAVE] Writing project.json with " + string(struct_names_count(foldersMap)) + " folders");
        // Update project.json with new folders map and settings
        projectJson.folders = foldersMap;
        projectJson.settings = self.__getProjectSettings();
        
        self.__writeJson(projectJsonPath, projectJson);
        show_debug_message("[SAVE] Incremental save completed successfully");
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
        show_debug_message("[SAVE] Writing JSON to: " + path);
        var jsonString = json_stringify(data, true);
        var buf = buffer_create(string_byte_length(jsonString), buffer_fixed, 1);
        buffer_write(buf, buffer_text, jsonString);
        buffer_save(buf, path);
        buffer_delete(buf);
        show_debug_message("[SAVE] Successfully wrote JSON to: " + path);
    }
    
    function __readFile(path) {
        if (!file_exists(path)) return "";
        var buf = buffer_load(path);
        var text = buffer_read(buf, buffer_text);
        buffer_delete(buf);
        return text;
    }
}
