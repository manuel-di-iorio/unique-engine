/// @description Asset Manager - Manages all assets with hierarchical structure
/// This replaces the category-based system with a free-form hierarchy

function UeAssetManager() constructor {
    // Root containers for different asset types
    self.textures = [];      // Array of texture assets
    self.materials = [];     // Array of material assets
    self.models = [];        // Array of model assets (with hierarchy)
    self.scenes = [];        // Array of scene assets (with instances)
    self.lights = [];        // Array of light assets
    self.cameras = [];       // Array of camera assets
    self.folders = [];       // Array of folder structures (for UI organization)
    
    // Asset lookup by name for quick access
    self.assetsByName = {};
    
    /**
     * Add an asset to the manager
     * @param {String} type - Asset type: "texture", "material", "model", "scene", "light", "camera", "folder"
     * @param {Struct} asset - The asset to add
     * @param {Struct} parent - Optional parent asset for hierarchical assets
     */
    function addAsset(type, asset, parent = undefined) {
        // Add to the appropriate array if it's a root asset
        if (parent == undefined) {
            switch (type) {
                case "texture":
                    array_push(self.textures, asset);
                    break;
                case "material":
                    array_push(self.materials, asset);
                    break;
                case "model":
                    array_push(self.models, asset);
                    break;
                case "scene":
                    array_push(self.scenes, asset);
                    break;
                case "light":
                    array_push(self.lights, asset);
                    break;
                case "camera":
                    array_push(self.cameras, asset);
                    break;
                case "folder":
                    array_push(self.folders, asset);
                    break;
            }
        } else {
            // Add to parent's hierarchy
            if (parent[$ "add"] != undefined) {
                parent.add(asset);
            }
        }
        
        // Add to lookup map
        if (asset[$ "name"] != undefined) {
            self.assetsByName[$ asset.name] = asset;
        }
    }
    
    /**
     * Remove an asset from the manager
     * @param {String} type - Asset type
     * @param {Struct} asset - The asset to remove
     */
    function removeAsset(type, asset) {
        var list = undefined;
        
        switch (type) {
            case "texture": list = self.textures; break;
            case "material": list = self.materials; break;
            case "model": list = self.models; break;
            case "scene": list = self.scenes; break;
            case "light": list = self.lights; break;
            case "camera": list = self.cameras; break;
            case "folder": list = self.folders; break;
        }
        
        if (list != undefined) {
            var index = array_find_index(list, method({ asset }, function(item) {
                return item == asset;
            }));
            
            if (index != -1) {
                array_delete(list, index, 1);
            }
        }
        
        // Remove from parent if it has one
        if (asset[$ "parent"] != undefined && asset.parent != undefined) {
            if (asset.parent[$ "remove"] != undefined) {
                asset.parent.remove(asset);
            }
        }
        
        // Remove from lookup map
        if (asset[$ "name"] != undefined) {
            delete self.assetsByName[$ asset.name];
        }
        
        // Clean up instances if this is a model
        if (asset[$ "instances"] != undefined) {
            asset.instances.clear();
        }
    }
    
    /**
     * Get an asset by name
     * @param {String} name - Asset name
     * @return {Struct|undefined} The asset or undefined if not found
     */
    function getAssetByName(name) {
        return self.assetsByName[$ name];
    }
    
    /**
     * Check if an asset name is available
     * @param {String} name - Name to check
     * @return {Bool} True if available
     */
    function isNameAvailable(name) {
        return self.assetsByName[$ name] == undefined;
    }
    
    /**
     * Get all assets of a specific type
     * @param {String} type - Asset type
     * @return {Array} Array of assets
     */
    function getAssetsByType(type) {
        switch (type) {
            case "texture": return self.textures;
            case "material": return self.materials;
            case "model": return self.models;
            case "scene": return self.scenes;
            case "light": return self.lights;
            case "camera": return self.cameras;
            case "folder": return self.folders;
        }
        return [];
    }
    
    /**
     * Clear all assets
     */
    function clear() {
        self.textures = [];
        self.materials = [];
        self.models = [];
        self.scenes = [];
        self.lights = [];
        self.cameras = [];
        self.folders = [];
        self.assetsByName = {};
    }
    
    /**
     * Validate asset hierarchy rules
     * @param {Struct} asset - Asset being moved/added
     * @param {Struct} target - Target parent asset
     * @return {Bool} True if the hierarchy is valid
     */
    function validateHierarchy(asset, target) {
        var assetType = asset[$ "type"] ?? asset[$ "assetType"];
        var targetType = target[$ "type"] ?? target[$ "assetType"];
        
        // Textures and materials cannot have children
        if (targetType == "Texture" || targetType == "Material") {
            return false;
        }
        
        // Models can have models as children
        if ((assetType == "Mesh" || assetType == "ModelInstance") && 
            (targetType == "Mesh" || targetType == "ModelInstance")) {
            return true;
        }
        
        // Scenes can only contain model instances
        if (targetType == "Scene") {
            if (assetType == "Mesh" || assetType == "ModelInstance") {
                return true;
            }
            return false;
        }
        
        return false;
    }
    
    /**
     * Export all assets to a JSON structure
     * @param {Struct} treeview - The treeview to extract folder structure from
     * @return {Struct} JSON-compatible structure
     */
    function toJSON(treeview = undefined) {
        var json = {
            textures: {},
            materials: {},
            models: {},
            scenes: {},
            lights: {},
            cameras: {},
            folders: [] // Array to preserve folder hierarchy
        };
        
        // Helper function to convert asset to JSON recursively
        var assetToJSON = function(asset) {
            var data = {
                type: asset.type,
                name: asset.name
            };
            
            // Add type-specific data
            if (asset[$ "toJSON"] != undefined) {
                data = asset.toJSON();
            }
            
            // Add children recursively
            if (asset[$ "children"] != undefined && array_length(asset.children) > 0) {
                data.children = [];
                for (var i = 0; i < array_length(asset.children); i++) {
                    array_push(data.children, assetToJSON(asset.children[i]));
                }
            }
            
            return data;
        };
        
        // Helper to export folder structure from treeview
        var exportTreeviewItem = function(item) {
            var itemData = {
                name: item.name ?? "Unnamed",
                type: item.type,
                assetType: item.assetType
            };
            
            // If it has an asset, reference it by name
            if (item[$ "asset"] != undefined && item.asset != undefined) {
                itemData.assetName = item.asset.name;
            }
            
            // Export children recursively
            if (item[$ "Items"] != undefined && item.Items[$ "children"] != undefined) {
                itemData.children = [];
                var children = item.Items.children;
                for (var i = 0; i < array_length(children); i++) {
                    array_push(itemData.children, exportTreeviewItem(children[i]));
                }
            }
            
            return itemData;
        };
        
        // Convert each asset type
        for (var i = 0; i < array_length(self.textures); i++) {
            var asset = self.textures[i];
            json.textures[$ asset.name] = assetToJSON(asset);
        }
        
        for (var i = 0; i < array_length(self.materials); i++) {
            var asset = self.materials[i];
            json.materials[$ asset.name] = assetToJSON(asset);
        }
        
        for (var i = 0; i < array_length(self.models); i++) {
            var asset = self.models[i];
            json.models[$ asset.name] = assetToJSON(asset);
        }
        
        for (var i = 0; i < array_length(self.scenes); i++) {
            var asset = self.scenes[i];
            json.scenes[$ asset.name] = assetToJSON(asset);
        }
        
        // Export folder structure from treeview if provided
        if (treeview != undefined && treeview[$ "Items"] != undefined) {
            var rootItems = treeview.Items[$ "children"];
            if (rootItems != undefined) {
                for (var i = 0; i < array_length(rootItems); i++) {
                    array_push(json.folders, exportTreeviewItem(rootItems[i]));
                }
            }
        }
        
        return json;
    }
}
