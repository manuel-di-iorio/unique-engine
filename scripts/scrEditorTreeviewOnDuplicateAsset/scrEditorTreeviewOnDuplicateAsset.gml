function editorTreeviewOnDuplicateAsset(treeviewItem) {
    if (treeviewItem == undefined || treeviewItem.asset == undefined) return;
    
    var originalAsset = treeviewItem.asset;
    var assetManager = oSceneEditor.assetManager;
    var treeview = treeviewItem.treeview;
    
    // 1. Clone the asset
    var clonedAsset = undefined;
    
    // Check if the asset has a clone method
    if (variable_struct_exists(originalAsset, "isInstance") && originalAsset.isInstance) {
        // For model instances, we must create a new instance from the master object
        // This ensures the materials and geometry are linked correctly
        if (variable_struct_exists(originalAsset, "object") && originalAsset.object != undefined) {
             // Create a new instance from the master object
             if (variable_struct_exists(originalAsset.object, "createInstance")) {
                clonedAsset = originalAsset.object.createInstance();
                
                // Copy properties from the original instance (transform etc)
                clonedAsset.visible = originalAsset.visible;
                clonedAsset.name = originalAsset.name; 
                clonedAsset.position.copy(originalAsset.position);
                clonedAsset.rotation.copy(originalAsset.rotation);
                clonedAsset.scale.copy(originalAsset.scale);
                if (variable_struct_exists(originalAsset, "__rotationEuler")) {
                    if (clonedAsset[$ "__rotationEuler"] == undefined) clonedAsset.__rotationEuler = euler_create();
                    euler_copy(clonedAsset.__rotationEuler, originalAsset.__rotationEuler);
                }
                
                // If the instance had an overriden material, carry it over
                if (originalAsset.material != originalAsset.object.material) {
                     clonedAsset.material = originalAsset.material; 
                }
             }
        }
    } 
    
    if (clonedAsset == undefined) {
        if (variable_struct_exists(originalAsset, "clone")) {
            clonedAsset = originalAsset.clone(true); // Recursive clone
        } else {
            clonedAsset = variable_clone(originalAsset);
        }
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
    _recursionScope.updateIdentifiers = method(_recursionScope, function(asset) {
        if (!is_struct(asset)) return;

        asset.uuid = ueUuid();
        if (variable_struct_exists(asset, "id")) {
             // Assuming global.UE_OBJECT_ID exists and is used for this
             if (variable_global_exists("UE_OBJECT_ID")) {
                asset.id = global.UE_OBJECT_ID++;
             }
        }
        
        // __rotationEuler
        if (variable_struct_exists(asset, "rotation") && asset[$ "__rotationEuler"] == undefined) {
             asset.__rotationEuler = euler_create();
             if (is_array(asset.rotation)) {
                euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
             }
        }
        
        // __matrixAutoUpdate
        if (variable_struct_exists(asset, "matrixAutoUpdate") && asset[$ "__matrixAutoUpdate"] == undefined) {
             asset.__matrixAutoUpdate = asset.matrixAutoUpdate;
        }
        
        // Clear UI references
        asset.__treeviewItem = undefined;
        asset.__parentUI = undefined;
        
        if (variable_struct_exists(asset, "children") && is_array(asset.children)) {
            for (var i = 0; i < array_length(asset.children); i++) {
                self.updateIdentifiers(asset.children[i]);
                if (is_struct(asset.children[i])) {
                    asset.children[i].parent = asset; // Ensure parent linkage is correct
                }
            }
        }
    });
    
    _recursionScope.updateIdentifiers(clonedAsset);
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
    treeview.__onItemSelected(newRootItem, true);
}

function __editorTreeviewOnDuplicateAsset__createUiRecursive(treeview, asset, parentUiItem) {
    var icon = undefined;
    var type = asset[$ "type"] ?? "Object3D"; 
    
    // Map type to icon (simple heuristic)
    if (type == "Folder") icon = sprUiFolder;
    else if (type == "Mesh" || type == "Object3D" || type == "ModelInstance") icon = sprUiObject;
    else if (type == "Material") icon = sprUiMaterial;
    else if (type == "Texture") icon = sprUiTexture;
    else if (type == "Scene") icon = sprUiScene;
    else if (type == "Light") icon = sprUiLight;
    else if (type == "Camera") icon = sprUiCamera;
    
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
