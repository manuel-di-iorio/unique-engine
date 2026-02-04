// Asset drag & drop handler
function editorTreeviewOnAssetDrop(draggedTreeviewItem, targetTreeviewItem) {
    var draggedItem = draggedTreeviewItem; // The TreeviewItem we are dragging
    var targetItem = targetTreeviewItem; // The TreeviewItem we are dropping onto
    
    // Prevent dropping onto itself or onto one of its own children/descendants
    if (draggedItem == targetItem) return false;
    if (__editorTreeview_isDescendantOf(targetItem, draggedItem)) return false;
    
    // Check if the drop is valid
    var isValidDrop = false;
    var dropAction = "";
    
    // Validation rules

    // Check if target is Root (UiTreeview context)
    // The main Treeview (root) doesn't have an assetType property.
    // It's a UiTreeview instance.
    var isTargetRoot = (targetItem[$ "assetType"] == undefined && targetItem[$ "Items"] != undefined);

    if (isTargetRoot) {
        // We are dropping onto the root background
        
        // Instances cannot be at root (must be in a Scene or under a Mesh)
        var draggedInScene = __editorTreeview_isAssetInScene(draggedItem.asset);
        
        if (!draggedInScene) {
            isValidDrop = true;
            dropAction = "moveToRoot";
        }
    }
    // Allow dropping anything into a Folder
    else if (targetItem.assetType == "Folder") {
        var draggedInScene = __editorTreeview_isAssetInScene(draggedItem.asset);
        if (!draggedInScene) {
            isValidDrop = true;
            dropAction = "moveToFolder";
        }
    }
    // Texture and Material are not draggable
    else if (draggedItem.assetType == "Texture" || draggedItem.assetType == "Material") {
        return false;
    }
    
    // Scene can only be moved under another Scene
    // Scene cannot be moved under another Scene
    else if (draggedItem.assetType == "Scene") {
        return false;
    }
    
    // Model can be moved under another Model (reparent) or under a Scene (instance)
    else if (draggedItem.assetType == "Mesh" || draggedItem.assetType == "Object3D" || draggedItem.assetType == "Bone") {
        var targetIsScene = (targetItem.assetType == "Scene");
        var targetIsModel = (targetItem.assetType == "Mesh" || targetItem.assetType == "Object3D" || targetItem.assetType == "Bone");

        if (targetIsScene || targetIsModel) {
             // Is the target part of the scene graph?
             var targetInScene = targetIsScene || __editorTreeview_isAssetInScene(targetItem.asset);
             
             if (targetInScene) {
                 // If target is in scene, we check if we should instance or reparent
                 var draggedInScene = __editorTreeview_isAssetInScene(draggedItem.asset);
                 
                 if (draggedInScene) {
                     // Ensure it's the SAME scene
                     var draggedScene = __editorTreeview_getSceneOfAsset(draggedItem.asset);
                     var targetScene = targetIsScene ? targetItem.asset : __editorTreeview_getSceneOfAsset(targetItem.asset);
                     
                     if (draggedScene != undefined && draggedScene == targetScene) {
                        isValidDrop = true;
                        dropAction = "reparent";
                     }
                 } else {
                     // Project asset dropped onto scene -> Instance
                     isValidDrop = true;
                     dropAction = "instance";
                 }
             } else {
                 // Target is NOT in scene (must be a folder/project asset)
                 // Just reparent/move if dragged item is also not in a scene
                 var draggedInScene = __editorTreeview_isAssetInScene(draggedItem.asset);
                 if (!draggedInScene) {
                    isValidDrop = true;
                    dropAction = "reparent";
                 }
             }
        } else {
            return false;
        }
    }
    
    // Perform the drop action
    if (isValidDrop) {
        if (dropAction == "moveToRoot") {
             // Remove from current asset parent (if any)
             __removeFromParent(draggedItem.asset);
             
             // Clear __parentUI since we're removing from hierarchy/folder
             if (draggedItem.asset[$ "__parentUI"] != undefined) {
                draggedItem.asset.__parentUI = undefined; 
             }
             
             // Track change on dragged asset
             oSceneEditor.assetManager.editAsset(draggedItem.asset);
             
             // Update the treeview UI
             draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "moveToFolder") {
            targetItem.asset.add(draggedItem.asset);
            oSceneEditor.assetManager.editAsset(draggedItem.asset);
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "unparent") {
            // Remove from current asset parent
                __removeFromParent(draggedItem.asset);
                
                // Clear __parentUI since we're removing from folder
                draggedItem.asset.__parentUI.removeFromParent();
                
                // Track change on the dragged asset (metadata 'folder' removed if it was in one)
                oSceneEditor.assetManager.editAsset(draggedItem.asset);
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "reparent") {
            // Reparenting: move the asset within the hierarchy

            // Remove from the previous asset parent
            __removeFromParent(draggedItem.asset);
            
            // Add to the new parent (only if target asset exists)
            if (targetItem.asset != undefined) {
                targetItem.asset.add(draggedItem.asset);
                
                // Update __parentUI for saving hierarchy
                draggedItem.asset.__parentUI = targetItem.asset;
                
                // Track change on new parent
                oSceneEditor.assetManager.editAsset(targetItem.asset);
            }
            
            // Track change on dragged asset too (parent changed)
            oSceneEditor.assetManager.editAsset(draggedItem.asset);
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "instance") {
            // Instantiate a new instance of the model in the scene
            var instanceAsset = draggedItem.asset.clone();
            instanceAsset.castShadow = true;
            instanceAsset.receiveShadow = true;
            
            // Set type and __rotationEuler for all children recursively BEFORE adding to scene
            // This ensures __rotationEuler exists before any inspector tries to access it
            __editorTreeview_setInstanceTypeRecursive(instanceAsset, draggedItem.assetType, draggedItem.asset, targetItem.asset);
            
            // Add the instance to the target element (scene or sub-object)
            targetItem.asset.add(instanceAsset);
            
            // Track change
            oSceneEditor.assetManager.editAsset(targetItem.asset);

            // If target is a scene and it's not loaded yet, don't create treeview items manually
            // expanding it will trigger the loader which builds the treeview
            if (targetItem.assetType == "Scene" && targetItem[$ "needsLoading"] == true) {
                targetItem.expandItem();
            } else {
                // Target is already loaded or is a regular object, create items manually
                targetItem.expandItem();

                // Create TreeviewItems for the instance and its children
                var instanceTreeviewItem = __editorTreeview_createTreeviewItem(instanceAsset, targetItem, draggedItem.icon);
                __editorTreeview_createTreeviewItemsForChildren(instanceAsset, instanceTreeviewItem, draggedItem.icon);

                // Only on the main parent call __onItemSelected
                targetItem.treeview.__onItemSelected(instanceTreeviewItem);
            }
        }
        
        return true;
    }
    
    return false;
}

