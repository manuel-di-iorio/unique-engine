/// @description Asset Manager - Manages all assets with hierarchical structure

function AssetManager() constructor {
    // Flat array of all assets
    self.assets = [];
    
    // Asset lookup by name for quick access
    self.assetsByName = {};
    
    /**
     * Add an asset to the manager
     * @param {String} type - Asset type: "Texture", "Material", "Mesh", "Scene", "Light", "Camera", "Folder"
     * @param {Struct} asset - The asset to add
     * @param {Struct} parent - Optional parent asset for hierarchical assets
     */
    function addAsset(type, asset, parent = undefined) {
        // Always add to flat assets array
        array_push(self.assets, asset);
        
        // Set __folder if asset is in a folder (from treeview)
        if (asset[$ "__treeviewItem"] != undefined) {
            var treeviewItem = asset.__treeviewItem;
            
            // The parent of a treeview item is the "Items" container
            // The parent of "Items" is the actual parent treeview item
            if (treeviewItem[$ "parent"] != undefined && treeviewItem.parent[$ "parent"] != undefined) {
                var parentTreeviewItem = treeviewItem.parent.parent;
                
                // Check if parent item has an asset
                if (parentTreeviewItem[$ "asset"] != undefined) {
                    if (parentTreeviewItem.asset[$ "type"] == "Folder") {
                        asset.__folder = parentTreeviewItem.asset.uuid;
                    }
                }
            }
        }
        
        // Handle 3D hierarchy parent (not folder)
        if (parent != undefined) {
            // If parent has add() method, use it (Object3D hierarchy)
            if (parent[$ "add"] != undefined) {
                parent.add(asset);
            } else {
                // Add to parent children array
                array_push(parent.children, asset);
            }
            asset.parent = parent;
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
        // Remove from flat assets array
        var index = array_find_index(self.assets, method({ asset }, function(item) {
            return item == asset;
        }));
        
        if (index != -1) {
            array_delete(self.assets, index, 1);
        }
        
        // Clear __folder if it was in a folder
        if (asset[$ "__folder"] != undefined) {
            asset.__folder = undefined;
        }
        
        // Remove from 3D parent if it has one
        if (asset[$ "parent"] != undefined && asset.parent != undefined) {
            // If parent has remove() method, call it (Object3D hierarchy)
            if (asset.parent[$ "remove"] != undefined) {
                asset.parent.remove(asset);
            }
            // Fallback: remove from parent's children array
            else if (asset.parent[$ "children"] != undefined) {
                var pchildren = asset.parent.children;
                for (var i = array_length(pchildren) - 1; i >= 0; i--) {
                    if (pchildren[i] == asset) {
                        array_delete(pchildren, i, 1);
                        break;
                    }
                }
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
     * Get all assets of a specific type (root level only, not in folders)
     * @param {String} type - Asset type (case insensitive)
     * @return {Array} Array of assets
     */
    function getAssetsByType(type) {
        var result = [];
        for (var i = 0; i < array_length(self.assets); i++) {
            var asset = self.assets[i];
            if (asset[$ "type"] == type) {
                array_push(result, asset);
            }
        }
        return result;
    }
    
    /**
     * Clear all assets
     */
    function clear() {
        self.assets = [];
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
