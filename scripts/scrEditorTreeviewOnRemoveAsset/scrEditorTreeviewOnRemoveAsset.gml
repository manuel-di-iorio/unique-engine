function editorTreeviewOnRemoveAsset(treeviewItem, isSelected) {
  if (isSelected) {
      oSceneEditor.editorManager.inspector.close();
  }
  
  var assetType = treeviewItem.assetType;
  var asset = treeviewItem.asset;
  var selectedAsset = oSceneEditor.editorManager.activeAsset;

  // If the asset being removed is the currently active asset, detach the associated transform controls
  if (asset != undefined && selectedAsset == asset && (selectedAsset.type == "Mesh" || selectedAsset.type == "ModelInstance")) {
    oSceneEditor.editorManager.transformControls.detach();
  }

  // Check if the currently selected item is a descendant of the item being removed
  var treeview = treeviewItem.treeview;
  if (treeview.selectedItem != undefined && __editorTreeview_isDescendantOf(treeview.selectedItem, treeviewItem)) {
      treeview.selectedItem = undefined;
      oSceneEditor.editorManager.inspector.close();
      if (oSceneEditor.editorManager.activeAsset != undefined) {
          oSceneEditor.editorManager.clearActiveAsset();
      }
  }

  // Also check if the selected item's asset is a descendant of the asset being removed
  if (treeview.selectedItem != undefined && treeview.selectedItem.asset != undefined && asset != undefined) {
      if (__editorTreeview_isAssetDescendantOf(treeview.selectedItem.asset, asset)) {
          treeview.selectedItem = undefined;
          oSceneEditor.editorManager.inspector.close();
          if (oSceneEditor.editorManager.activeAsset != undefined) {
              oSceneEditor.editorManager.clearActiveAsset();
          }
      }
  }

  // If the asset being removed is currently active, unset it and close the inspector
  if (asset != undefined && oSceneEditor.editorManager.activeAsset == asset) {
      oSceneEditor.editorManager.clearActiveAsset();
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
    //   switch (assetType) {
    //       case "Texture": list = oSceneEditor.projectTextures; break;
    //       case "Material": list = oSceneEditor.projectMaterials; break;
    //       case "Mesh": list = oSceneEditor.projectModels; break;
    //       case "Light": list = oSceneEditor.projectLights; break;
    //       case "Camera": list = oSceneEditor.projectCameras; break;
    //       case "Scene": list = oSceneEditor.projectScenes; break;
    //   }
      
    //   var _itemIdx = array_find_index(list, method({ asset }, function(value) {
    //       return value == asset;
    //   }))
    //   if (_itemIdx != -1) array_delete(list, _itemIdx, 1);
      
    //   // If the asset has instances, remove them all from scenes
    //   if (asset != undefined && asset[$ "instances"] != undefined) {
    //       // Make a copy of the instances list because we'll remove items during iteration
    //       var instancesList = asset.instances.list;
    //       var instancesToRemove = [];
    //       for (var i = 0, l = array_length(instancesList); i < l; i++) {
    //           array_push(instancesToRemove, instancesList[i]);
    //       }
          
          // Remove each instance
    //       for (var i = 0, l = array_length(instancesToRemove); i < l; i++) {
    //           var instance = instancesToRemove[i];

    //           if (oSceneEditor.activeAsset == instance) {
    //               oSceneEditor.unsetActiveAsset();
    //               global.EditorState.inspector.close();
    //           }

    //           // Remove the instance from its parent
    //           if (instance.parent != undefined) {
    //               instance.parent.remove(instance);
    //           }

    //           // Find and remove the instance from the treeview
    //           __editorTreeview_removeTreeviewItemByAsset(oSceneEditor.ui.Assets.Treeview, instance);
    //       }

    //       // Clear the instances list
    //       asset.instances.clear();
    //   }

      // If we are deleting a material, remove it from all models
      if (assetType == "material") {
    //       var models = oSceneEditor.projectModels;
    //       for (var i = 0, l = array_length(models); i < l; i++) {
    //           __editorTreeviewRemoveAsset_unsetMaterialRecursive(models[i], asset);
    //       }
    //       var scenes = oSceneEditor.projectScenes;
    //       for (var i = 0, l = array_length(scenes); i < l; i++) {
    //           if (scenes[i].children != undefined) {
    //               for (var j = 0; j < array_length(scenes[i].children); j++) {
    //                   __editorTreeviewRemoveAsset_unsetMaterialRecursive(scenes[i].children[j], asset);
    //               }
    //           }
    //       }
    //   }

      // If we are deleting a texture, remove it from all models and all scenes
    //   if (assetType == "texture") {
    //       var models = oSceneEditor.projectModels;
    //       for (var i = 0, l = array_length(models); i < l; i++) {
    //           __editorTreeview_unsetTextureRecursive(models[i], asset);
    //       }
    //       var scenes = oSceneEditor.projectScenes;
    //       for (var i = 0, l = array_length(scenes); i < l; i++) {
    //           if (scenes[i].children != undefined) {
    //               for (var j = 0; j < array_length(scenes[i].children); j++) {
    //                   __editorTreeview_unsetTextureRecursive(scenes[i].children[j], asset);
    //               }
    //           }
    //       }
      }
  }
}

// Recursive: unset material from obj, children, instances
function __editorTreeviewRemoveAsset_unsetMaterialRecursive(obj, targetMaterial) {
    if (obj[$ "material"] == targetMaterial) {
        obj.material = undefined;
    }
    
    if (obj.children != undefined) {
        for (var j = 0; j < array_length(obj.children); j++) {
            __editorTreeviewRemoveAsset_unsetMaterialRecursive(obj.children[j], targetMaterial);
        }
    }

    if (obj.instances != undefined && obj.instances.list != undefined) {
        for (var k = 0; k < array_length(obj.instances.list); k++) {
            __editorTreeviewRemoveAsset_unsetMaterialRecursive(obj.instances.list[k], targetMaterial);
        }
    }
}

// Recursive: unset texture from obj, children, instances
function __editorTreeview_unsetTextureRecursive(obj, targetTexture) {
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
            __editorTreeview_unsetTextureRecursive(obj.children[j], targetTexture);
        }
    }

    // Recursion on instances
    if (obj.instances != undefined && obj.instances.list != undefined) {
        for (var k = 0; k < array_length(obj.instances.list); k++) {
            __editorTreeview_unsetTextureRecursive(obj.instances.list[k], targetTexture);
        }
    }
}

// Private recursive function to search and remove an instance
function __editorTreeview_removeTreeviewItemByAsset(treeviewItem, targetAsset) {
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
            if (__editorTreeview_removeTreeviewItemByAsset(children[i], targetAsset)) {
                return true;
            }
        }
    }

    return false;
}

// Helper function to check if a treeview item is a descendant of another
function __editorTreeview_isDescendantOf(childItem, potentialAncestor) {
    var currentParent = childItem.parent;
    
    while (currentParent != undefined) {
        if (currentParent == potentialAncestor) {
            return true;
        }
        currentParent = currentParent.parent;
    }
    
    return false;
}

// Helper function to check if an asset is a descendant of another asset in the 3D hierarchy
function __editorTreeview_isAssetDescendantOf(childAsset, potentialAncestorAsset) {
    var currentParent = childAsset.parent;
    
    while (currentParent != undefined) {
        if (currentParent == potentialAncestorAsset) {
            return true;
        }
        currentParent = currentParent.parent;
    }
    
    return false;
}
