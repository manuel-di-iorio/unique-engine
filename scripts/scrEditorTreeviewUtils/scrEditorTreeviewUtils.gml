/// @description Treeview utility functions - Centralized helper functions for the editor treeview
/// These were previously scattered across scrEditorTreeviewOnAssetDrop, 
/// scrEditorTreeviewOnRemoveAsset, and scrEditorTreeviewOnModelImport as __editorTreeview_* globals.

// =============================================================================
// HIERARCHY QUERIES
// =============================================================================

/// Check if a treeview item is a descendant of another treeview item
/// @param {Struct} item The item to check
/// @param {Struct} potentialAncestor The potential ancestor item
/// @returns {Bool}
function editorTreeviewUtil_isDescendantOf(item, potentialAncestor) {
    if (item == undefined || potentialAncestor == undefined) return false;
    
    var p = item.parent; // This is the Items container node
    while (p != undefined) {
        // If the parent of the Items container is the potential ancestor, we found it
        if (p.parent == potentialAncestor) return true;
        
        // Go up to the next TreeviewItem
        if (p.parent != undefined && p.parent[$ "parent"] != undefined) {
            p = p.parent.parent;
        } else {
            break;
        }
    }
    
    return false;
}

/// Check if an asset is part of a Scene hierarchy
/// @param {Struct} asset The asset to check
/// @returns {Bool}
function editorTreeviewUtil_isAssetInScene(asset) {
    if (asset == undefined) return false;
    
    // Explicit check for isInstance flag if it exists (for extra safety)
    if (asset[$ "isInstance"] == true) return true;
    
    // Start from parent to check if it's contained within a scene hierarchy
    var curr = asset[$ "parent"];
    while (curr != undefined) {
        if (curr[$ "type"] == "Scene") return true;
        if (curr[$ "type"] == "Folder") return false; // Assets in folders are masters
        
        // Safety break for cycles (shouldn't happen but good practice)
        if (curr[$ "parent"] == curr) break;
        
        curr = curr[$ "parent"];
    }
    return false;
}

/// Get the Scene asset that contains this asset
/// @param {Struct} asset The asset to find the parent scene of
/// @returns {Struct|Undefined} The parent Scene, or undefined if not in a scene
function editorTreeviewUtil_getSceneOfAsset(asset) {
    if (asset == undefined) return undefined;
    
    var curr = asset;
    while (curr != undefined) {
        if (curr[$ "type"] == "Scene") return curr;
        
        // Safety break for cycles
        if (curr[$ "parent"] == curr) break;
        
        curr = curr[$ "parent"];
    }
    return undefined;
}

// =============================================================================
// PARENT MANAGEMENT
// =============================================================================

/// Remove an asset from its parent (Folder or Object3D)
/// @param {Struct} asset The asset to remove from its parent
function editorTreeviewUtil_removeFromParent(asset) {
    if (asset == undefined) return;
    if (asset[$ "parent"] == undefined) return;
    
    var parent = asset.parent;
    
    if (parent[$ "type"] == "Folder") {
        if (parent[$ "children"] != undefined) {
            for (var i = array_length(parent.children) - 1; i >= 0; i--) {
                if (parent.children[i] == asset) {
                    array_delete(parent.children, i, 1);
                    break;
                }
            }
        }
    } else if (parent[$ "remove"] != undefined) {
        parent.remove(asset);
        // Track change on Object3D parent
        global.editor.assetManager.editAsset(parent);
    }
    
    asset.parent = undefined;
}

// =============================================================================
// PREFAB INSTANCE LIFECYCLE
// =============================================================================

/// Register an instance (and its children) in the respective prefab.instances[] lists
/// @param {Struct} obj The instance root to register
function editorTreeviewUtil_registerInstance(obj) {
    if (obj == undefined) return;
    if (obj[$ "prefab"] != undefined && obj.prefab != undefined) {
        // Avoid duplicates
        var _found = false;
        for (var i = 0; i < array_length(obj.prefab.instances); i++) {
            if (obj.prefab.instances[i] == obj) { _found = true; break; }
        }
        if (!_found) array_push(obj.prefab.instances, obj);
    }
    // Recurse children
    if (obj[$ "children"] != undefined) {
        for (var i = 0; i < array_length(obj.children); i++) {
            editorTreeviewUtil_registerInstance(obj.children[i]);
        }
    }
}

