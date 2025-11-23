//* Create a new asset when clicking the + icon button on the Treeview */
function editorTreeviewOnNewAsset(treeviewItem, assetTypeOverride = undefined) {
  // In free mode, assetType might not be set, so we use the override or prompt
  var assetType = assetTypeOverride ?? (treeviewItem != undefined ? treeviewItem.assetType : undefined);
  
  // Handle folder creation
  if (assetType == "Folder") {
      var treeview = global.UI.Main.Assets.Treeview;
      var folderId = global.UI_ASSETS_FOLDERS_ID++;
      
      // Create folder asset object
      var folder = {
          type: "Folder",
          name: "Folder" + string(folderId),
          uuid: ueUuid(),
          children: []
      };
      
      var folderItem = new UiTreeviewItem({ 
          name: "UiTreeview.Item", 
          paddingVertical: 2.5 
      }, {
          treeview,
          name: folder.name,
          assetType: "Folder",
          type: "Folder",
          icon: sprUiFolder,
          asset: folder
      });
      
      // Add to root or parent
      var parentAsset = undefined;
      if (treeviewItem != undefined) {
          if (treeviewItem.asset != undefined) {
              parentAsset = treeviewItem.asset;
              if (parentAsset[$ "children"] != undefined) {
                  array_push(parentAsset.children, folder);
              }
          }
          treeviewItem.addChild(folderItem);
      } else {
          treeview.Items.add(folderItem);
      }
      
      // Add to AssetManager
      oSceneEditor.assetManager.addAsset("Folder", folder, parentAsset);
      
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
          var size = 50;
          var geometry = new UeBoxGeometry(size, size, size, { canFreeze: false });
          
          // Set bounding box
          geometry.boundingBox = new UeBox3();
          geometry.boundingBox.setFromCenterAndSize(
              new UeVector3(0, 0, 0),
              new UeVector3(size, size, size)
          );
          
          // Set bounding sphere
          geometry.boundingSphere = new UeSphere(new UeVector3(0, 0, 0), size * 0.866); // sqrt(3)/2 ≈ 0.866
          
          asset = new UeMesh(geometry);
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
  
  _assetTypeName = string_upper(string_char_at(assetType, 1)) + string_copy(assetType, 2, string_length(assetType) - 1);
  if (_assetTypeName == "Mesh") _assetTypeName = "Object";
  asset.name = _assetTypeName + string(assetId);
  
  // Determine the parent asset
  var parentAsset = undefined;
  if (treeviewItem != undefined && treeviewItem.asset != undefined) {
      parentAsset = treeviewItem.asset;
      
      // Check if parent is a Folder (plain struct) or Object3D (has add method)
      if (parentAsset.type == "Folder") {
          // Folders use plain array for children
          array_push(parentAsset.children, asset);
      } else {
          // Objects use the add() method
          parentAsset.add(asset);
      }
      
      treeviewItem.addChild(newTreeviewItem);
  } else {
      // Add to root
      treeview.Items.add(newTreeviewItem);
  }
  
  // Add asset to asset manager
  var typeKey = assetType;
  assetManager.addAsset(typeKey, asset, parentAsset);
  
  // Select the new item
  treeview.__onItemSelected(newTreeviewItem);
};
