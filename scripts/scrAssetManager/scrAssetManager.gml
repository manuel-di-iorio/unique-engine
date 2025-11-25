/// @description Asset Manager - Manages all assets with hierarchical structure

function AssetManager() constructor {
    // Flat array of all assets
    self.assets = [];
    
    /**
     * Add an asset to the manager
     * @param {String} type - Asset type: "Texture", "Material", "Mesh", "Scene", "Light", "Camera", "Folder"
     * @param {Struct} asset - The asset to add
     * @param {Struct} parent - Optional parent asset for hierarchical assets
     */
    function addAsset(type, asset, parent = undefined) {
        // Always add to flat assets array
        array_push(self.assets, asset);
        
        show_debug_message("[ASSET] Adding asset: " + asset.name + " (type: " + asset.type + ")");
        
        // Set __parentUI if asset is in a folder (from treeview)
        if (asset[$ "__treeviewItem"] != undefined) {
            var treeviewItem = asset.__treeviewItem;
            
            // The parent of a treeview item is the "Items" container
            // The parent of "Items" is the actual parent treeview item
            if (treeviewItem[$ "parent"] != undefined && treeviewItem.parent[$ "parent"] != undefined) {
                var parentTreeviewItem = treeviewItem.parent.parent;
                
                // Check if parent item has an asset
                if (parentTreeviewItem[$ "asset"] != undefined) {
                    // Store parent UUID in __parentUI (used for saving hierarchy)
                    // This works for both Folders and other assets (like Meshes acting as parents)
                    asset.__parentUI = parentTreeviewItem.asset.uuid;
                    show_debug_message("[ASSET] Set __parentUI for '" + asset.name + "' to: " + parentTreeviewItem.asset.name + " (UUID: " + asset.__parentUI + ")");
                } else {
                    show_debug_message("[ASSET] Parent treeview item has no asset for: " + asset.name);
                }
            } else {
                show_debug_message("[ASSET] No parent treeview item for: " + asset.name);
            }
        } else {
            show_debug_message("[ASSET] No treeview item for: " + asset.name);
        }
        
        // Handle 3D hierarchy parent (not folder)
        if (parent != undefined) {
            show_debug_message("[ASSET] Setting 3D parent for '" + asset.name + "' to: " + parent.name);
            // If parent has add() method, use it (Object3D hierarchy)
            if (parent[$ "add"] != undefined) {
                parent.add(asset);
            } else {
                // Add to parent children array
                array_push(parent.children, asset);
            }
            asset.parent = parent;
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
        
        // Clear __parentUI if it was in a folder
        if (asset[$ "__parentUI"] != undefined) {
            asset.__parentUI = undefined;
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
        
        // Clean up instances if this is a model
        if (asset[$ "instances"] != undefined) {
            asset.instances.clear();
        }
        
        // Track removal
        __trackChange("delete", asset);
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
    }
    
    /**
     * Mark an asset as edited (triggers unsaved changes)
     * @param {Struct} asset - The asset that was modified
     */
    function editAsset(asset) {
        self.__trackChange("edit", asset);
        
        // Rebuild the box in the next frame in order to wait first for the matrix updates
        if (asset.type == "Mesh" || asset.type == "ModelInstance") {
            self.updateAssetMatrix(asset);
        }
    }
    
    /**
     * Internal: Track a change to an asset
     * @param {String} action - "create", "edit", "delete"
     * @param {Struct} asset - The asset that was modified
     */
    function __trackChange(action, asset) {
        var projectManager = oSceneEditor.projectManager;
        
        // VALIDATION: Don't track invalid assets
        if (asset == undefined) {
            show_debug_message("[TRACK] WARNING: Attempted to track undefined asset. Action: " + action);
            return;
        }
        
        // VALIDATION: Don't track assets without names (except delete)
        if (action != "delete" && (asset[$ "name"] == undefined || asset.name == "")) {
            show_debug_message("[TRACK] WARNING: Attempted to track asset with empty name. UUID: " + (asset[$ "uuid"] ?? "no-uuid") + ", Type: " + (asset[$ "type"] ?? "undefined") + ", Action: " + action);
            return;
        }
        
        // VALIDATION: Don't track generic Object3D types (these should not be saved)
        if (action != "delete" && asset[$ "type"] == "Object3D") {
            show_debug_message("[TRACK] WARNING: Attempted to track Object3D (should not be saved). UUID: " + asset.uuid + ", Name: " + (asset[$ "name"] ?? "no-name") + ", Action: " + action);
            return;
        }

        // ModelInstance objects belong to Scenes: instead of tracking the instance itself,
        // track the parent Scene as edited so scene changes (rename/move instance) are saved.
        if (asset[$ "type"] == "ModelInstance") {
            // Find nearest ancestor Scene
            var scene = asset[$ "parent"];
            while (scene != undefined && ((scene[$ "type"] ?? scene[$ "assetType"]) != "Scene")) {
                scene = scene[$ "parent"];
            }

            if (scene != undefined) {
                var sceneUuid = scene[$ "uuid"] ?? scene[$ "uuid"];
                show_debug_message("[TRACK] ModelInstance change will track parent Scene as edit. Scene UUID: " + (sceneUuid ?? "no-uuid") + ", Instance: " + (asset[$ "name"] ?? "no-name") + ", Action: " + action);

                // If the scene is not already tracked, mark it as edited
                var existingSceneChange = projectManager.changes[$ sceneUuid];
                if (existingSceneChange == undefined) {
                    projectManager.changes[$ sceneUuid] = {
                        action: "edit",
                        asset: scene
                    };
                    projectManager.markAsUnsaved();
                }
                return;
            } else {
                show_debug_message("[TRACK] WARNING: ModelInstance has no parent Scene, skipping tracking. Instance UUID: " + (asset[$ "uuid"] ?? "no-uuid"));
                return;
            }
        }
        
        show_debug_message("[TRACK] Tracking change: " + action + " for asset '" + (asset[$ "name"] ?? "no-name") + "' (type: " + (asset[$ "type"] ?? "unknown") + ", UUID: " + (asset[$ "uuid"] ?? "no-uuid") + ")");
        
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
     * Update the matrix of an asset and of the box helper
     * The update is scheduled in the next frame in order to wait for box helper update
     */
    function updateAssetMatrix(asset) {
        call_later(1, time_source_units_frames, method({ asset }, function() {
            asset.updateMatrix();
            asset.updateMatrixWorld(true);
            
            // Update the box helper to match the new transform
            oSceneEditor.sceneManager.boxHelper.update();
            
            oSceneEditor.sceneManager.transformControls.updateGizmo();
        }));
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
