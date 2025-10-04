// Asset drag & drop handler
function editorTreeviewOnAssetDrop(draggedTreeviewItem, targetTreeviewItem) {
    var draggedItem = draggedTreeviewItem; // The TreeviewItem we are dragging
    var targetItem = targetTreeviewItem; // The TreeviewItem we are dropping onto
    
    // Check if the drop is valid
    var isValidDrop = false;
    var dropAction = "";
    
    // Validation rules
    // 1. Texture and Material are not draggable
    if (draggedItem.assetType == "texture" || draggedItem.assetType == "material") {
        return false;
    }
    
    // 2. Drop on a root entity item to unparent
    // Check if the item is under a parent in the UI (not just in the asset)
    if ((draggedItem.assetType == "model" || draggedItem.assetType == "scene") &&
    targetItem.entity && targetItem.assetType == draggedItem.assetType && draggedItem.asset != undefined) {
        isValidDrop = true;
        dropAction = "unparent";
    }
    
    // 3. Scene can only be moved under another Scene
    else if (draggedItem.assetType == "scene") {
        if (targetItem.assetType == "scene" && !targetItem.entity) {
            isValidDrop = true;
            dropAction = "reparent";
        } else {
            return false;
        }
    }
    
    // 4. Model can be moved under another Model (reparent) or under a Scene (instance)
    else if (draggedItem.assetType == "model") {
        // Determine whether the dragged item is an instance (from a scene) or a master (from the Models list)
        var draggedIsInstance = (draggedItem.asset != undefined && draggedItem.asset.isInstance == true);
        var targetHasAsset = (targetItem.asset != undefined);
        var targetIsInstance = targetHasAsset && (targetItem.asset.isInstance == true);

        if (draggedIsInstance) {
            // If we're dragging an existing instance, do reparenting
            if (targetIsInstance && !targetItem.entity) {
                isValidDrop = true;
                dropAction = "reparent";
            } else if (targetItem.assetType == "model" && !targetItem.entity && !targetIsInstance) {
                // Dragging an instance onto a master model -> reparent under that master
                isValidDrop = true;
                dropAction = "reparent";
            } else if (targetItem.assetType == "scene" && !targetItem.entity) {
                // Move instance directly under the scene
                isValidDrop = true;
                dropAction = "reparent";
            } else {
                return false;
            }
        } else {
            // Dragging from the Models list (master)
            if (targetItem.assetType == "model" && !targetItem.entity && (!targetHasAsset || !targetIsInstance)) {
                // Dropping on a master model -> reparent the master under another master
                isValidDrop = true;
                dropAction = "reparent";
            } else if ((targetItem.assetType == "scene" || targetIsInstance) && !targetItem.entity) {
                // Dropping a master onto a scene or onto an instance -> create a new instance
                isValidDrop = true;
                dropAction = "instance";
            } else {
                return false;
            }
        }
    }
    
    // 5. Other types of assets
    else {
        // For now, other asset types follow the same rules as models
        if (targetItem.assetType == draggedItem.assetType && !targetItem.entity) {
            isValidDrop = true;
            dropAction = "reparent";
        } else {
            return false;
        }
    }
    
    // Ensure we are not trying to move an item onto itself
    if (draggedItem == targetItem) {
        return false;
    }
    
    // Ensure we are not trying to reparent a parent into one of its children
    // (this would create a cycle in the hierarchy)
    if (dropAction == "reparent" && draggedItem.asset != undefined && targetItem.asset != undefined) {
        // Check if the targetItem is a descendant of the draggedItem
        var currentParent = targetItem.asset.parent;
        while (currentParent != undefined) {
            if (currentParent == draggedItem.asset) {
                return false;
            }
            currentParent = currentParent.parent;
        }
        
        // Also check in the UI hierarchy of the treeview
        var currentTreeviewParent = targetItem.parent;
        while (currentTreeviewParent != undefined) {
            if (currentTreeviewParent == draggedItem) {
                return false;
            }
            currentTreeviewParent = currentTreeviewParent.parent;
        }
    }
    
    // Perform the drop action
    if (isValidDrop) {
        if (dropAction == "unparent") {
            // Remove from current asset parent
            if (draggedItem.asset.parent != undefined) {
                draggedItem.asset.parent.remove(draggedItem.asset);
                draggedItem.asset.parent = undefined;
            }
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "reparent") {
            // Reparenting: move the asset within the hierarchy

            // Remove from the previous asset parent
            if (draggedItem.asset.parent != undefined) {
                draggedItem.asset.parent.remove(draggedItem.asset);
            }
            
            // Add to the new parent
            targetItem.asset.add(draggedItem.asset);
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "instance") {
            // Instantiate a new instance of the model in the scene
            var instanceAsset = draggedItem.asset.createInstance();
            
            // Set type and __rotationEuler for all children recursively using a class-level function
            __editorTreeview_setInstanceTypeRecursive(instanceAsset, draggedItem.assetType);

            // Add the instance to the target element (scene or sub-object)
            targetItem.asset.add(instanceAsset);

            // Create TreeviewItems for the instance and its children
            var instanceTreeviewItem = __editorTreeview_createTreeviewItem(instanceAsset, targetItem, draggedItem.icon);
            __editorTreeview_createTreeviewItemsForChildren(instanceAsset, instanceTreeviewItem, draggedItem.icon);

            // Only on the main parent call __onItemSelected
            targetItem.treeview.__onItemSelected(instanceTreeviewItem);
        }
        
        return true;
    }
    
    return false;
};

// On drop -> create instance -> imposta ricorsivamente, name, type e __rotationEuler su tutte le istanze
function __editorTreeview_setInstanceTypeRecursive(obj, assetType) {
    obj.name += "_" + string(global.UI_ASSETS_INSTANCE_ID++)

    switch (assetType) {
        case "model": obj.type = "ModelInstance"; break;
        case "light": obj.type = "LightInstance"; break;
        case "camera": obj.type = "CameraInstance"; break;
        default: obj.type = assetType + "Instance"; break;
    }
    // Assicura che __rotationEuler sia presente
    obj.__rotationEuler = new UeEuler();

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
        marginLeft: 15,
        paddingVertical: 2.5
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
