/**
 * @class UeProjectLoader
 * @description Runtime project loader for loading and managing game assets from the exported project structure.
 */
function UeProjectLoader(data = {}) constructor {
    self.renderer = data[$ "renderer"] ?? new UeRenderer();
    self.autoLoad = data[$ "autoLoad"] ?? true;
    
    self.scene = new UeScene();
    self.__projectPath = "Unique Project";

    self.assetsByUuid = {};
    self.assetsByName = {};
    self.projectId = "";

    /**
     * @function load
     * @description Discovers all assets by scanning the Assets/ folder.
     */
    self.load = function() {
        var baseDir = self.__projectPath + "/";
        var assetsDir = baseDir + "Assets/";
        var projectJsonPath = baseDir + "project.json";
        var types = ["Textures", "Materials", "Objects", "Scenes"];
        
        self.assetsByUuid = {};
        self.assetsByName = {};

        if (file_exists(projectJsonPath)) {
            var projectData = self.__readJson(projectJsonPath);
            self.projectId = projectData[$ "id"] ?? "";
        }

        for (var i = 0; i < array_length(types); i++) {
            var typeDir = assetsDir + types[i] + "/";
            if (!directory_exists(typeDir)) continue;

            // Discover all Assets (UUID/asset.json)
            var a = file_find_first(typeDir + "*", fa_directory);
            while (a != "") {
                var fullPath = typeDir + a + "/";
                var metaPath = fullPath + "asset.json";
                if (directory_exists(fullPath) && file_exists(metaPath)) {
                    var entry = self.__readJson(metaPath);
                    entry[$ "uuid"] = a;
                    self.assetsByUuid[$ a] = entry;
                    if (struct_exists(entry, "name") && entry[$ "name"] != "") {
                        self.assetsByName[$ entry[$ "name"]] = entry;
                    }
                }
                a = file_find_next();
            }
            file_find_close();
        }

        if (self.autoLoad) {
            self.loadAssets();
            
            var sceneNames = [];
            var assetNames = struct_get_names(self.assetsByName);
            for (var i = 0; i < array_length(assetNames); i++) {
                var asset = self.assetsByName[$ assetNames[i]];
                if (struct_exists(asset, "type") && asset[$ "type"] == "Scene") {
                    array_push(sceneNames, asset[$ "name"]);
                }
            }
            if (array_length(sceneNames) == 1) {
                self.setScene(sceneNames[0]);
            }
        }
    };
    
    self.loadAssets = function() {
        var assetNames = [];
        if (argument_count == 1 && is_array(argument[0])) {
            assetNames = argument[0];
        } else {
            for (var i = 0; i < argument_count; i++) {
                array_push(assetNames, argument[i]);
            }
        }
        
        if (array_length(assetNames) == 0) {
            assetNames = struct_get_names(self.assetsByName);
        }
        
        var uuidsToLoad = [];
        for (var i = 0; i < array_length(assetNames); i++) {
            var entry = self.assetsByName[$ assetNames[i]];
            if (entry != undefined) array_push(uuidsToLoad, entry[$ "uuid"]);
        }
        
        self.__loadAssetsInternal(uuidsToLoad);
    };
    
    self.loadAssetsByUuid = function() {
        var uuidsToLoad = [];
        if (argument_count == 1 && is_array(argument[0])) {
            uuidsToLoad = argument[0];
        } else {
            for (var i = 0; i < argument_count; i++) {
                array_push(uuidsToLoad, argument[i]);
            }
        }
        
        if (array_length(uuidsToLoad) == 0) {
            uuidsToLoad = struct_get_names(self.assetsByUuid);
        }
        
        self.__loadAssetsInternal(uuidsToLoad);
    };

    self.__loadAssetsInternal = function(uuidsToLoad) {
        for (var i = 0; i < array_length(uuidsToLoad); i++) {
            var uuid = uuidsToLoad[i];
            var entry = self.assetsByUuid[$ uuid];
            
            if (entry == undefined || (struct_exists(entry, "isLoaded") && entry[$ "isLoaded"] == true)) continue;

            var asset = self.__createAsset(entry, uuid);
            if (asset != undefined) {
                self.assetsByUuid[$ uuid] = asset;
                if (struct_exists(asset, "name") && asset[$ "name"] != "") {
                    self.assetsByName[$ asset[$ "name"]] = asset;
                }
            }
        }
        self.__linkAssets();
    };
    
    self.getAsset = function(name) {
        return self.assetsByName[$ name];
    };

    self.setScene = function(sceneName = undefined) {
        var sceneAsset = self.assetsByName[$ sceneName];
        if (sceneAsset == undefined || !struct_exists(sceneAsset, "type") || sceneAsset[$ "type"] != "Scene") {
            return;
        }
        
        self.scene.clear();
        
        if (!struct_exists(sceneAsset, "__metadata") || sceneAsset[$ "__metadata"] == undefined) return;
        var childrenData = sceneAsset[$ "__metadata"][$ "children"];
        if (childrenData == undefined) return;
        
        self.__instantiateChildren(childrenData, self.scene);
        self.scene.updateWorldMatrix(false, true);
    };

    self.__instantiateChildren = function(childrenData, parent) {
        for (var i = 0; i < array_length(childrenData); i++) {
            var childData = childrenData[i];
            if (is_struct(childData) && childData[$ "type"] == "ModelInstance") {
                var modelUUID = childData[$ "model"];
                var model = self.assetsByUuid[$ modelUUID];
                
                if (model != undefined && struct_exists(model, "isMesh") && model[$ "isMesh"] == true) {
                    var instance = model.createInstance();
                    instance.name = childData[$ "name"] ?? "Instance";
                    instance.type = "ModelInstance";
                    
                    if (struct_exists(childData, "position")) {
                        var p = childData[$ "position"];
                        vec3_set(instance.position, p[0], p[1], p[2]);
                    }
                    if (struct_exists(childData, "rotation")) {
                        var r = childData[$ "rotation"];
                        quat_set(instance.rotation, r[0], r[1], r[2], r[3]);
                    }
                    if (struct_exists(childData, "scale")) {
                        var s = childData[$ "scale"];
                        vec3_set(instance.scale, s[0], s[1], s[2]);
                    }
                    
                    instance.updateMatrix();
                    parent.add(instance);
                    
                    if (struct_exists(childData, "children") && is_array(childData[$ "children"])) {
                        self.__instantiateChildren(childData[$ "children"], instance);
                    }
                }
            } else if (is_string(childData)) {
                var childAsset = self.assetsByUuid[$ childData];
                if (childAsset != undefined && is_struct(childAsset) && struct_exists(childAsset, "isObject3D")) {
                     parent.add(childAsset);
                }
            }
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

    self.__createAsset = function(metadata, uuid) {
        var asset = undefined;
        var baseDir = self.__projectPath + "/";
        
        var type = metadata[$ "type"];
        var typeDir = self.__getTypeDir(type);
        var assetDir = baseDir + "Assets/" + typeDir + "/" + uuid + "/";

        switch (type) {
            case "Texture":
                asset = new UeTexture();
                asset.fromJSON(metadata);
                var texPath = assetDir + "texture.png";
                if (file_exists(texPath)) asset.import(texPath);
                break;
                
            case "Material":
                asset = new UeMaterial();
                asset.__metadata = metadata;
                break;
 
            case "Mesh":
                asset = new UeStaticMesh();
                asset.fromJSON(metadata);
                var geoPath = assetDir + "geometry.buf";
                
                if (file_exists(geoPath)) {
                    var geo = new UeGeometry();
                    geo.import(geoPath);
                    asset.geometry = geo;
                }
                asset.__metadata = metadata;
                break;
                
            case "Scene":
                asset = new UeScene();
                asset.fromJSON(metadata);
                asset.__metadata = metadata;
                break;
        }
        
        if (asset != undefined) {
            asset.isLoaded = true;
            asset.name = metadata[$ "name"] ?? "";
            asset.uuid = uuid;
        }
        return asset;
    };
    
    self.__linkAssets = function() {
        var assetUUIDs = struct_get_names(self.assetsByUuid);
        var texturesByUUID = {};
        var materialsByUUID = {};
        
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assetsByUuid[$ assetUUIDs[i]];
            if (is_struct(asset) && struct_exists(asset, "type") && asset[$ "type"] == "Texture") texturesByUUID[$ asset[$ "uuid"]] = asset;
            if (is_struct(asset) && struct_exists(asset, "type") && asset[$ "type"] == "Material") materialsByUUID[$ asset[$ "uuid"]] = asset;
        }
        
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assetsByUuid[$ assetUUIDs[i]];
            if (!is_struct(asset)) continue;

            if (struct_exists(asset, "type") && asset[$ "type"] == "Material" && struct_exists(asset, "__metadata") && asset[$ "__metadata"] != undefined) {
                asset.fromJSON(asset[$ "__metadata"], texturesByUUID);
                delete asset.__metadata;
            }
            if (struct_exists(asset, "type") && asset[$ "type"] == "Mesh" && struct_exists(asset, "__metadata") && asset[$ "__metadata"] != undefined) {
                var matId = asset[$ "__metadata"][$ "material"];
                if (matId != undefined && struct_exists(materialsByUUID, matId)) {
                    asset.material = materialsByUUID[$ matId];
                }
                delete asset.__metadata;
            }
        }
    };
 
    self.__readJson = function(path) {
        var bf = buffer_load(path);
        var str = buffer_read(bf, buffer_text);
        buffer_delete(bf);
        return json_parse(str);
    };
    
    self.render = function(camera) {
        self.renderer.render(self.scene, camera);
        return self;
    };

    self.load();
}
