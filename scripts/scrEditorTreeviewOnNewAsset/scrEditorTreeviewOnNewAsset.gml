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
      
      global.editor.assetManager.addAsset("Folder", folder);
      treeview.__onItemSelected(folderItem, true);
      return;
  }
  
  var asset;
  var assetId;
  var assetManager = global.editor.assetManager;

  switch (assetType) {
      case "Texture": 
          asset = new UeTexture();
          assetId = global.UI_ASSETS_TEXTURES_ID++;
      break;

      case "Material":
          asset = new UeMeshStandardMaterial();
          assetId = global.UI_ASSETS_MATERIALS_ID++;
      break;

      case "Scene":
          asset = new UeScene();
          assetId = global.UI_ASSETS_SCENES_ID++;
      break;

      case "Object3D":
          asset = new UeObject3D();
          asset.__rotationEuler = euler_create();
          asset.matrixAutoUpdate = false;
          asset.__matrixAutoUpdate = true;
          assetId = global.UI_ASSETS_OBJECT3D_ID++;
      break;
  }
  
  // Create treeview item
  var treeview = treeviewItem != undefined ? treeviewItem.treeview : global.UI.Main.Assets.Treeview;
  var icon = undefined;
  
  switch (assetType) {
      case "Texture": icon = sprUiTexture; break;
      case "Material": icon = sprUiMaterial; break;
      case "Scene": icon = sprUiScene; break;
      case "Object3D": icon = sprUiObject; break;
    //   case "PointLight": icon = sprUiPointLight; break;
    //   case "DirectionalLight": icon = sprUiDirectionalLight; break;
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
  if (_assetTypeName == "Object3D") _assetTypeName = "Object";
  asset.name = _assetTypeName + string(assetId);
  
  // Determine the parent asset (only for 3D hierarchy, not folders)
  var parentAsset = undefined;
  var parentTreeviewItem = treeviewItem;

  // Special case for lights: they must be children of a scene
  /*if (assetType == "PointLight" || assetType == "DirectionalLight" || assetType == "Light") {
      var foundSceneItem = undefined;
      var currentItem = treeviewItem;
      
      // Look for the selected scene or the scene containing the selection
      while (currentItem != undefined) {
          if (currentItem.asset != undefined && currentItem.asset.type == "Scene") {
              foundSceneItem = currentItem;
              break;
          }
          // Move up in the treeview hierarchy
          // UiTreeviewItem -> parent (UiTreeview.Items) -> parent (UiTreeviewItem or UiTreeview)
          if (currentItem[$ "parent"] != undefined && currentItem.parent[$ "parent"] != undefined) {
              currentItem = currentItem.parent.parent;
              // Check if we reached the root treeview (which doesn't have a parent.parent)
              if (currentItem == treeview) {
                  currentItem = undefined;
              }
          } else {
              currentItem = undefined;
          }
      }
      
      if (foundSceneItem != undefined) {
          parentAsset = foundSceneItem.asset;
          parentTreeviewItem = foundSceneItem;
      } else {
          // If no scene is selected, try to find the first scene in the project
          var allAssets = assetManager.assets;
          for (var i = 0; i < array_length(allAssets); i++) {
              if (allAssets[i].type == "Scene") {
                  parentAsset = allAssets[i];
                  parentTreeviewItem = parentAsset.__treeviewItem;
                  break;
              }
          }
      }
  } else */if (treeviewItem != undefined && treeviewItem.asset != undefined) {
      // Only set parent if it's NOT a folder (folders are UI organization only)
      if (treeviewItem.asset[$ "type"] != "Folder") {
          parentAsset = treeviewItem.asset;
      }
  }

  // Add to treeview
  if (parentTreeviewItem != undefined) {
      parentTreeviewItem.addChild(newTreeviewItem);
  } else {
      // Add to root
      treeview.Items.add(newTreeviewItem);
  }
  
  // Add asset to asset manager AFTER treeview parent is set (so __treeviewItem.parent is available)
  var typeKey = assetType;
  assetManager.addAsset(typeKey, asset, parentAsset);
  
  // Mark project as modified for standalone Object3D/Texture/Material/Scene (not tracked via parent)
  if (assetType != "Folder") {
      global.editor.projectManager.markAsUnsaved();
  }

  // Set visual representation for lights in editor
//   if (assetType == "PointLight" || assetType == "DirectionalLight") {
//       var icon = (assetType == "DirectionalLight") ? sprUiDirectionalLight3D : sprUiPointLight3D;
//       asset.geometry = new UePlaneGeometry(32, 32);
//       asset.material = new UeSpriteMaterial({
//           map: new UeTexture(icon),
//           color: make_color_rgb(asset.color[0] * 255, asset.color[1] * 255, asset.color[2] * 255),
//       });
//       asset.isSprite = true;
//       asset.geometry.computeBoundingBox();
//       asset.geometry.computeBoundingSphere();
//       asset.primitive = pr_trianglelist;

//       asset.render = UeMesh.render;
//   }
  
  // Select the new item
  treeview.__onItemSelected(newTreeviewItem, true);
};
