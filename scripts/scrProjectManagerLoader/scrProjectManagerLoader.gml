function ProjectLoader() constructor {
  /**
   * Load project from project.json
   * @param {Struct} projectManager - The project manager instance
   */
  function load(projectManager) {
    var projectDir = projectManager.projectDatafiles + "/Unique Project/";
    var projectJsonPath = projectDir + "project.json";

    if (!file_exists(projectJsonPath)) return;

    var projectData = __readJson(projectJsonPath);
    var treeview = global.UI.Main.Assets.Treeview;
    __recurseNodes(projectDir, treeview, projectData.assets, undefined, undefined);
    __linkNodes();
    projectManager.markAsSaved();
    show_debug_message("Project loaded successfully!");
  }

  // Helper: map type -> icon
  function __iconForType(type) {
    switch (type) {
      case "Folder": return sprUiFolder;
      case "Texture": return sprUiTexture;
      case "Material": return sprUiMaterial;
      case "Mesh": return sprUiObject;
      case "Scene": return sprUiScene;
      case "Light": return sprUiLight;
      case "Camera": return sprUiCamera;
    }
    return undefined;
  }

  // Helper: create asset instance from JSON or a plain Folder struct
  function __createAssetFromNode(projectDir,node) {
    if (node.type == "Folder") {
      var folder = {
        type: "Folder",
        name: node.name,
        uuid: node.uuid,
        children: []
      };
      return folder;
    }

    var asset = undefined;
    switch (node.type) {
      case "Texture": asset = new UeTexture(); break;
      case "Material": asset = new UeMaterial(); break;
      case "Mesh": asset = new UeMesh(); break;
      case "Scene": asset = new UeScene(); break;
      case "Light": asset = new UeLight(); break;
      case "Camera": asset = new UeObject3D(); asset[$ "isCamera"] = true; asset[$ "type"] = "Camera"; break;
    }

    if (asset != undefined) {
      // Import the asset metadata
      // var metadataPath = projectDir + "assets/" + node.uuid + "/metadata.json";
      // if (file_exists(metadataPath) && is_callable(asset[$ "fromJSON"])) {
      //   var meta = __readJson(metadataPath);
      //   asset[$ "fromJSON"](meta);
      // }

      // Attempt to import binary resources (geometry/texture) if import() exists
      if (is_callable(asset[$ "import"])) {
        var assetPath = projectDir + "assets/" + node.uuid;
        if (directory_exists(assetPath)) {
          if (node.type == "Texture" && file_exists(assetPath + "/texture.png")) {
            asset[$ "import"](assetPath + "/texture.png");
          }
          if (node.type == "Mesh" && file_exists(assetPath + "/geometry.buf")) {
            asset[$ "import"](assetPath + "/geometry.buf");
          }
        }
      }
    }

    return asset;
  }

  // Recursive: rebuild treeview and asset manager
  function __recurseNodes(projectDir, treeview, nodes, parentTreeviewItem, parentAsset) {
    for (var i = 0; i < array_length(nodes); i++) {
      var node = nodes[i];

      // Create asset or folder
      var asset = __createAssetFromNode(projectDir, node);

      // Create UiTreeviewItem
      var icon = __iconForType(node.type);
      var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item", paddingVertical: 2.5 }, {
        treeview,
        assetType: node.type,
        type: node.type,
        icon,
        asset
      });

      // Attach to UI
      if (parentTreeviewItem != undefined) {
        parentTreeviewItem.addChild(tvItem);
      } else {
        treeview.Items.add(tvItem);
      }

      // Add to AssetManager
      if (asset != undefined) {
        oSceneEditor.assetManager.addAsset(node.type, asset, parentAsset);
      }

      // Recurse children
      if (node[$ "children"] != undefined && array_length(node.children) > 0) {
        var childParentAsset = asset != undefined ? asset : parentAsset;
        __recurseNodes(projectDir, treeview, node.children, tvItem, childParentAsset);
      }
    }
  }

  function __readJson(filePath) {
      var buf = buffer_load(filePath);
      var jsonString = buffer_read(buf, buffer_text);
      buffer_delete(buf);
      return json_parse(jsonString);
  }
}