/// Unregister an instance (and its children) from the respective prefab.instances[] lists
/// @param {Struct} obj The instance root to unregister
function editorTreeviewUtil_unregisterInstance(obj) {
    if (obj == undefined) return;
    if (obj[$ "prefab"] != undefined && obj.prefab != undefined) {
        var _instances = obj.prefab.instances;
        for (var i = array_length(_instances) - 1; i >= 0; i--) {
            if (_instances[i] == obj) {
                array_delete(_instances, i, 1);
                break;
            }
        }
    }
    // Recurse children
    if (obj[$ "children"] != undefined) {
        for (var i = 0; i < array_length(obj.children); i++) {
            editorTreeviewUtil_unregisterInstance(obj.children[i]);
        }
    }
}

/// Detach all instances from a prefab (when the prefab is destroyed)
/// @param {Struct} prefabObj The prefab being destroyed
function editorTreeviewUtil_detachPrefabInstances(prefabObj) {
    if (prefabObj == undefined) return;
    // Detach direct instances
    var _instances = prefabObj[$ "instances"];
    if (_instances != undefined) {
        for (var i = 0; i < array_length(_instances); i++) {
            var inst = _instances[i];
            if (inst != undefined) {
                inst.prefab = undefined;
            }
        }
        prefabObj.instances = [];
    }
    // Recurse children (for sub-node prefab links)
    if (prefabObj[$ "children"] != undefined) {
        for (var i = 0; i < array_length(prefabObj.children); i++) {
            editorTreeviewUtil_detachPrefabInstances(prefabObj.children[i]);
        }
    }
}

// =============================================================================
// INSTANCE CREATION
// =============================================================================

/// Recursively set instance metadata on a cloned asset and its children
/// Sets new UUIDs, __rotationEuler, __matrixAutoUpdate, prefab link
/// @param {Struct} obj The cloned object to configure
/// @param {String} assetType The asset type string
/// @param {Struct} originalObj The original asset (for copying metadata)
/// @param {Struct} parentObj The parent object (for __parentUI tracking)
function editorTreeviewUtil_setInstanceTypeRecursive(obj, assetType, originalObj = undefined, parentObj = undefined) {
    obj.name += "_" + string(global.UI_ASSETS_INSTANCE_ID++)
    obj.uuid = ueUuid(); // Ensure new UUID for the clone
    
    // Set metadata for the original asset
    if (originalObj != undefined) {
        obj.prefab = originalObj;
        // Register in prefab's instances list (avoid duplicates)
        var _found = false;
        for (var i = 0; i < array_length(originalObj.instances); i++) {
            if (originalObj.instances[i] == obj) { _found = true; break; }
        }
        if (!_found) array_push(originalObj.instances, obj);
    }

    // Set __parentUI for editor hierarchy tracking
    if (parentObj != undefined) {
        obj.__parentUI = parentObj;
    }

    // Always create __rotationEuler for instances (clone may not copy it)
    if (obj[$ "__rotationEuler"] != undefined) {
        // If it exists, free the old one first to avoid memory leaks
        delete obj.__rotationEuler;
    }
    obj.__rotationEuler = euler_create();
    euler_copy(obj.__rotationEuler, originalObj.__rotationEuler);

    // Ensure __matrixAutoUpdate exists and is copied from original if available
    if (originalObj != undefined && originalObj[$ "__matrixAutoUpdate"] != undefined) {
        obj.__matrixAutoUpdate = originalObj.__matrixAutoUpdate;
    } else if (obj[$ "__matrixAutoUpdate"] == undefined) {
        obj.__matrixAutoUpdate = true;
    }
    obj.matrixAutoUpdate = false; // Editor objects don't auto-update for performance

    // Recurse on children
    if (obj.children != undefined) {
        for (var i = 0; i < array_length(obj.children); i++) {
            var originalChild = undefined;
            if (originalObj != undefined && originalObj[$ "children"] != undefined && i < array_length(originalObj.children)) {
                originalChild = originalObj.children[i];
            }
            editorTreeviewUtil_setInstanceTypeRecursive(obj.children[i], assetType, originalChild, obj);
        }
    }
}

// =============================================================================
// TREEVIEW ITEM CREATION
// =============================================================================

