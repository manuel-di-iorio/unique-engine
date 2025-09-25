function EditorUiAssets(ui) constructor {
    // Recursive: unset material from obj, children, instances
    self.__unsetMaterialRecursive = function(obj, targetMaterial) {
        if (obj[$ "material"] == targetMaterial) {
            obj.material = undefined;
        }
        if (obj.children != undefined) {
            for (var j = 0; j < array_length(obj.children); j++) {
                self.__unsetMaterialRecursive(obj.children[j], targetMaterial);
            }
        }
        if (obj.instances != undefined && obj.instances.list != undefined) {
            for (var k = 0; k < array_length(obj.instances.list); k++) {
                self.__unsetMaterialRecursive(obj.instances.list[k], targetMaterial);
            }
        }
    }

    // Recursive: unset texture from obj, children, instances
    self.__unsetTextureRecursive = function(obj, targetTexture) {
        // Remove the texture from the direct property
        if (obj[$ "texture"] == targetTexture) {
            obj.texture = undefined;
        }

        // If the child has a material, remove the texture from the textures struct
        if (obj[$ "material"] != undefined && obj.material.textures != undefined) {
            var texNames = variable_struct_get_names(obj.material.textures);
            for (var t = 0; t < array_length(texNames); t++) {
                var texName = texNames[t];
                if (obj.material.textures[$ texName] == targetTexture) {
                    obj.material.textures[$ texName] = undefined;
                }
            }
        }

        // Recursion on children
        if (obj.children != undefined) {
            for (var j = 0; j < array_length(obj.children); j++) {
                self.__unsetTextureRecursive(obj.children[j], targetTexture);
            }
        }

        // Recursion on instances
        if (obj.instances != undefined && obj.instances.list != undefined) {
            for (var k = 0; k < array_length(obj.instances.list); k++) {
                self.__unsetTextureRecursive(obj.instances.list[k], targetTexture);
            }
        }
    }
    
    // Private function to recursively create TreeviewItems
    self.__createTreeviewItem = function(asset, parentTreeviewItem, icon) {
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
    self.__createTreeviewItemsForChildren = function(asset, treeviewItem, icon) {
        for (var i = 0; i < array_length(asset.children); i++) {
            var child = asset.children[i];
            var childTreeviewItem = self.__createTreeviewItem(child, treeviewItem, icon);
            self.__createTreeviewItemsForChildren(child, childTreeviewItem, icon);
        }
    }

    // Private recursive function to search and remove the instance
    self.__removeTreeviewItemByAsset = function(treeviewItem, targetAsset) {
        if (treeviewItem[$ "asset"] != undefined && treeviewItem.asset == targetAsset) {
            var parent = treeviewItem.parent;
            treeviewItem.destroy();
            if (parent != undefined && parent.parent != undefined) {
                parent.parent.__updateArrowVisibility();
            }
            return true;
        }

        if (treeviewItem[$ "Items"] != undefined) {
            var children = treeviewItem.Items.children;
            for (var i = array_length(children) - 1; i >= 0; i--) {
                if (self.__removeTreeviewItemByAsset(children[i], targetAsset)) {
                    return true;
                }
            }
        }

        return false;
    }
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", marginBottom: 62 }, { border: true });
    ui.Assets.Treeview = new UiTreeview({ marginTop: 35, flex: 1, height: "90%", flexDirection: "column" });
    
    ui.Assets.add(ui.Assets.Treeview);
        
    ui.Assets.onDraw = method(ui.Assets, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
        draw_text(self.x1 + 20, self.y1 + 8, "Assets");
    });
        
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.enableScrollbar();
        
    // Create new asset
    Treeview.onNewAsset = function(treeviewItem) {
        var assetType = treeviewItem.assetType;
        var asset;
        var assetId;
        switch (assetType) {
            case "texture": 
                asset = new UeTexture();
                assetId = global.UI_ASSETS_TEXTURES_ID++;
                array_push(oSceneEditor.projectTextures, asset);
            break;
            
            case "material": 
                asset = new UeMaterial(); 
                assetId = global.UI_ASSETS_MATERIALS_ID++;
                array_push(oSceneEditor.projectMaterials, asset);
            break;
            
            case "model": 
                asset = new UeMesh(new UeBoxGeometry(50, 50, 50));
                asset.material = undefined;
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_MODELS_ID++;
                array_push(oSceneEditor.projectModels, asset);
            break;
            
            case "light":
                asset = new UeLight(); 
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_LIGHTS_ID++;
                array_push(oSceneEditor.projectLights, asset);
            break;
            
            case "camera":
                asset = new UeObject3D();
                asset.isCamera = true;
                asset.type = "camera";
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_CAMERAS_ID++;
                array_push(oSceneEditor.projectCameras, asset);
            break;
            
            case "scene":   
                asset = new UeScene();
                assetId = global.UI_ASSETS_SCENES_ID++;
                array_push(oSceneEditor.projectScenes, asset);
            break;
        }
        
        treeviewItem.asset = asset; 
        asset.name = string_upper(string_char_at(assetType, 1)) + string_copy(assetType, 2, string_length(assetType) - 1) + string(assetId);
        
        // If the item was created under a parent (not a root entity), establish asset hierarchy
        if (treeviewItem.parent != undefined && treeviewItem.parent.parent != undefined && !treeviewItem.parent.parent.entity) {
            var parentTreeviewItem = treeviewItem.parent.parent;
            if (parentTreeviewItem.asset != undefined) {
                parentTreeviewItem.asset.add(asset);
            }
        }
        
        // If it's a scene, select it automatically
        if (assetType == "scene") {
            ui.Assets.Treeview.__onItemSelected(treeviewItem);
        }
    };
        
    Treeview.onRemoveItem = function(treeviewItem, isSelected) {
        if (isSelected) {
            oSceneEditor.inspector.close();
        }
        
        var assetType = treeviewItem.assetType;
        var asset = treeviewItem.asset;

        // If the asset being removed is currently active, unset it
        if (asset != undefined && oSceneEditor.activeAsset == asset) {
            oSceneEditor.unsetActiveAsset();
        }

        // If the asset is an instance, remove it from the scene
        if (asset != undefined && asset[$ "isInstance"] == true) {
            // Remove the instance from the scene (from its parent)
            if (asset.parent != undefined) {
                asset.parent.remove(asset);
            }
            
            // Remove the instance from the original model's instances list
            if (asset[$ "object"] != undefined && asset.object[$ "instances"] != undefined) {
                asset.object.instances.remove(asset);
            }
        } else {
            // If the asset is a master asset (not an instance), remove it from the project list
            var list;
            switch (assetType) {
                case "texture": list = oSceneEditor.projectTextures; break;
                case "material": list = oSceneEditor.projectMaterials; break;
                case "model": list = oSceneEditor.projectModels; break;
                case "light": list = oSceneEditor.projectLights; break;
                case "camera": list = oSceneEditor.projectCameras; break;
                case "scene": list = oSceneEditor.projectScenes; break;
            }
            
            var _itemIdx = array_find_index(list, method({ asset }, function(value) {
                return value == asset;
            }))
            if (_itemIdx != -1) array_delete(list, _itemIdx, 1);
            
            // If the asset has instances, remove them all from scenes
            if (asset != undefined && asset[$ "instances"] != undefined) {
                // Make a copy of the instances list because we'll remove items during iteration
                var instancesList = asset.instances.list;
                var instancesToRemove = [];
                for (var i = 0, l = array_length(instancesList); i < l; i++) {
                    array_push(instancesToRemove, instancesList[i]);
                }
                
                // Remove each instance
                for (var i = 0, l = array_length(instancesToRemove); i < l; i++) {
                    var instance = instancesToRemove[i];

                    if (oSceneEditor.activeAsset == instance) {
                        oSceneEditor.unsetActiveAsset();
                        oSceneEditor.inspector.close();
                    }

                    // Remove the instance from its parent
                    if (instance.parent != undefined) {
                        instance.parent.remove(instance);
                    }

                    // Find and remove the instance from the treeview
                    self.__removeTreeviewItemByAsset(ui.Assets.Treeview, instance);
                }

                // Clear the instances list
                asset.instances.clear();
            }

            // If we are deleting a material, remove it from all models
            if (assetType == "material") {
                var models = oSceneEditor.projectModels;
                for (var i = 0, l = array_length(models); i < l; i++) {
                    self.__unsetMaterialRecursive(models[i], asset);
                }
                var scenes = oSceneEditor.projectScenes;
                for (var i = 0, l = array_length(scenes); i < l; i++) {
                    if (scenes[i].children != undefined) {
                        for (var j = 0; j < array_length(scenes[i].children); j++) {
                            self.__unsetMaterialRecursive(scenes[i].children[j], asset);
                        }
                    }
                }
            }

            // If we are deleting a texture, remove it from all models and all scenes
            if (assetType == "texture") {
                var models = oSceneEditor.projectModels;
                for (var i = 0, l = array_length(models); i < l; i++) {
                    self.__unsetTextureRecursive(models[i], asset);
                }
                var scenes = oSceneEditor.projectScenes;
                for (var i = 0, l = array_length(scenes); i < l; i++) {
                    if (scenes[i].children != undefined) {
                        for (var j = 0; j < array_length(scenes[i].children); j++) {
                            self.__unsetTextureRecursive(scenes[i].children[j], asset);
                        }
                    }
                }
            }
        }
    }
            
    // On item selected
    Treeview.onItemSelected = function(treeviewItem) {
        switch (treeviewItem.asset.type) {
            case "ModelInstance":                
                var scene = treeviewItem.asset;
                while (scene == undefined || scene.type != "Scene") {
                    scene = scene.parent;
                }
                oSceneEditor.setActiveAsset(scene);
            break;

            case "Mesh":
            case "Scene":
                oSceneEditor.setActiveAsset(treeviewItem.asset);
            break;
        }

        oSceneEditor.inspector.inspect(treeviewItem.asset);
    };
    
    // Asset drag & drop handler
    Treeview.onAssetDrop = function(draggedTreeviewItem, targetTreeviewItem) {
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
                
                instanceAsset.name += "_" + string(global.UI_ASSETS_INSTANCE_ID++);

                switch (draggedItem.assetType) {
                    case "model": instanceAsset.type = "ModelInstance"; break;
                    case "light": instanceAsset.type = "LightInstance"; break;
                    case "camera": instanceAsset.type = "CameraInstance"; break;
                }
                instanceAsset.__rotationEuler = new UeEuler();

                // Add the instance to the target element (scene or sub-object)
                targetItem.asset.add(instanceAsset);

                // Create TreeviewItems for the instance and its children
                var instanceTreeviewItem = self.__createTreeviewItem(instanceAsset, targetItem, draggedItem.icon);
                self.__createTreeviewItemsForChildren(instanceAsset, instanceTreeviewItem, draggedItem.icon);

                // Only on the main parent call __onItemSelected
                targetItem.treeview.__onItemSelected(instanceTreeviewItem);
            }
            
            return true;
        }
        
        return false;
    };
}
