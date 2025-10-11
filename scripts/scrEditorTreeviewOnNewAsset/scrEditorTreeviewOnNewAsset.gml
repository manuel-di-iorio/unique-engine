//* Create a new asset when clicking the + icon button on the Treeview */
function editorTreeviewOnNewAsset(treeviewItem) {
  var assetType = treeviewItem.assetType;
  var asset;
  var assetId;

  switch (assetType) {
      case "Texture": 
          asset = new UeTexture();
          assetId = global.UI_ASSETS_TEXTURES_ID++;
          array_push(oSceneEditor.projectTextures, asset);
      break;

      case "Material":
          asset = new UeMaterial();
          assetId = global.UI_ASSETS_MATERIALS_ID++;
          array_push(oSceneEditor.projectMaterials, asset);
      break;
      
      case "Mesh": 
          asset = new UeMesh(new UeBoxGeometry(50, 50, 50));
          asset.material = undefined;
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_MODELS_ID++;
          array_push(oSceneEditor.projectModels, asset);
      break;
      
      case "Light":
          asset = new UeLight(); 
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_LIGHTS_ID++;
          array_push(oSceneEditor.projectLights, asset);
      break;
      
      case "Camera":
          asset = new UeObject3D();
          asset.isCamera = true;
          asset.type = "Camera";
          asset.__rotationEuler = new UeEuler();
          assetId = global.UI_ASSETS_CAMERAS_ID++;
          array_push(oSceneEditor.projectCameras, asset);
      break;
      
      case "Scene":
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
  if (assetType == "Scene") {
      oSceneEditor.ui.Assets.Treeview.__onItemSelected(treeviewItem);
  }
};