/// Create a UiTreeviewItem for an asset and add it to a parent (item or treeview)
/// @param {Struct} asset The asset to create a treeview item for
/// @param {Struct} parent The parent (UiTreeviewItem or UiTreeview)
/// @param {Asset.GMSprite} icon The icon sprite
/// @param {Bool} expand Whether to expand the parent after adding
/// @returns {Struct} The created UiTreeviewItem
function editorTreeviewUtil_createTreeviewItem(asset, parent, icon, expand = false) {
    var treeview = parent[$ "treeview"] ?? parent;
    
    var treeviewItem = new UiTreeviewItem({
        name: "UiTreeview.Item",
    }, {
        treeview: treeview,
        assetType: asset.type,
        type: asset.type,
        icon: icon,
        asset: asset
    });

    if (struct_exists(parent, "addChild")) {
        parent.addChild(treeviewItem, expand);
    } else if (struct_exists(parent, "Items")) {
        parent.Items.add(treeviewItem);
    }
    
    return treeviewItem;
}

/// Recursively create UiTreeviewItems for all children of an asset
/// @param {Struct} asset The parent asset whose children need treeview items
/// @param {Struct} parent The parent treeview item or treeview
/// @param {Asset.GMSprite} icon The icon sprite for the children
function editorTreeviewUtil_createTreeviewItemsForChildren(asset, parent, icon) {
    if (asset[$ "children"] == undefined) return;
    
    for (var i = 0; i < array_length(asset.children); i++) {
        var child = asset.children[i];
        var childTreeviewItem = editorTreeviewUtil_createTreeviewItem(child, parent, icon);
        editorTreeviewUtil_createTreeviewItemsForChildren(child, childTreeviewItem, icon);
    }
}

/// Get the appropriate icon for an asset type
/// @param {String} type The asset type
/// @returns {Asset.GMSprite}
function editorTreeviewUtil_getIconForType(type) {
    switch (type) {
        case "Texture": return sprUiTexture;
        case "Material": return sprUiMaterial;
        case "Mesh": return sprUiMesh;
        case "Bone": return sprUiBone;
        case "Scene": return sprUiScene;
        case "Folder": return sprUiFolder;
        default: return sprUiObject;
    }
}

/// Recursively create treeview items for imported model children
/// @param {Struct} parentAsset The parent asset node
/// @param {Struct} parentTreeviewItem The parent treeview item
function editorTreeviewUtil_addModelChildrenRecursive(parentAsset, parentTreeviewItem) {
    for (var i = 0, il = array_length(parentAsset.children); i < il; i++) {
        var child = parentAsset.children[i];
        
        // Determine icon based on type
        var _sprite = undefined;
        switch (child.type) {
            case "Mesh": _sprite = sprUiMesh; break;
            case "Bone": _sprite = sprUiBone; break;
            default: _sprite = sprUiObject;
        }

        var childTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
        }, {
            treeview: parentTreeviewItem.treeview,
            assetType: child.type,
            type: child.type,
            icon: _sprite,
            asset: child
        });
        parentTreeviewItem.addChild(childTreeviewItem);
        
        // Recurse
        editorTreeviewUtil_addModelChildrenRecursive(child, childTreeviewItem);
    }
}

// =============================================================================
// REMOVAL HELPERS
// =============================================================================

/// Recursively remove children of a treeview item (and their associated assets)
/// @param {Struct} treeviewItem The treeview item whose children should be removed
function editorTreeviewUtil_removeChildrenRecursive(treeviewItem) {
    if (treeviewItem.Items != undefined && treeviewItem.Items.children != undefined) {
        var children = treeviewItem.Items.children;
        for (var i = 0; i < array_length(children); i++) {
            var childItem = children[i];
            // Recurse: clean the child's asset
            editorTreeviewOnRemoveAsset(childItem, false);
        }
    }
}

/// Find and remove a treeview item by its associated asset (recursive search)
/// @param {Struct} container The container to search (typically Items node)
/// @param {Struct} asset The asset to find and remove
/// @returns {Bool} True if found and removed
function editorTreeviewUtil_findAndRemoveTreeviewItem(container, asset) {
    if (container == undefined || container.children == undefined) return false;
    
    for (var i = array_length(container.children) - 1; i >= 0; i--) {
        var child = container.children[i];
        
        // If this is a TreeviewItem with the matching asset, remove it
        if (child[$ "asset"] != undefined && child.asset == asset) {
            child.destroy();
            return true;
        }
        
        // Otherwise search recursively in its children
        if (child[$ "Items"] != undefined) {
            if (editorTreeviewUtil_findAndRemoveTreeviewItem(child.Items, asset)) {
                return true;
            }
        }
    }
    
    return false;
}

