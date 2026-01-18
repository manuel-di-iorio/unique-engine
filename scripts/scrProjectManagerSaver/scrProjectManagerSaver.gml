function ProjectSaver() constructor {
    
    // Debounce tracking for saveEditorSettings
    self.__lastCallTime = 0;
    self.__pendingSave = false;
    self.__debounceDelay = 500; // milliseconds

    /**
     * Save the project.
     */
    self.save = function(projectManager) {
        // Paths
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var editorJsonPath = projectDir + "editor.json";
        var projectJsonPath = projectDir + "project.json";
        var assetsDir = projectDir + "Assets/";

        // Ensure base dir exists
        if (!directory_exists(projectDir)) directory_create(projectDir);

        // Check if this is the first save for settings
        var isFirstSave = !file_exists(editorJsonPath);
        
        // Ensure .gitignore exists and ignores editor.json
        __ensureGitIgnore(projectDir);

        if (isFirstSave) {
            // Full save
            __performFullSave(projectManager, projectDir, assetsDir, editorJsonPath, projectJsonPath);
        } else {
            // Incremental save
            __performIncrementalSave(projectManager, projectDir, assetsDir, editorJsonPath, projectJsonPath);
        }

        projectManager.markAsSaved();
    };
    
    /**
     * Save editor settings (camera easing, grid, box colliders) to editor.json
     */
    self.saveEditorSettings = function(projectManager) {
        var currentTime = current_time;
        self.__lastCallTime = currentTime;
        
        if (self.__pendingSave) return;
        
        self.__pendingSave = true;
        
        var _this = self;
        runLater(method({ 
            projectManager: projectManager,
            scheduledTime: currentTime,
            _this: _this, 
        }, function() {
            if (current_time - _this.__lastCallTime >= _this.__debounceDelay - 50) {
                _this.__performSaveEditorSettings(projectManager);
                _this.__pendingSave = false;
            } else {
                _this.__pendingSave = false;
                projectManager.saver.saveEditorSettings(projectManager);
            }
        }), self.__debounceDelay);
    };
    
    self.__performSaveEditorSettings = function(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var editorJsonPath = projectDir + "editor.json";
        
        var settings = __getProjectSettings();
        __writeJson(editorJsonPath, settings);
    };
    
    self.__performFullSave = function(projectManager, projectDir, assetsDir, editorJsonPath, projectJsonPath) {
        // Full save implies we might want to cleanup the categorized folders
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        var subDirs = ["Textures", "Materials", "Objects", "Scenes"];
        for (var i = 0; i < array_length(subDirs); i++) {
            var path = assetsDir + subDirs[i] + "/";
            if (!directory_exists(path)) directory_create(path);
        }

        var am = oSceneEditor.assetManager;
        var allAssets = am.assets;
        
        for (var i = 0; i < array_length(allAssets); i++) {
            var asset = allAssets[i];
            var type = asset[$ "type"];
            if (type == "ModelInstance" || type == "Folder") continue;
            
            __saveAsset(asset, assetsDir);
        }

        // Handle project.json and folders
        __saveProjectJson(projectJsonPath);

        // Save editor settings
        var settings = __getProjectSettings();
        __writeJson(editorJsonPath, settings);
    };
    
    self.__performIncrementalSave = function(projectManager, projectDir, assetsDir, editorJsonPath, projectJsonPath) {
        var changes = projectManager.changes;
        var changeIds = struct_get_names(changes);
        
        if (!directory_exists(assetsDir)) directory_create(assetsDir);

        for (var i = 0; i < array_length(changeIds); i++) {
            var uuid = changeIds[i];
            var change = changes[$ uuid];
            var action = change[$ "action"];
            var asset = change[$ "asset"];
            
            if (asset == undefined) continue;
            
            var type = asset[$ "type"];
            if (type == "Folder") continue;

            switch (action) {
                case "create":
                case "edit":
                    if (type == "ModelInstance") break;
                    __saveAsset(asset, assetsDir);
                    break;
                    
                case "delete":
                    if (type == "ModelInstance") break;
                    var typeDir = __getTypeDir(type);
                    var assetPath = assetsDir + typeDir + "/" + uuid;
                    if (directory_exists(assetPath)) directory_destroy(assetPath);
                    
                    // Also check for legacy flat path
                    var legacyPath = assetsDir + uuid;
                    if (directory_exists(legacyPath)) directory_destroy(legacyPath);
                    break;
            }
        }
        
        __saveProjectJson(projectJsonPath);

        var settings = __getProjectSettings();
        __writeJson(editorJsonPath, settings);
    };

    self.__saveProjectJson = function(projectJsonPath) {
        var projectData = {};
        
        if (file_exists(projectJsonPath)) {
            projectData = __readJson(projectJsonPath);
        } else {
            projectData[$ "id"] = ueUuid();
        }
        
        var foldersEntries = [];
        var am = oSceneEditor.assetManager;
        var allFolders = am.getAssetsByType("Folder");
        
        for (var i = 0; i < array_length(allFolders); i++) {
            var folder = allFolders[i];
            var folderParentUuid = undefined;
            if (struct_exists(folder, "__parentUI") && folder[$ "__parentUI"] != undefined && struct_exists(folder[$ "__parentUI"], "type") && folder[$ "__parentUI"][$ "type"] == "Folder") {
                folderParentUuid = folder[$ "__parentUI"][$ "uuid"];
            }
            
            array_push(foldersEntries, {
                uuid: folder[$ "uuid"],
                name: folder[$ "name"],
                __parentUI: folderParentUuid
            });
        }
        
        projectData[$ "version"] = global.UE_VERSION;
        projectData[$ "folders"] = foldersEntries;
        __writeJson(projectJsonPath, projectData);
    };

    self.__saveAsset = function(asset, assetsDir) {
        var type = asset[$ "type"];
        var typeDir = __getTypeDir(type);
        var assetPath = assetsDir + typeDir + "/" + asset[$ "uuid"] + "/";
        if (!directory_exists(assetPath)) directory_create(assetPath);
        
        var assetToJSON = asset[$ "toJSON"];
        var metadata = is_callable(assetToJSON) ? assetToJSON() : asset;
        
        if (struct_exists(asset, "__rotationEuler") && asset[$ "__rotationEuler"] != undefined) {
            metadata[$ "rotationEuler"] = asset[$ "__rotationEuler"];
        }
        
        if ((type == "Mesh" || type == "Object3D" || type == "Camera") && struct_exists(asset, "__matrixAutoUpdate") && asset[$ "__matrixAutoUpdate"] != undefined) {
            metadata[$ "matrixAutoUpdate"] = asset[$ "__matrixAutoUpdate"];
        }

        if (struct_exists(asset, "__parentUI") && asset[$ "__parentUI"] != undefined) {
            metadata[$ "__parentUI"] = asset[$ "__parentUI"][$ "uuid"];
        }
        
        __writeJson(assetPath + "asset.json", metadata);
        
        switch (type) {
            case "Texture":
                asset.export(assetPath + "texture.png");
                break;
            case "Mesh":  
                var assetGeometry = asset[$ "geometry"];
                if (assetGeometry != undefined) {
                    var vbuff = assetGeometry[$ "vb"];
                    if (vbuff != undefined) {
                        assetGeometry.vb = assetGeometry[$ "__vbClone"]; 
                        assetGeometry.export(assetPath + "geometry.buf");
                        assetGeometry.vb = vbuff;
                    }
                }
                break;
        }
    };

    self.__getTypeDir = function(type) {
        switch (type) {
            case "Texture": return "Textures";
            case "Material": return "Materials";
            case "Mesh": return "Objects";
            case "Scene": return "Scenes";
            case "Light": return "Objects";
            case "Camera": return "Objects";
        }
        return "Objects";
    };

    self.__getProjectSettings = function() {
        var sm = oSceneEditor.sceneManager;
        var cameraSettings = {
            position: [100, -300, 70],
            target: [0, 0, 0],
            damping: true
        };

        cameraSettings[$ "position"] = [sm.camera.position[VEC3.x], sm.camera.position[VEC3.y], sm.camera.position[VEC3.z]];

        if (sm.orbit != undefined) {
            cameraSettings[$ "target"] = [sm.orbit.target[VEC3.x], sm.orbit.target[VEC3.y], sm.orbit.target[VEC3.z]];
            cameraSettings[$ "dampingFactor"] = sm.orbit.dampingFactor;
        }

        var counters = {
            textures: global.UI_ASSETS_TEXTURES_ID ?? 0,
            materials: global.UI_ASSETS_MATERIALS_ID ?? 0,
            models: global.UI_ASSETS_MODELS_ID ?? 0,
            lights: global.UI_ASSETS_LIGHTS_ID ?? 0,
            cameras: global.UI_ASSETS_CAMERAS_ID ?? 0,
            scenes: global.UI_ASSETS_SCENES_ID ?? 0,
            object3d: global.UI_ASSETS_OBJECT3D_ID ?? 0,
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
    };

    self.__ensureGitIgnore = function(projectDir) {
        var gitIgnorePath = projectDir + ".gitignore";
        var content = "";
        
        if (!file_exists(gitIgnorePath)) {
            content = "editor.json\n";
            __writeFile(gitIgnorePath, content);
        }
    };

    self.__writeJson = function(path, data) {
        var jsonString = json_stringify_ordered(data, true);
        var buf = buffer_create(string_byte_length(jsonString), buffer_fixed, 1);
        buffer_write(buf, buffer_text, jsonString);
        buffer_save(buf, path);
        buffer_delete(buf);
    };
    
    self.__writeFile = function(path, text) {
        var buf = buffer_create(string_byte_length(text), buffer_fixed, 1);
        buffer_write(buf, buffer_text, text);
        buffer_save(buf, path);
        buffer_delete(buf);
    };

    self.__readJson = function(path) {
        if (!file_exists(path)) return {};
        var buf = buffer_load(path);
        var jsonString = buffer_read(buf, buffer_text);
        buffer_delete(buf);
        return json_parse(jsonString);
    };
}
