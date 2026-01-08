//* Create a new asset when clicking the + icon button on the Treeview */
function editorTreeviewOnNewAsset(treeviewItem, assetTypeOverride = undefined) {
  // In free mode, assetType might not be set, so we use the override or prompt
  var assetType = assetTypeOverride ?? (treeviewItem != undefined ? treeviewItem.assetType : undefined);
  
  // Handle folder creation
  if (assetType == "Folder") {
      var treeview = global.UI.Main.Assets.Treeview;
      var folderId = global.UI_ASSETS_FOLDERS_ID++;
      
      // Create folder asset object
      var folder = new EditorFolder({
          name: "Folder" + string(folderId),
      });
      
      var folderItem = new UiTreeviewItem({ 
          name: "UiTreeview.Item", 
      }, {
          treeview,
          name: folder.name,
          assetType: "Folder",
          type: "Folder",
          icon: sprUiFolder,
          asset: folder
      });
      
      // Add to root or parent
      if (treeviewItem != undefined) {
          treeviewItem.addChild(folderItem);
          
          // If parent is a folder, set parent reference
          if (treeviewItem.assetType == "Folder") {
              treeviewItem.asset.add(folder);
          }
      } else {
          treeview.Items.add(folderItem);
      }
      
      oSceneEditor.assetManager.addAsset("Folder", folder);
      treeview.__onItemSelected(folderItem, true);
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
          asset = new UeMeshStandardMaterial();
          assetId = global.UI_ASSETS_MATERIALS_ID++;
      break;
      
      case "Mesh": 
          var size = 50;
          var geometry = new UeBoxGeometry(size, size, size, { canFreeze: false });
          
          // Set bounding box
          geometry.boundingBox = box3_create();
          box3_set_from_center_and_size(geometry.boundingBox, [0, 0, 0], [size, size, size]);
          
          // Set bounding sphere
          geometry.boundingSphere = sphere_create(vec3_create(), size * 0.866); // sqrt(3)/2 ≈ 0.866
          
          asset = new UeStaticMesh(geometry);
          asset.castShadow = true;
          asset.receiveShadow = true;
          asset.geometry.__vbClone = geometry.cloneVb();
          geometry.freeze();
          asset.__rotationEuler = euler_create();
          asset.__matrixAutoUpdate = false; // Internal field for export (false = static mesh)
          assetId = global.UI_ASSETS_MODELS_ID++;
      break;
      
      case "Light":
          asset = new UeLight(); 
          asset.__rotationEuler = euler_create();
          assetId = global.UI_ASSETS_LIGHTS_ID++;
      break;
      
      case "Camera":
          asset = new UeObject3D();
          asset.isCamera = true;
          asset.type = "Camera";
          asset.__rotationEuler = euler_create();
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
  
  // Determine the parent asset (only for 3D hierarchy, not folders)
  var parentAsset = undefined;
  if (treeviewItem != undefined && treeviewItem.asset != undefined) {
      // Only set parent if it's NOT a folder (folders are UI organization only)
      if (treeviewItem.asset[$ "type"] != "Folder") {
          parentAsset = treeviewItem.asset;
      }
      
      treeviewItem.addChild(newTreeviewItem);
  } else {
      // Add to root
      treeview.Items.add(newTreeviewItem);
  }
  
  // Add asset to asset manager AFTER treeview parent is set (so __treeviewItem.parent is available)
  var typeKey = assetType;
  assetManager.addAsset(typeKey, asset, parentAsset);
  
  // Select the new item
  treeview.__onItemSelected(newTreeviewItem, true);
};