/**
 * Get the Scene asset that contains this asset
 */
function __editorTreeview_getSceneOfAsset(asset) {
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

// On drop -> create instance -> imposta ricorsivamente, name, type e __rotationEuler su tutte le istanze
function __editorTreeview_setInstanceTypeRecursive(obj, assetType, originalObj = undefined, parentObj = undefined) {
    obj.name += "_" + string(global.UI_ASSETS_INSTANCE_ID++)
    obj.uuid = ueUuid(); // Ensure new UUID for the clone
    
    // Set metadata for the original asset
    if (originalObj != undefined) {
        obj.__instanceOf = originalObj;
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
    
    // Copy original rotationEuler if it exists, otherwise calculate from quaternion
    if (originalObj != undefined && originalObj[$ "__rotationEuler"] != undefined) {
        euler_copy(obj.__rotationEuler, originalObj.__rotationEuler);
    } else {
        euler_set_from_quaternion(obj.__rotationEuler, obj.rotation);
    }

    // Ensure __matrixAutoUpdate exists and is copied from original if available
    if (originalObj != undefined && originalObj[$ "__matrixAutoUpdate"] != undefined) {
        obj.__matrixAutoUpdate = originalObj.__matrixAutoUpdate;
    } else if (obj[$ "__matrixAutoUpdate"] == undefined) {
        obj.__matrixAutoUpdate = true;
    }
    obj.matrixAutoUpdate = false; // Editor objects don't auto-update for performance

    // Ricorsione su children
    if (obj.children != undefined) {
        for (var i = 0; i < array_length(obj.children); i++) {
            var originalChild = undefined;
            if (originalObj != undefined && originalObj[$ "children"] != undefined && i < array_length(originalObj.children)) {
                originalChild = originalObj.children[i];
            }
            __editorTreeview_setInstanceTypeRecursive(obj.children[i], assetType, originalChild, obj);
        }
    }
}

// Private function to recursively create TreeviewItems
function __editorTreeview_createTreeviewItem(asset, parentTreeviewItem, icon, expand = false) {
    var treeviewItem = new UiTreeviewItem({
        name: "UiTreeview.Item",
    }, {
        treeview: parentTreeviewItem.treeview,
        assetType: asset.type,
        type: asset.type,
        icon: icon,
        asset: asset
    });
    parentTreeviewItem.addChild(treeviewItem, expand);
    return treeviewItem;
}

// Private recursive function to add children as TreeviewItems
function __editorTreeview_createTreeviewItemsForChildren(asset, treeviewItem, icon) {
    for (var i = 0; i < array_length(asset.children); i++) {
        var child = asset.children[i];
        var childTreeviewItem = __editorTreeview_createTreeviewItem(child, treeviewItem, icon);
        __editorTreeview_createTreeviewItemsForChildren(child, childTreeviewItem, icon);
    }
}

/**
 * Helper to remove an asset from its parent (Folder or Object3D)
 */
function __removeFromParent(asset) {
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
        oSceneEditor.assetManager.editAsset(parent);
    }
    
    asset.parent = undefined;
}

/**
 * Check if a treeview item is a descendant of another treeview item
 */
function __editorTreeview_isDescendantOf(item, potentialAncestor) {
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

/**
 * Check if an asset is part of a Scene hierarchy
 */
function __editorTreeview_isAssetInScene(asset) {
    if (asset == undefined) return false;
    
    // Explicit check for isInstance flag if it exists (for extra safety)
    if (asset[$ "isInstance"] == true) return true;
    
    var curr = asset;
    while (curr != undefined) {
        if (curr[$ "type"] == "Scene") return true;
        if (curr[$ "type"] == "Folder") return false; // Assets in folders are masters
        
        // Safety break for cycles (shouldn't happen but good practice)
        if (curr[$ "parent"] == curr) break;
        
        curr = curr[$ "parent"];
    }
    return false;
}