/// Remove a texture from all materials that reference it
/// @param {Struct} targetTexture The texture to remove references to
function editorTreeviewUtil_removeTextureFromMaterials(targetTexture) {
    var materials = global.editor.assetManager.getAssetsByType("Material");
    
    for (var i = 0; i < array_length(materials); i++) {
        var material = materials[i];
        
        // Check if the material has textures
        if (material[$ "textures"] != undefined) {
            var texNames = variable_struct_get_names(material.textures);
            
            for (var t = 0; t < array_length(texNames); t++) {
                var texName = texNames[t];
                if (material.textures[$ texName] == targetTexture) {
                    material.textures[$ texName] = undefined;
                    
                    // Rebuild material to apply the changes
                    if (material[$ "build"] != undefined) {
                        material.build();
                    }
                }
            }
        }
    }
}

/// Remove a material from all objects/meshes that reference it
/// @param {Struct} targetMaterial The material to remove references to
function editorTreeviewUtil_removeMaterialFromObjects(targetMaterial) {
    // Remove from models
    var models = global.editor.assetManager.getAssetsByType("Mesh");
    for (var i = 0; i < array_length(models); i++) {
        editorTreeviewUtil_unsetMaterialRecursive(models[i], targetMaterial);
    }
    
    // Remove from scenes and their children
    var scenes = global.editor.assetManager.getAssetsByType("Scene");
    for (var i = 0; i < array_length(scenes); i++) {
        editorTreeviewUtil_unsetMaterialRecursive(scenes[i], targetMaterial);
    }
}

/// Recursively unset a material from an object and its children
/// @param {Struct} obj The object to check
/// @param {Struct} targetMaterial The material to remove
function editorTreeviewUtil_unsetMaterialRecursive(obj, targetMaterial) {
    // Remove the material if it matches
    if (obj[$ "material"] == targetMaterial) {
        obj.material = undefined;
    }
    
    // Recurse on children
    if (obj[$ "children"] != undefined) {
        for (var j = 0; j < array_length(obj.children); j++) {
            editorTreeviewUtil_unsetMaterialRecursive(obj.children[j], targetMaterial);
        }
    }
}

// =============================================================================
// BACKWARD COMPATIBILITY ALIASES
// These redirect old function names to the new ones.
// Can be removed once all external code is updated.
// =============================================================================

function __editorTreeview_isDescendantOf(item, potentialAncestor) {
    return editorTreeviewUtil_isDescendantOf(item, potentialAncestor);
}

function __editorTreeview_isAssetInScene(asset) {
    return editorTreeviewUtil_isAssetInScene(asset);
}

function __editorTreeview_getSceneOfAsset(asset) {
    return editorTreeviewUtil_getSceneOfAsset(asset);
}

function __removeFromParent(asset) {
    editorTreeviewUtil_removeFromParent(asset);
}

function __editorTreeview_setInstanceTypeRecursive(obj, assetType, originalObj = undefined, parentObj = undefined) {
    editorTreeviewUtil_setInstanceTypeRecursive(obj, assetType, originalObj, parentObj);
}

function __editorTreeview_createTreeviewItem(asset, parentTreeviewItem, icon, expand = false) {
    return editorTreeviewUtil_createTreeviewItem(asset, parentTreeviewItem, icon, expand);
}

function __editorTreeview_createTreeviewItemsForChildren(asset, treeviewItem, icon) {
    editorTreeviewUtil_createTreeviewItemsForChildren(asset, treeviewItem, icon);
}

function __editorTreeview_addModelChildrenRecursive(parentAsset, parentTreeviewItem) {
    editorTreeviewUtil_addModelChildrenRecursive(parentAsset, parentTreeviewItem);
}

function __editorTreeview_removeChildrenRecursive(treeviewItem) {
    editorTreeviewUtil_removeChildrenRecursive(treeviewItem);
}

function __editorTreeview_findAndRemoveTreeviewItem(container, asset) {
    return editorTreeviewUtil_findAndRemoveTreeviewItem(container, asset);
}

function __editorTreeview_removeTextureFromMaterials(targetTexture) {
    editorTreeviewUtil_removeTextureFromMaterials(targetTexture);
}

function __editorTreeview_removeMaterialFromObjects(targetMaterial) {
    editorTreeviewUtil_removeMaterialFromObjects(targetMaterial);
}

function __editorTreeview_unsetMaterialRecursive(obj, targetMaterial) {
    editorTreeviewUtil_unsetMaterialRecursive(obj, targetMaterial);
}
