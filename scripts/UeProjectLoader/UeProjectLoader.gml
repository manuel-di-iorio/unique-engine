/**
 * @class UeProjectLoader
 * @description Runtime project loader for loading and managing game assets from the exported project structure.
 * 
 * This loader reads assets from the "datafiles/Unique Project/" directory structure and provides
 * on-demand asset loading capabilities. It supports loading assets by name or UUID and can populate
 * scenes with model instances.
 * 
 * @example
 * // Create loader and load all assets
 * var loader = new UeProjectLoader();
 * 
 * // Load specific assets by name
 * loader.loadAssets(["MyTexture", "MyMaterial"]);
 * 
 * // Load specific assets by UUID
 * loader.loadAssets(undefined, ["uuid-1", "uuid-2"]);
 * 
 * // Populate a scene
 * loader.setScene("MainScene");
 * 
 * @param {Struct} data - Configuration options
 * @param {Bool} data.autoLoad - If true, automatically loads all assets on construction (default: true)
 */
function UeProjectLoader(data = {}) constructor {
    self.autoLoad = data[$ "autoLoad"] ?? true;
    
    /// @member {Struct} assets - Flat map of all loaded assets indexed by UUID
    self.assets = {};
    
    /// @member {UeScene} scene - The active scene populated by setScene()
    self.scene = new UeScene();
    
    /// @member {String} __projectDir - Base directory for project assets
    self.__projectDir = "Unique Project";
    
    /// @member {Struct} __jsonAssetsByName - Internal cache mapping asset names to their JSON entries
    self.__jsonAssetsByName = {};

    /**
     * @function load
     * @description Loads the project's assets.json and optionally loads all assets.
     * This function must be called before using loadAssets() or setScene().
     * 
     * @example
     * // Load only assets.json (for on-demand loading)
     * loader.load(false);
     * 
     * // Load all assets immediately
     * loader.load(true);
     */
    self.load = function() {
        if (!file_exists(self.__projectDir + "/assets.json")) return;

        // Load all assets by UUID
        self.jsonAssets = self.__readJson(self.__projectDir + "/assets.json");

        // Build name->entry map
        for (var i = 0, il = array_length(self.jsonAssets.assets); i < il; i++) {
            var entry = self.jsonAssets.assets[i];
            self.__jsonAssetsByName[$ entry.name] = entry;
        }

        if (self.autoLoad) {
            log(self.jsonAssets)
            var assetUUIDs = array_map(self.jsonAssets.assets, function(entry) { return entry.uuid; });
            self.loadAssets(undefined, assetUUIDs);
        }
    };
    
    /**
     * @function loadAssets
     * @description Loads specific assets by name or UUID. Uses a two-pass loading system:
     * Pass 1: Loads asset metadata and binary resources (textures, geometry)
     * Pass 2: Links asset references (materials->textures, meshes->materials)
     * 
     * @param {String|Array<String>} assetNames - Asset name(s) to load. Can be a single string or array of strings
     * @param {String|Array<String>} assetUUIDs - Asset UUID(s) to load. Can be a single string or array of strings (takes priority over names)
     * 
     * @example
     * // Load single asset by name
     * loader.loadAssets("MyTexture");
     * 
     * // Load multiple assets by name
     * loader.loadAssets(["Texture1", "Material1", "Mesh1"]);
     * 
     * // Load by UUID (avoids name conflicts)
     * loader.loadAssets(undefined, "abc-123-def");
     * 
     * // Load multiple by UUID
     * loader.loadAssets(undefined, ["uuid-1", "uuid-2"]);
     */
    self.loadAssets = function(assetNames = undefined, assetUUIDs = undefined) {
        var assetList = self.jsonAssets.assets;
        
        // Determine which assets to load
        var uuidsToLoad = [];
        
        if (assetUUIDs != undefined) {
            // Use UUIDs directly
            if (!is_array(assetUUIDs)) {
                uuidsToLoad = [assetUUIDs];
            } else {
                uuidsToLoad = assetUUIDs;
            }
        } else if (assetNames != undefined) {
            // Convert names to UUIDs
            if (!is_array(assetNames)) {
                assetNames = [assetNames];
            }
            
            // Find UUIDs for requested names
            for (var i = 0, il = array_length(assetNames); i < il; i++) {
                var assetName = assetNames[i];
                var entry = self.__jsonAssetsByName[$ assetName];
                
                if (entry == undefined) {
                    show_debug_message("[UeProjectLoader] Asset not found: " + assetName);
                    continue;
                }
                
                array_push(uuidsToLoad, entry.uuid);
            }
        } else {
            show_debug_message("[UeProjectLoader] loadAssets: no assets specified");
            return;
        }
        
        // Pass 1: Load requested assets and their metadata
        for (var i = 0, il = array_length(uuidsToLoad); i < il; i++) {
            var uuid = uuidsToLoad[i];
            
            // Skip if already loaded
            if (self.assets[$ uuid] != undefined) continue;
            
            // Find asset type from assets.json
            var type = undefined;
            for (var j = 0, jl = array_length(assetList); j < jl; j++) {
                if (assetList[j].uuid == uuid) {
                    type = assetList[j].type;
                    break;
                }
            }
            
            if (type == undefined) {
                show_debug_message("[UeProjectLoader] Asset type not found for UUID: " + uuid);
                continue;
            }
            
            // Load metadata
            var metaPath = self.__projectDir + "assets/" + uuid + "/metadata.json";
            if (file_exists(metaPath)) {
                var metadata = self.__readJson(metaPath);
                
                // Create asset instance
                var asset = self.__createAsset(type, metadata, uuid);
                if (asset != undefined) {
                    self.assets[$ uuid] = asset;
                }
            }
        }
        
        // Pass 2: Link assets
        self.__linkAssets();
    };
    
    /**
     * @function getAsset
     * @description Retrieves a loaded asset by its UUID.
     * 
     * @param {String} uuid - The UUID of the asset to retrieve
     * @returns {Struct|undefined} The asset struct, or undefined if not found
     * 
     * @example
     * var myTexture = loader.getAsset("abc-123-def");
     * if (myTexture != undefined) {
     *     // Use texture
     * }
     */
    self.getAsset = function(uuid) {
        return self.assets[$ uuid];
    };

    /**
     * @function setScene
     * @description Populates the loader's scene with model instances from a scene asset.
     * Clears any existing scene content before populating.
     * 
     * @param {String} sceneName - Name of the scene to load (optional if sceneUUID is provided)
     * @param {String} sceneUUID - UUID of the scene to load (takes priority over sceneName)
     * 
     * @example
     * // Load scene by name
     * loader.setScene("MainScene");
     * 
     * // Load scene by UUID (avoids name conflicts)
     * loader.setScene(undefined, "scene-uuid-123");
     * 
     * // Access the populated scene
     * renderer.render(loader.scene, camera);
     */
    self.setScene = function(sceneName = undefined, sceneUUID = undefined) {
        // Determine which scene to load
        var targetUUID = undefined;
        
        if (sceneUUID != undefined) {
            // Use UUID directly
            targetUUID = sceneUUID;
        } else if (sceneName != undefined) {
            // Find UUID by name
            targetUUID = self.__jsonAssetsByName[$ sceneName].uuid;
            
            if (targetUUID == undefined) {
                show_error("[UeProjectLoader] Scene not found: " + sceneName, true);
                return;
            }
        } else {
            show_error("[UeProjectLoader] setScene: no scene specified", true);
            return;
        }
        
        // Clear existing scene
        self.scene.clear();
        
        // Get scene asset
        var sceneAsset = self.assets[$ targetUUID];
        if (sceneAsset == undefined || sceneAsset[$ "type"] != "Scene") {
            show_error("[UeProjectLoader] Scene not found: " + targetUUID, true);
            return;
        }
        
        // Get scene metadata for ModelInstances
        if (sceneAsset[$ "__metadata"] == undefined) return;
        
        var children = sceneAsset.__metadata[$ "children"];
        if (children == undefined) return;
        
        // Create instances
        for (var i = 0; i < array_length(children); i++) {
            var child = children[i];
            if (is_struct(child) && child[$ "type"] == "ModelInstance") {
                var modelUUID = child[$ "model"];
                var model = self.assets[$ modelUUID];
                
                if (model != undefined && model[$ "isMesh"] == true) {
                    var instance = model.createInstance();
                    instance.type = "ModelInstance";
                    
                    // Apply transform
                    if (child[$ "position"] != undefined) {
                        var pos = child.position;
                        instance.position.set(pos[0], pos[1], pos[2]);
                    }
                    if (child[$ "rotation"] != undefined) {
                        var rot = child.rotation;
                        instance.rotation.set(rot[0], rot[1], rot[2], rot[3]);
                    }
                    if (child[$ "scale"] != undefined) {
                        var scl = child.scale;
                        instance.scale.set(scl[0], scl[1], scl[2]);
                    }
                    
                    self.scene.add(instance);
                }
            }
        }
    };

    self.__createAsset = function(type, metadata, uuid) {
        switch (type) {
            case "Texture":
                var texture = new UeTexture();
                texture.fromJSON(metadata);
                // Load texture image
                var texturePath = self.__projectDir + "assets/" + uuid + "/texture.png";
                if (file_exists(texturePath)) {
                    texture.import(texturePath);
                }
                return texture;
                
            case "Material":
                var material = new UeMaterial();
                // Store metadata for linking pass
                material.__metadata = metadata;
                return material;
                
            case "Mesh":
                var mesh = new UeMesh();
                mesh.fromJSON(metadata);
                // Load geometry
                var geometryPath = self.__projectDir + "assets/" + uuid + "/geometry.buf";
                if (file_exists(geometryPath)) {
                    var geometry = new UeBufferGeometry();
                    geometry.import(geometryPath);
                    mesh.geometry = geometry;
                }
                // Store metadata for material linking
                mesh.__metadata = metadata;
                return mesh;
                
            case "Scene":
                var scene = new UeScene();
                scene.fromJSON(metadata);
                // Store metadata for instance creation
                scene.__metadata = metadata;
                return scene;
        }
        return undefined;
    };
    
    self.__linkAssets = function() {
        var assetUUIDs = struct_get_names(self.assets);
        
        // Build texture map
        var texturesByUUID = {};
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assets[$ assetUUIDs[i]];
            if (asset[$ "type"] == "Texture") {
                texturesByUUID[$ asset.uuid] = asset;
            }
        }
        
        // Link materials to textures
        var materialsByUUID = {};
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assets[$ assetUUIDs[i]];
            if (asset[$ "type"] == "Material") {
                materialsByUUID[$ asset.uuid] = asset;
                if (asset[$ "__metadata"] != undefined) {
                    asset.fromJSON(asset.__metadata, texturesByUUID);
                    delete asset.__metadata;
                }
            }
        }
        
        // Link meshes to materials
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assets[$ assetUUIDs[i]];
            if (asset[$ "type"] == "Mesh" && asset[$ "__metadata"] != undefined) {
                var materialUUID = asset.__metadata[$ "material"];
                if (materialUUID != undefined && materialsByUUID[$ materialUUID] != undefined) {
                    asset.material = materialsByUUID[$ materialUUID];
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

    self.load();
}
