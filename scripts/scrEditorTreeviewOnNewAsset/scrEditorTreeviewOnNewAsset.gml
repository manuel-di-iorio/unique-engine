//* Create a new asset when clicking the + icon button on the Treeview */
function editorTreeviewOnNewAsset(treeviewItem, assetTypeOverride = undefined) {
  // In free mode, assetType might not be set, so we use the override or prompt
  var assetType = assetTypeOverride ?? (treeviewItem != undefined ? treeviewItem.assetType : undefined);
  
  if (assetType == undefined) {
      show_debug_message("ERROR: Cannot create asset without type");
      return;
  }
  
  // Handle folder creation
  if (assetType == "Folder") {
      var treeview = global.UI.Main.Assets.Treeview;
      var folderId = global.UI_ASSETS_FOLDERS_ID++;
      
      var folderItem = new UiTreeviewItem({ 
          name: "UiTreeview.Item", 
          paddingVertical: 2.5 
      }, {
          treeview,
          name: "Folder" + string(folderId),
          assetType: "Folder",
          type: "Folder",
          icon: sprUiFolder
      });
      
      // Add to root or parent
      if (treeviewItem != undefined) {
          treeviewItem.addChild(folderItem);
      } else {
          treeview.Items.add(folderItem);
      }
      
      treeview.__onItemSelected(folderItem);
      return;
  }
  
  var asset;
  var assetId;
  var assetManager = oSceneEditor.assetManager;

  switch (assetType) {
      case "Texture": 
          asset = new UeTexture();
          assetId = global.UI_ASSETS_TEXTURES_ID++;
      break;

      case "Material":
          asset = new UeMaterial();
          assetId = global.UI_ASSETS_MATERIALS_ID++;
      break;
      
      case "Mesh": 
          asset = new UeMesh(new UeBoxGeometry(50, 50, 50));
          asset.material = undefined;
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_MODELS_ID++;
      break;
      
      case "Light":
          asset = new UeLight(); 
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_LIGHTS_ID++;
      break;
      
      case "Camera":
          asset = new UeObject3D();
          asset.isCamera = true;
          asset.type = "Camera";
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_CAMERAS_ID++;
      break;
      
      case "Scene":
          asset = new UeScene();
          assetId = global.UI_ASSETS_SCENES_ID++;
      break;
  }
  
  // Create treeview item
  var treeview = treeviewItem != undefined ? treeviewItem.treeview : global.UI.Main.Assets.Treeview;
  var icon = undefined;
  
  switch (assetType) {
      case "Texture": icon = sprUiTexture; break;
      case "Material": icon = sprUiMaterial; break;
      case "Mesh": icon = sprUiObject; break;
      case "Scene": icon = sprUiScene; break;
  }
  
  var newTreeviewItem = new UiTreeviewItem({ 
      name: "UiTreeview.Item", 
      paddingVertical: 2.5 
  }, {
      treeview: treeview,
      assetType: assetType,
      type: assetType,
      icon: icon,
      asset: asset
  });
  
  asset.name = string_upper(string_char_at(assetType, 1)) + string_copy(assetType, 2, string_length(assetType) - 1) + string(assetId);
  
  // Determine the parent asset
  var parentAsset = undefined;
  if (treeviewItem != undefined && treeviewItem.asset != undefined) {
      parentAsset = treeviewItem.asset;
      parentAsset.add(asset);
      treeviewItem.addChild(newTreeviewItem);
  } else {
      // Add to root
      treeview.Items.add(newTreeviewItem);
  }
  
  // Add asset to asset manager
  var typeKey = string_lower(assetType);
  if (typeKey == "mesh") typeKey = "model";
  assetManager.addAsset(typeKey, asset, parentAsset);
  
  // Select the new item
  treeview.__onItemSelected(newTreeviewItem);
};
