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
 * loader.loadAssetsByUuid(["uuid-1", "uuid-2"]);
 * 
 * // Populate a scene
 * loader.setScene("MainScene");
 * 
 * @param {Struct} data - Configuration options
 * @param {Bool} data.autoLoad - If true, automatically loads all assets on construction (default: true)
 */
function UeProjectLoader(data = {}) constructor {
    self.autoLoad = data[$ "autoLoad"] ?? true;
    
    /// @member {UeScene} scene - The active scene populated by setScene()
    self.scene = new UeScene();
    
    /// @member {String} __projectPath - Path to the project's assets.json file
    self.__projectPath = "Unique Project";

    /// @member {Struct} assets - Flat map of all loaded assets indexed by UUID
    self.assetsByUuid = {};
    
    /// @member {Struct} assetsByName - Flat map of all loaded assets indexed by name
    self.assetsByName = {};

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
        if (!file_exists(self.__projectPath + "/assets.json")) return;

        // Load all assets by UUID
        self.jsonAssets = self.__readJson(self.__projectPath + "/assets.json");

        // Build maps from the UUID-only assets list. For each UUID read its metadata
        for (var i = 0, il = array_length(self.jsonAssets.assets); i < il; i++) {
            var uuid = self.jsonAssets.assets[i];
            var metadataPath = self.__projectPath + "/assets/" + uuid + "/metadata.json";
            if (!file_exists(metadataPath)) continue;
            var entry = self.__readJson(metadataPath);
            entry.uuid = uuid;
            self.assetsByUuid[$ uuid] = entry;
            if (entry.name != undefined && entry.name != "") {
                self.assetsByName[$ entry.name] = entry;
            }
        }

        if (self.autoLoad) {
            self.loadAssets();
        }
    };
    
    /**
     * @function loadAssets
     * @description Loads specific assets by name. Uses a two-pass loading system:
     * Pass 1: Loads asset metadata and binary resources (textures, geometry)
     * Pass 2: Links asset references (materials->textures, meshes->materials)
     * 
     * @param {...String} assetNames - Asset name(s) to load. If no arguments provided, loads all assets
     * 
     * @example
     * // Load all assets
     * loader.loadAssets();
     * 
     * // Load single asset by name
     * loader.loadAssets("MyTexture");
     * 
     * // Load multiple assets by name
     * loader.loadAssets("Texture1", "Material1", "Mesh1");
     */
    self.loadAssets = function() {
        var assetNames = [];
        
        // Handle arguments (support both array and variable arguments)
        if (argument_count == 1 && is_array(argument[0])) {
            assetNames = argument[0];
        } else {
            for (var i = 0; i < argument_count; i++) {
                array_push(assetNames, argument[i]);
            }
        }
        
        // If no arguments, load all assets
        if (array_length(assetNames) == 0) {
            var assetList = self.jsonAssets.assets;
            for (var i = 0; i < array_length(assetList); i++) {
                var uuid = assetList[i];
                var entry = self.assetsByUuid[$ uuid];
                if (entry != undefined && entry.name != undefined) array_push(assetNames, entry.name);
            }
        }
        
        // Convert names to UUIDs
        var uuidsToLoad = [];
        for (var i = 0; i < array_length(assetNames); i++) {
            var assetName = assetNames[i];
            var entry = self.assetsByName[$ assetName];

            if (entry == undefined) {
                continue;
            }

            array_push(uuidsToLoad, entry.uuid);
        }
        
        // Load by UUIDs
        self.__loadAssetsInternal(uuidsToLoad);
    };
    
    /**
     * @function loadAssetsByUuid
     * @description Loads specific assets by UUID. Uses a two-pass loading system:
     * Pass 1: Loads asset metadata and binary resources (textures, geometry)
     * Pass 2: Links asset references (materials->textures, meshes->materials)
     * 
     * @param {...String} assetUUIDs - Asset UUID(s) to load. If no arguments provided, loads all assets
     * 
     * @example
     * // Load all assets
     * loader.loadAssetsByUuid();
     * 
     * // Load single asset by UUID
     * loader.loadAssetsByUuid("abc-123-def");
     * 
     * // Load multiple assets by UUID
     * loader.loadAssetsByUuid("uuid-1", "uuid-2", "uuid-3");
     */
    self.loadAssetsByUuid = function() {
        var uuidsToLoad = [];
        
        // Handle arguments (support both array and variable arguments)
        if (argument_count == 1 && is_array(argument[0])) {
            uuidsToLoad = argument[0];
        } else {
            for (var i = 0; i < argument_count; i++) {
                array_push(uuidsToLoad, argument[i]);
            }
        }
        
        // If no arguments, load all assets
        if (array_length(uuidsToLoad) == 0) {
            var assetList = self.jsonAssets.assets;
            for (var i = 0; i < array_length(assetList); i++) {
                array_push(uuidsToLoad, assetList[i]);
            }
        }
        
        self.__loadAssetsInternal(uuidsToLoad);
    };

    self.__loadAssetsInternal = function(uuidsToLoad) {
        var assetList = self.jsonAssets.assets;
        
        // Pass 1: Load requested assets and their metadata
        for (var i = 0, il = array_length(uuidsToLoad); i < il; i++) {
            var uuid = uuidsToLoad[i];
            
            // Skip if already loaded
            var existing = self.assetsByUuid[$ uuid];
            if (existing != undefined && existing[$ "isLoaded"] == true) continue;

            // Load metadata
            var metaPath = self.__projectPath + "/assets/" + uuid + "/metadata.json";
            if (file_exists(metaPath)) {
                var metadata = self.__readJson(metaPath);
                
                // Create asset instance
                var asset = self.__createAsset(metadata, uuid);
                if (asset != undefined) {
                    self.assetsByUuid[$ uuid] = asset;
                    if (asset[$ "name"] != undefined && asset.name != "") {
                        self.assetsByName[$ asset.name] = asset;
                    }
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
    self.getAsset = function(name) {
        return self.assetsByName[$ name];
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
    self.setScene = function(sceneName = undefined) {
        // Get scene asset
        var sceneAsset = self.assetsByName[$ sceneName];
        if (sceneAsset == undefined || sceneAsset[$ "type"] != "Scene") {
            show_error("[UeProjectLoader] Scene not found: " + sceneName, true);
            return;
        }
        
        // Clear existing scene
        self.scene.clear();
        
        // Get scene metadata for ModelInstances
        if (sceneAsset[$ "__metadata"] == undefined) {
            return;
        }
        
        var children = sceneAsset.__metadata[$ "children"];
        if (children == undefined) {
            return;
        }
        
        // Create instances
        for (var i = 0; i < array_length(children); i++) {
            var child = children[i];
            if (is_struct(child) && child[$ "type"] == "ModelInstance") {
                var modelUUID = child[$ "model"];
                var model = self.assetsByUuid[$ modelUUID];
                
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

    self.__createAsset = function(metadata, uuid) {
        var asset = undefined;
        switch (metadata.type) {
            case "Texture":
                var texture = new UeTexture();
                texture.fromJSON(metadata);
                // Load texture image
                var texturePath = self.__projectPath + "/assets/" + uuid + "/texture.png";
                if (file_exists(texturePath)) {
                    texture.import(texturePath);
                }
                asset = texture;
                break;
                
            case "Material":
                var material = new UeMaterial();
                // Store metadata for linking pass
                material.__metadata = metadata;
                asset = material;
                break;

            case "Mesh":
                var mesh = new UeMesh();
                mesh.fromJSON(metadata);
                // Load geometry
                var geometryPath = self.__projectPath + "/assets/" + uuid + "/geometry.buf";
                if (file_exists(geometryPath)) {
                    var geometry = new UeBufferGeometry();
                    geometry.import(geometryPath);
                    mesh.geometry = geometry;
                }
                // Store metadata for material linking
                mesh.__metadata = metadata;
                asset = mesh;
                break;
                
            case "Scene":
                var scene = new UeScene();
                scene.fromJSON(metadata);
                // Store metadata for instance creation
                scene.__metadata = metadata;
                asset = scene;
                break;
        }
        
        if (asset != undefined) {
            asset.isLoaded = true;
            asset.name = metadata.name;
            asset.uuid = uuid;
        }
        return asset;
    };
    
    self.__linkAssets = function() {
        var assetUUIDs = struct_get_names(self.assetsByUuid);
        
        // Build texture map
        var texturesByUUID = {};
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assetsByUuid[$ assetUUIDs[i]];
            if (asset[$ "type"] == "Texture") {
                texturesByUUID[$ asset.uuid] = asset;
            }
        }
        
        // Link materials to textures
        var materialsByUUID = {};
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var asset = self.assetsByUuid[$ assetUUIDs[i]];
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
            var asset = self.assetsByUuid[$ assetUUIDs[i]];
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
