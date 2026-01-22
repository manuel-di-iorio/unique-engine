// Asset drag & drop handler
function editorTreeviewOnAssetDrop(draggedTreeviewItem, targetTreeviewItem) {
    var draggedItem = draggedTreeviewItem; // The TreeviewItem we are dragging
    var targetItem = targetTreeviewItem; // The TreeviewItem we are dropping onto
    
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
        var draggedIsInstance = (draggedItem.asset != undefined && draggedItem.asset[$ "isInstance"] == true);
        
        if (!draggedIsInstance) {
            // Check if already at root
            // If dragging from a folder, parent is defined. If from root, parent is undefined.
            
            isValidDrop = true;
            dropAction = "moveToRoot";
        }
    }
    // Allow dropping anything into a Folder
    else if (targetItem.assetType == "Folder") {
        isValidDrop = true;
        dropAction = "moveToFolder";
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
    else if (draggedItem.assetType == "Mesh" || draggedItem.assetType == "Object3D") {
        var targetHasAsset = (targetItem.asset != undefined);
        var targetIsScene = (targetItem.assetType == "Scene");

        if (targetIsScene) {
            // Dropping a master onto a scene -> create a new instance (clone)
            isValidDrop = true;
            dropAction = "instance";
        } else if (targetItem.assetType == "Mesh" || targetItem.assetType == "Object3D") {
            // Reparenting
            isValidDrop = true;
            dropAction = "reparent";
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
            
            // Set type and __rotationEuler for all children recursively using a class-level function
            __editorTreeview_setInstanceTypeRecursive(instanceAsset, draggedItem.assetType);

            // Add the instance to the target element (scene or sub-object)
            targetItem.asset.add(instanceAsset);
            
            // Track change
            oSceneEditor.assetManager.editAsset(targetItem.asset);

            // Create TreeviewItems for the instance and its children
            var instanceTreeviewItem = __editorTreeview_createTreeviewItem(instanceAsset, targetItem, draggedItem.icon);
            __editorTreeview_createTreeviewItemsForChildren(instanceAsset, instanceTreeviewItem, draggedItem.icon);

            // Only on the main parent call __onItemSelected
            targetItem.treeview.__onItemSelected(instanceTreeviewItem);
        }
        
        return true;
    }
    
    return false;
}

// On drop -> create instance -> imposta ricorsivamente, name, type e __rotationEuler su tutte le istanze
function __editorTreeview_setInstanceTypeRecursive(obj, assetType) {
    obj.name += "_" + string(global.UI_ASSETS_INSTANCE_ID++)
    obj.uuid = ueUuid(); // Ensure new UUID for the clone

    // Copy __rotationEuler from the master object if it exists, otherwise create new
    obj.__rotationEuler = euler_create();
    euler_set_from_quaternion(obj.__rotationEuler, obj.rotation);

    // Ensure __matrixAutoUpdate exists and is synced with matrixAutoUpdate
    if (obj[$ "__matrixAutoUpdate"] == undefined) {
        obj.__matrixAutoUpdate = obj[$ "matrixAutoUpdate"] ?? true;
    }

    // Ricorsione su children
    if (obj.children != undefined) {
        for (var i = 0; i < array_length(obj.children); i++) {
            __editorTreeview_setInstanceTypeRecursive(obj.children[i], assetType);
        }
    }
}

// Private function to recursively create TreeviewItems
function __editorTreeview_createTreeviewItem(asset, parentTreeviewItem, icon) {
    var treeviewItem = new UiTreeviewItem({
        name: "UiTreeview.Item",
    }, {
        treeview: parentTreeviewItem.treeview,
        assetType: asset.type,
        type: asset.type,
        icon: icon,
        asset: asset
    });
    parentTreeviewItem.addChild(treeviewItem);
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
