function editorTreeviewOnDuplicateAsset(treeviewItem) {
    if (treeviewItem == undefined || treeviewItem.asset == undefined) return;
    
    var originalAsset = treeviewItem.asset;
    var assetManager = oSceneEditor.assetManager;
    var treeview = treeviewItem.treeview;
    
    // 1. Clone the asset
    var clonedAsset = undefined;
    
    if (variable_struct_exists(originalAsset, "clone")) {
        clonedAsset = originalAsset.clone(true); // Recursive clone
    } else {
        clonedAsset = variable_clone(originalAsset);
    }
    
    // Copy editor properties
    if (clonedAsset != undefined) {
         if (variable_struct_exists(originalAsset, "__rotationEuler")) {
            if (clonedAsset[$ "__rotationEuler"] == undefined) clonedAsset.__rotationEuler = euler_create();
            euler_copy(clonedAsset.__rotationEuler, originalAsset.__rotationEuler);
        }
        
        if (variable_struct_exists(originalAsset, "__matrixAutoUpdate")) {
            clonedAsset.__matrixAutoUpdate = originalAsset.__matrixAutoUpdate;
        }
    }
    
    // 2. Recursive update internal identifiers (UUIDs, IDs)
    var _recursionScope = {};
    _recursionScope.updateIdentifiers = method(_recursionScope, function(asset, originalSource = undefined) {
        if (!is_struct(asset)) return;

        asset.uuid = ueUuid();
        
        // Preserve __instanceOf if it exists on original
        if (originalSource != undefined && originalSource[$ "__instanceOf"] != undefined) {
            asset.__instanceOf = originalSource.__instanceOf;
        }
        
        if (variable_struct_exists(asset, "id")) {
             // Assuming global.UE_OBJECT_ID exists and is used for this
             if (variable_global_exists("UE_OBJECT_ID")) {
                asset.id = global.UE_OBJECT_ID++;
             }
        }
        
        // __rotationEuler
        if (variable_struct_exists(asset, "rotation") && asset[$ "__rotationEuler"] == undefined) {
             asset.__rotationEuler = euler_create();
             if (originalSource != undefined && originalSource[$ "__rotationEuler"] != undefined) {
                euler_copy(asset.__rotationEuler, originalSource.__rotationEuler);
             }
        }
        
        // __matrixAutoUpdate
        if (asset[$ "__matrixAutoUpdate"] == undefined) {
             asset.__matrixAutoUpdate = true;
        }
        asset.matrixAutoUpdate = false; // Editor objects don't auto-update for performance

        // Shadows
        if (variable_struct_exists(asset, "castShadow") && asset.castShadow) {
            asset.castShadow = true;
        }
        if (variable_struct_exists(asset, "receiveShadow") && asset.receiveShadow) {
            asset.receiveShadow = true;
        }
        
        // Clear UI references
        asset.__treeviewItem = undefined;
        asset.__parentUI = undefined;
        
        if (variable_struct_exists(asset, "children") && is_array(asset.children)) {
            for (var i = 0; i < array_length(asset.children); i++) {
                var originalChild = (originalSource != undefined && originalSource[$ "children"] != undefined && i < array_length(originalSource.children)) ? originalSource.children[i] : undefined;
                self.updateIdentifiers(asset.children[i], originalChild);
                if (is_struct(asset.children[i])) {
                    asset.children[i].parent = asset; // Ensure parent linkage is correct
                }
            }
        }
    });
    
    _recursionScope.updateIdentifiers(clonedAsset, originalAsset);
    if (is_struct(clonedAsset)) {
        clonedAsset.name = originalAsset.name + " (Copy)";
        clonedAsset.parent = undefined; // Root clone has no parent yet
    }

    // 3. Determine Parent Treeview Item
    var targetParentItem = undefined;
    var parentAsset = undefined;

    // Logic to find valid parent UI Item from the current item's parent container
    if (treeviewItem.parent != undefined && treeviewItem.parent.parent != undefined) {
         var containerParent = treeviewItem.parent.parent;
         
         // If container's parent is a TreeviewItem, that's our target parent
         if (containerParent.type == "UiTreeview.Item" || containerParent[$ "assetType"] != undefined) {
             targetParentItem = containerParent;
             parentAsset = targetParentItem.asset;
         }
         // If containerParent is the Treeview itself, we are at root (targetParentItem stays undefined)
    }
    
    // 4. Create UI Hierarchy recursively
    var newRootItem = __editorTreeviewOnDuplicateAsset__createUiRecursive(treeview, clonedAsset, targetParentItem);

    // 5. Register with AssetManager
    assetManager.addAsset(treeviewItem.assetType, clonedAsset, parentAsset);

    // 6. Select
    treeview.__onItemSelected(newRootItem, false);
}

function __editorTreeviewOnDuplicateAsset__createUiRecursive(treeview, asset, parentUiItem) {
    var icon = undefined;
    var type = asset[$ "type"] ?? "Object3D"; 
    
    // Map type to icon (simple heuristic)
    if (type == "Folder") icon = sprUiFolder;
    else if (type == "Mesh" || type == "Object3D") icon = sprUiObject;
    else if (type == "Material") icon = sprUiMaterial;
    else if (type == "Texture") icon = sprUiTexture;
    else if (type == "Scene") icon = sprUiScene;
    // else if (type == "PointLight") icon = sprUiPointLight;
    // else if (type == "DirectionalLight") icon = sprUiDirectionalLight;
    // else if (type == "Camera") icon = sprUiCamera;
    
    var newItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
      treeview: treeview,
      assetType: type,
      type: type,
      icon: icon,
      asset: asset,
      name: asset.name
    });
    
    if (parentUiItem != undefined) {
      parentUiItem.addChild(newItem);
    } else {
      treeview.Items.add(newItem);
    }
    
    if (variable_struct_exists(asset, "children")) {
      for (var i = 0; i < array_length(asset.children); i++) {
        __editorTreeviewOnDuplicateAsset__createUiRecursive(treeview, asset.children[i], newItem);
      }
    }
    
    return newItem;
}
