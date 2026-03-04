// Asset drag & drop handler
function editorTreeviewOnAssetDrop(draggedTreeviewItem, targetTreeviewItem) {
    var draggedItem = draggedTreeviewItem; // The TreeviewItem we are dragging
    var targetItem = targetTreeviewItem; // The TreeviewItem we are dropping onto
    
    // Prevent dropping onto itself or onto one of its own children/descendants
    if (draggedItem == targetItem) return false;
    if (editorTreeviewUtil_isDescendantOf(targetItem, draggedItem)) return false;
    
    // Check if the drop is valid
    var isValidDrop = false;
    var dropAction = "";
    var targetAssetOverride = undefined;
    
    // Validation rules

    // Check if target is Root (UiTreeview context)
    // The main Treeview (root) doesn't have an assetType property.
    // It's a UiTreeview instance.
    var isTargetRoot = (!struct_exists(targetItem, "assetType") && struct_exists(targetItem, "Items"));

    if (isTargetRoot) {
        // We are dropping onto the root background
        var sceneTreeview = global.UI.Main.Assets.Treeview;
        var resourcesTreeview = global.UI.Main.Resources.Treeview;
        
        var draggedInScene = editorTreeviewUtil_isAssetInScene(draggedItem.asset);
        
        if (targetItem == sceneTreeview) {
            if (draggedInScene) {
                var activeScene = global.editor.editorManager.activeScene;
                if (activeScene != undefined && editorTreeviewUtil_getSceneOfAsset(draggedItem.asset) == activeScene) {
                    isValidDrop = true;
                    dropAction = "reparent";
                    targetAssetOverride = activeScene;
                }
            } else {
                // Instance project asset into active scene
                if (draggedItem.assetType == "Mesh" || draggedItem.assetType == "Object3D") {
                    isValidDrop = true;
                    dropAction = "instance";
                    targetAssetOverride = activeScene;
                }
            }
        } else if (targetItem == resourcesTreeview) {
            // Drop onto Resources panel root
            if (!draggedInScene) {
                isValidDrop = true;
                dropAction = "moveToRoot";
            }
        }
    }
    // Allow dropping anything into a Folder
    else if (targetItem.assetType == "Folder") {
        var draggedInScene = editorTreeviewUtil_isAssetInScene(draggedItem.asset);
        if (!draggedInScene) {
            isValidDrop = true;
            dropAction = "moveToFolder";
        }
    }
    // Material dropped onto Mesh
    else if (draggedItem.assetType == "Material" && targetItem.assetType == "Mesh") {
        isValidDrop = true;
        dropAction = "applyMaterial";
    }
    
    // Texture can be dragged on Materials
    else if (draggedItem.assetType == "Texture") {
        if (targetItem != undefined && targetItem.assetType == "Material") {
            var material = targetItem.asset;
            var texture = draggedItem.asset;
            material.setTexture("map", texture);
            material.build();
            
            // Refresh inspector if this material is the one currently edited
            if (global.editor.editorManager.activeAsset == material) {
                global.editor.assetManager.editAsset(material);
            }
            return true;
        }
        return false;
    }
    
    // Material is not draggable onto other things
    else if (draggedItem.assetType == "Material") {
        return false;
    }
    
    // Scene cannot be moved under another Scene or Object (no nesting)
    // Also prevent dropping anything onto a Scene asset directly
    else if (draggedItem.assetType == "Scene" || targetItem.assetType == "Scene") {
        return false;
    }
    
    // Model can be moved under another Model (reparent) or under a Scene (instance)
    else if (draggedItem.assetType == "Mesh" || draggedItem.assetType == "Object3D" || draggedItem.assetType == "Bone") {
        var targetIsScene = (targetItem.assetType == "Scene");
        var targetIsModel = (targetItem.assetType == "Mesh" || targetItem.assetType == "Object3D" || targetItem.assetType == "Bone");

        if (targetIsScene || targetIsModel) {
             // Is the target part of the scene graph?
             var targetInScene = targetIsScene || editorTreeviewUtil_isAssetInScene(targetItem.asset);
             
             if (targetInScene) {
                 // If target is in scene, we check if we should instance or reparent
                 var draggedInScene = editorTreeviewUtil_isAssetInScene(draggedItem.asset);
                 
                 if (draggedInScene) {
                     // Ensure it's the SAME scene
                     var draggedScene = editorTreeviewUtil_getSceneOfAsset(draggedItem.asset);
                     var targetScene = targetIsScene ? targetItem.asset : editorTreeviewUtil_getSceneOfAsset(targetItem.asset);
                     
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
                 var draggedInScene = editorTreeviewUtil_isAssetInScene(draggedItem.asset);
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
             editorTreeviewUtil_removeFromParent(draggedItem.asset);
             
             // Clear __parentUI since we're removing from hierarchy/folder
             if (struct_exists(draggedItem.asset, "__parentUI")) {
                draggedItem.asset.__parentUI = undefined; 
             }
             
             // Track change on dragged asset
             global.editor.assetManager.editAsset(draggedItem.asset);
             
             // Update the treeview UI
             draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "moveToFolder") {
            targetItem.asset.add(draggedItem.asset);
            global.editor.assetManager.editAsset(draggedItem.asset);
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "unparent") {
            // Remove from current asset parent
                editorTreeviewUtil_removeFromParent(draggedItem.asset);
                
                // Clear __parentUI since we're removing from folder
                draggedItem.asset.__parentUI.removeFromParent();
                
                // Track change on the dragged asset (metadata 'folder' removed if it was in one)
                global.editor.assetManager.editAsset(draggedItem.asset);
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "reparent") {
            // Reparenting: move the asset within the hierarchy

            // Remove from the previous asset parent
            editorTreeviewUtil_removeFromParent(draggedItem.asset);
            
            // Add to the new parent
            var targetAsset = (targetAssetOverride != undefined) ? targetAssetOverride : targetItem.asset;
            if (targetAsset != undefined) {
                targetAsset.add(draggedItem.asset);
                
                // Update __parentUI for saving hierarchy
                draggedItem.asset.__parentUI = targetAsset;
                
                // Track change on new parent
                global.editor.assetManager.editAsset(targetAsset);
            }
            
            // Track change on dragged asset too (parent changed)
            global.editor.assetManager.editAsset(draggedItem.asset);
            
            // Update the treeview UI using the new helper
            draggedItem.moveItemTo(targetItem);
        }
        else if (dropAction == "instance") {
            // Instantiate a new instance of the model in the scene
            var instanceAsset = draggedItem.asset.clone();
            instanceAsset.castShadow = true;
            instanceAsset.receiveShadow = true;
            
            var targetAsset = (targetAssetOverride != undefined) ? targetAssetOverride : targetItem.asset;
            if (targetAsset != undefined) {
                // Set type and __rotationEuler for all children recursively BEFORE adding to scene
                editorTreeviewUtil_setInstanceTypeRecursive(instanceAsset, draggedItem.assetType, draggedItem.asset, targetAsset);
                
                // Add the instance to the target element (scene or sub-object)
                targetAsset.add(instanceAsset);
                
                // Track change
                global.editor.assetManager.editAsset(targetAsset);
            }

            // If target is a scene and it's not loaded yet, don't create treeview items manually
            // expanding it will trigger the loader which builds the treeview
            var needsLoading = struct_exists(targetItem, "needsLoading") ? targetItem.needsLoading : false;
            if (struct_exists(targetItem, "assetType") && targetItem.assetType == "Scene" && needsLoading) {
                targetItem.expandItem();
            } else {
                // Target is already loaded or is a regular object, create items manually
                targetItem.expandItem();

                // Create TreeviewItems for the instance and its children
                var instanceTreeviewItem = editorTreeviewUtil_createTreeviewItem(instanceAsset, targetItem, draggedItem.icon);
                editorTreeviewUtil_createTreeviewItemsForChildren(instanceAsset, instanceTreeviewItem, draggedItem.icon);

                // Focus the newly created instance in the viewport
                global.editor.sceneManager.orbit.focus(instanceAsset);

                // Only on the main parent call __onItemSelected
                var tv = struct_exists(targetItem, "treeview") ? targetItem.treeview : targetItem;
                if (tv != undefined && struct_exists(tv, "__onItemSelected")) {
                    tv.__onItemSelected(instanceTreeviewItem);
                }
            }
        }
        else if (dropAction == "applyMaterial") {
            // Apply material to mesh
            targetItem.asset.material = draggedItem.asset;
            global.editor.assetManager.editAsset(targetItem.asset);
        }
        
        return true;
    }
    
    return false;
}
