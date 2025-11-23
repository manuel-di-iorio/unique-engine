/// @description Asset Manager - Manages all assets with hierarchical structure

function AssetManager() constructor {
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
     * @param {String} type - Asset type: "Texture", "Material", "Mesh", "Scene", "Light", "Camera", "Folder"
     * @param {Struct} asset - The asset to add
     * @param {Struct} parent - Optional parent asset for hierarchical assets
     */
    function addAsset(type, asset, parent = undefined) {
        // Add to the appropriate array if it's a root asset
        if (parent == undefined) {
            switch (type) {
                case "Texture":
                    array_push(self.textures, asset);
                    break;
                case "Material":
                    array_push(self.materials, asset);
                    break;
                case "Mesh":
                    array_push(self.models, asset);
                    break;
                case "Scene":
                    array_push(self.scenes, asset);
                    break;
                case "Light":
                    array_push(self.lights, asset);
                    break;
                case "Camera":
                    array_push(self.cameras, asset);
                    break;
                case "Folder":
                    array_push(self.folders, asset);
                    break;
            }
        } else {
            // Add to parent's hierarchy
            // If parent is a Folder struct, push into its children array
            if (parent[$ "type"] != undefined && parent[$ "type"] == "Folder") {
                asset.parent = parent;
                if (parent[$ "children"] == undefined) parent.children = [];
                array_push(parent.children, asset);
            }
            // If parent is an Object3D-like object with add(), use that
            else if (parent[$ "add"] != undefined) {
                parent.add(asset);
                asset.parent = parent;
            }
            // Fallback: if parent has a children array, push into it
            else if (parent[$ "children"] != undefined) {
                asset.parent = parent;
                array_push(parent.children, asset);
            }
        }
        
        // Add to lookup map
        if (asset[$ "name"] != undefined) {
            self.assetsByName[$ asset.name] = asset;
        }
        
        // Track creation
        __trackChange("create", asset);
    }
    
    /**
     * Remove an asset from the manager
     * @param {String} type - Asset type
     * @param {Struct} asset - The asset to remove
     */
    function removeAsset(type, asset) {
        var list = undefined;
        
        switch (type) {
            case "Texture": list = self.textures; break;
            case "Material": list = self.materials; break;
            case "Mesh": list = self.models; break;
            case "Scene": list = self.scenes; break;
            case "Light": list = self.lights; break;
            case "Camera": list = self.cameras; break;
            case "Folder": list = self.folders; break;
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
            // If parent is Folder struct, remove from children array
            if (asset.parent[$ "type"] != undefined && asset.parent[$ "type"] == "Folder") {
                var pchildren = asset.parent.children;
                for (var i = array_length(pchildren) - 1; i >= 0; i--) {
                    if (pchildren[i] == asset) {
                        array_delete(pchildren, i, 1);
                        break;
                    }
                }
            }
            // If parent has remove() method, call it
            else if (asset.parent[$ "remove"] != undefined) {
                asset.parent.remove(asset);
            }
        }
        
        // Remove from lookup map
        if (asset[$ "name"] != undefined) {
            variable_struct_remove(self.assetsByName, asset.name);
        }
        
        // Clean up instances if this is a model
        if (asset[$ "instances"] != undefined) {
            asset.instances.clear();
        }
        
        // Track removal
        __trackChange("delete", asset);
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
     * @param {String} type - Asset type (case insensitive)
     * @return {Array} Array of assets
     */
    function getAssetsByType(type) {
        switch (type) {
            case "Texture": return self.textures;
            case "Material": return self.materials;
            case "Mesh": return self.models;
            case "Scene": return self.scenes;
            case "Light": return self.lights;
            case "Camera": return self.cameras;
            case "Folder": return self.folders;
        }
        return [];
    }
    
    /**
     * Get all assets of a type recursively (including those in folders)
     * @param {String} type - Asset type (texture, material, model, etc)
     * @returns {Array} All assets of the specified type
     */
    function getAllAssetsByType(type) {
        var result = [];
        var rootAssets = getAssetsByType(type);
        
        // Add root assets
        for (var i = 0; i < array_length(rootAssets); i++) {
            array_push(result, rootAssets[i]);
            
            // If collecting meshes, also collect their children recursively
            if (type == "Mesh" && rootAssets[i][$ "children"] != undefined) {
                __collectMeshChildren(rootAssets[i], result);
            }
        }
        
        // Recursively collect from folders
        __collectAssetsFromFolders(self.folders, type, result);
        
        return result;
    }
    
    /**
     * Helper: recursively collect mesh children
     */
    function __collectMeshChildren(mesh, result) {
        for (var i = 0; i < array_length(mesh.children); i++) {
            var child = mesh.children[i];
            if (child[$ "isMesh"] == true) {
                array_push(result, child);
                
                // Recurse into this child's children
                if (child[$ "children"] != undefined) {
                    __collectMeshChildren(child, result);
                }
            }
        }
    }
    
    /**
     * Helper: recursively collect assets from folders
     */
    function __collectAssetsFromFolders(folders, type, result) {
        for (var i = 0, il = array_length(folders); i < il; i++) {
            var folder = folders[i];
            
            if (folder[$ "children"] != undefined) {
                var childFolders = [];
                
                for (var j = 0; j < array_length(folder.children); j++) {
                    var child = folder.children[j];
                    
                    if (child[$ "type"] == "Folder") {
                        array_push(childFolders, child);
                    } else if (child[$ "type"] == type) {
                        array_push(result, child);
                        
                        // If collecting meshes, also collect their children recursively
                        if (type == "Mesh" && child[$ "children"] != undefined) {
                            __collectMeshChildren(child, result);
                        }
                    }
                }
                
                // Recurse into subfolders
                if (array_length(childFolders) > 0) {
                    __collectAssetsFromFolders(childFolders, type, result);
                }
            }
        }
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
     * Mark an asset as edited (triggers unsaved changes)
     * @param {Struct} asset - The asset that was modified
     */
    function editAsset(asset) {
        __trackChange("edit", asset);
        
        // Rebuild the box in the next frame in order to wait first for the matrix updates
        if (asset.type == "Mesh" || asset.type == "ModelInstance") {
            oSceneEditor.sceneManager.boxHelper.needsUpdate = true;
        }
    }
    
    /**
     * Internal: Track a change to an asset
     * @param {String} action - "create", "edit", "delete"
     * @param {Struct} asset - The asset that was modified
     */
    function __trackChange(action, asset) {
        var projectManager = oSceneEditor.projectManager;
        
        var uuid = asset.uuid;
        var existing = projectManager.changes[$ uuid];
        
        // If asset already has a change tracked
        if (existing != undefined) {
            // create -> delete = no change needed (asset never existed in saved state)
            if (existing.action == "create" && action == "delete") {
                variable_struct_remove(projectManager.changes, uuid);
                // Check if there are still other changes
                if (variable_struct_names_count(projectManager.changes) == 0) {
                    projectManager.markAsSaved();
                }
                return;
            }
            
            // create -> edit = still create (new asset with edits)
            if (existing.action == "create" && action == "edit") {
                return; // Keep the create
            }
            
            // edit -> delete = delete (override edit with delete)
            if (existing.action == "edit" && action == "delete") {
                existing.action = "delete";
                projectManager.markAsUnsaved();
                return;
            }
            
            // edit -> edit = keep edit (already tracked)
            if (existing.action == "edit" && action == "edit") {
                return; // Already tracked
            }
        } else {
            // New change
            projectManager.changes[$ uuid] = {
                action: action,
                asset: asset
            };
            projectManager.markAsUnsaved();
        }
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
}
