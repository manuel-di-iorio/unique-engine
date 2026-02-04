function ProjectLoader() constructor {
  self.treeviewItemsByUUID = {};

  /**
   * Load project searching for assets in Assets/ folder
   */
  self.load = function (projectManager) {
    var projectDir = projectManager.projectDatafiles + "/Unique Project/";
    var editorJsonPath = projectDir + "editor.json";
    var projectJsonPath = projectDir + "project.json";
    var assetsDir = projectDir + "Assets/";

    if (!file_exists(editorJsonPath)) return;

    var settings = self.__readJson(editorJsonPath);
    self.__applyProjectSettings(settings);

    var treeview = global.UI.Main.Assets.Treeview;
    self.treeviewItemsByUUID = {};

    // 1. Load Folders from project.json
    var projectData = { folders: {} };
    if (file_exists(projectJsonPath)) {
      projectData = self.__readJson(projectJsonPath);
    }

    var foldersData = projectData[$ "folders"] ?? {};
    var folderTargets = [];

    if (is_struct(foldersData)) {
      var names = struct_get_names(foldersData);
      for (var i = 0; i < array_length(names); i++) {
        var fData = foldersData[$ names[i]];
        array_push(folderTargets, self.__createFolderItem(fData, treeview));
      }
    } else if (is_array(foldersData)) {
      for (var i = 0; i < array_length(foldersData); i++) {
        var fData = foldersData[i];
        array_push(folderTargets, self.__createFolderItem(fData, treeview));
      }
    }

    // 2. Discover all Assets from categorized subfolders
    var assetTargets = [];
    var types = ["Textures", "Materials", "Objects", "Scenes"];
    for (var i = 0; i < array_length(types); i++) {
      var typeDir = assetsDir + types[i] + "/";
      if (!directory_exists(typeDir)) continue;

      // Support for UUID/asset.json format
      var a = file_find_first(typeDir + "*", fa_directory);
      while (a != "") {
        var fullPath = typeDir + a + "/";
        var metaPath = fullPath + "asset.json";
        if (directory_exists(fullPath) && file_exists(metaPath)) {
          var node = self.__readJson(metaPath);
          node[$ "uuid"] = a;
          self.__registerAssetFromNode(node, treeview, assetTargets, projectDir);
        }
        a = file_find_next();
      }
      file_find_close();
    }

    // 3. Parenting Pass (Folders + Assets)
    for (var i = 0; i < array_length(folderTargets); i++) {
      var target = folderTargets[i];
      if (target == undefined) continue;

      var tvItem = target.item;
      var parentUUID = target.parentUUID;
      var folder = tvItem.asset;

      if (parentUUID != undefined && struct_exists(self.treeviewItemsByUUID, parentUUID)) {
        var parentItem = self.treeviewItemsByUUID[$ parentUUID];
        parentItem.addChild(tvItem, false);

        var parentAsset = parentItem.asset;
        if (struct_exists(parentAsset, "children")) array_push(parentAsset.children, folder);
        folder.__parentUI = parentAsset;
      } else {
        treeview.Items.add(tvItem);
      }
    }

    for (var i = 0; i < array_length(assetTargets); i++) {
      var target = assetTargets[i];
      var tvItem = target.item;
      var parentUUID = target.parentUUID;
      var asset = tvItem.asset;

      if (parentUUID != undefined && struct_exists(self.treeviewItemsByUUID, parentUUID)) {
        var parentItem = self.treeviewItemsByUUID[$ parentUUID];
        var parentAsset = parentItem.asset;

        // If parent is a Scene, we don't add the child treeview item yet.
        // It will be built dynamically when the Scene is expanded (lazy-load).
        if (parentAsset.type != "Scene") {
          parentItem.addChild(tvItem, false);
        }

        if (parentAsset.type == "Folder") {
          array_push(parentAsset.children, asset);
        } else if (struct_exists(parentAsset, "add")) {
          parentAsset.add(asset);
        }
        asset.__parentUI = parentUUID;
      } else {
        treeview.Items.add(tvItem);
      }
    }

    // 4. Convert __parentUI for all assets to object references
    var allAssets = oSceneEditor.assetManager.assets;
    for (var i = 0; i < array_length(allAssets); i++) {
      var asset = allAssets[i];
      if (struct_exists(asset, "__parentUI") && is_string(asset.__parentUI)) {
        var parentUUID = asset.__parentUI;
        if (struct_exists(self.treeviewItemsByUUID, parentUUID)) {
          asset.__parentUI = self.treeviewItemsByUUID[$ parentUUID].asset;
        } else {
          asset.__parentUI = undefined;
        }
      }
    }

    // 5. Build Material / Mesh / Texture links
    self.__linkNodes();

    // Clear the cache
    self.treeviewItemsByUUID = {};
    projectManager.markAsSaved();
  };

  self.__createFolderItem = function (fData, treeview) {
    if (fData == undefined) return undefined;
    
    var uuid = fData[$ "uuid"];
    var folder = new EditorFolder({
      name: fData[$ "name"],
      uuid: uuid
    });

    var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
      treeview: treeview,
      assetType: "Folder",
      type: "Folder",
      icon: sprUiFolder,
      asset: folder
    });

    self.treeviewItemsByUUID[$ uuid] = tvItem;
    oSceneEditor.assetManager.addAsset("Folder", folder);

    return { item: tvItem, parentUUID: fData[$ "__parentUI"] };
  };

  self.__registerAssetFromNode = function (node, treeview, assetTargets, projectDir) {
    var asset = self.__createAssetFromNode(projectDir, node);
    if (asset != undefined) {
      var icon = self.__iconForType(asset.type);
      var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
        treeview: treeview,
        assetType: asset.type,
        type: asset.type,
        icon: icon,
        asset: asset
      });

      self.treeviewItemsByUUID[$ asset.uuid] = tvItem;
      oSceneEditor.assetManager.addAsset(asset.type, asset);

      // Save for parenting pass
      array_push(assetTargets, {
        item: tvItem,
        parentUUID: node[$ "__parentUI"]
      });
    }
  };

  self.__applyProjectSettings = function (settings) {
    if (settings[$ "counters"] != undefined) {
      var c = settings.counters;
      if (c[$ "textures"] != undefined) global.UI_ASSETS_TEXTURES_ID = c.textures;
      if (c[$ "materials"] != undefined) global.UI_ASSETS_MATERIALS_ID = c.materials;
      if (c[$ "models"] != undefined) global.UI_ASSETS_MODELS_ID = c.models;
      if (c[$ "scenes"] != undefined) global.UI_ASSETS_SCENES_ID = c.scenes;
      if (c[$ "object3d"] != undefined) global.UI_ASSETS_OBJECT3D_ID = c.object3d;
      if (c[$ "instances"] != undefined) global.UI_ASSETS_INSTANCE_ID = c.instances;
      if (c[$ "folders"] != undefined) global.UI_ASSETS_FOLDERS_ID = c.folders;
    }

    if (settings[$ "camera"] != undefined) {
      var c = settings.camera;
      var sm = oSceneEditor.sceneManager;
      if (sm.camera != undefined && c[$ "position"] != undefined) {
        sm.camera.setPosition(c.position[0], c.position[1], c.position[2]);
      }
      if (sm.orbit != undefined) {
        if (c[$ "target"] != undefined) vec3_set(sm.orbit.target, c.target[0], c.target[1], c.target[2]);
        if (c[$ "dampingFactor"] != undefined) sm.orbit.dampingFactor = c.dampingFactor;
        sm.orbit.updateSphericalCoordinates();
        sm.orbit.update();
      }
      oSceneEditor.editorManager.sceneTools.updateDampingButton();
    }

    if (settings[$ "gridEnabled"] != undefined) {
      var sm = oSceneEditor.sceneManager;
      sm.gridEnabled = settings.gridEnabled;
      sm.grid.visible = settings.gridEnabled;
      oSceneEditor.editorManager.sceneTools.updateGridButton();
    }

    if (settings[$ "gizmos"] != undefined) {
      var g = settings.gizmos;
      var sm = oSceneEditor.sceneManager;
      if (g[$ "showBoxColliders"] != undefined) {
        sm.showBoxColliders = g.showBoxColliders;
        sm.boxHelper.visible = sm.showBoxColliders;
      }
      oSceneEditor.editorManager.sceneTools.updateBoxCollidersButton();
    }
  };

  self.__linkNodes = function () {
    var assetManager = oSceneEditor.assetManager;
    var texturesByUUID = {};
    var objectsByUUID = {};

    var textures = assetManager.getAssetsByType("Texture");
    for (var i = 0, il = array_length(textures); i < il; i++) {
        texturesByUUID[$ textures[i].uuid] = textures[i];
    }

    var meshes = assetManager.getAssetsByType("Mesh");
    var geometriesByUUID = {};
    for (var i = 0, il = array_length(meshes); i < il; i++) {
        objectsByUUID[$ meshes[i].uuid] = meshes[i];
        if (meshes[i].geometry != undefined) {
             geometriesByUUID[$ meshes[i].geometry.uuid] = meshes[i].geometry;
        }
    }

    var materials = assetManager.getAssetsByType("Material");
    var materialsByUUID = {};
    for (var i = 0, il = array_length(materials); i < il; i++) {
        materialsByUUID[$ materials[i].uuid] = materials[i];
    }

    for (var i = 0, il = array_length(materials); i < il; i++) {
      var material = materials[i];
      if (struct_exists(material, "__json") && material.__json != undefined) {
        material.fromJSON(material.__json, texturesByUUID);
        delete material.__json;
      }
    }

    for (var i = 0, il = array_length(meshes); i < il; i++) {
      var mesh = meshes[i];
      var materialUUID = mesh[$ "materialUUID"];
      if (materialUUID != undefined && materialsByUUID[$ materialUUID] != undefined) {
        mesh.material = materialsByUUID[$ materialUUID];
      }
    }

    var scenes = assetManager.getAssetsByType("Scene");
    var treeview = global.UI.Main.Assets.Treeview;

    // Set up lazy loading callback for the treeview
    var loaderRef = self;
    treeview.onExpand = method({ loader: loaderRef, objectsByUUID, materialsByUUID, geometriesByUUID }, function (treeviewItem) {
      if (treeviewItem[$ "needsLoading"] == true) {
        var scene = treeviewItem.asset;
        if (scene != undefined && scene.type == "Scene") {
          treeviewItem.Items.clear();

          var sceneData = undefined;
          if (struct_exists(scene, "__sceneJSON") && scene.__sceneJSON != undefined) {
            sceneData = scene.__sceneJSON;
          } else if (struct_exists(scene, "__assetPath") && file_exists(scene.__assetPath)) {
            sceneData = loader.__readJson(scene.__assetPath);
          }

          if (sceneData != undefined) {
            scene.fromJSON(sceneData, objectsByUUID, materialsByUUID, geometriesByUUID);
            loader.__initEditorPropsRecursive(scene, sceneData);

            loader.__buildTreeviewForScene(scene, treeviewItem, treeviewItem.treeview);
            scene.forceUpdate();
          }

          treeviewItem.needsLoading = false;
          treeviewItem.__updateArrowVisibility();
          if (struct_exists(scene, "__sceneJSON")) delete scene.__sceneJSON;
        }
      }
    });

    treeview.onCollapse = method(self, function (treeviewItem) {
      var scene = treeviewItem.asset;
      var editorManager = oSceneEditor.editorManager;

      if (scene != undefined && scene.type == "Scene" && editorManager.activeScene != scene) {
        scene.__sceneJSON = scene.toJSON(true); // Serialize state recursively to memory before unloading
        scene.clear(true);
        treeviewItem.Items.clear(); 
        treeviewItem.needsLoading = true;
        treeviewItem.needsLoading = true;
        treeviewItem.Arrow.visible = false;
      }
    });

    for (var i = 0, il = array_length(scenes); i < il; i++) {
        var scene = scenes[i];
        var sceneItem = loaderRef.treeviewItemsByUUID[$ scene.uuid];
        if (sceneItem != undefined) {
             sceneItem.needsLoading = true;
             sceneItem.Arrow.visible = false;
        }
    }
  };

  self.__iconForType = function (type) {
    switch (type) {
      case "Texture": return sprUiTexture;
      case "Material": return sprUiMaterial;
      case "Mesh": return sprUiMesh;
      case "Bone": return sprUiBone;
      case "Scene": return sprUiScene;
      case "Folder": return sprUiFolder;
      case "Object3D": return sprUiObject;
    }
    return undefined;
  };

  self.__getTypeDir = function (type) {
    switch (type) {
      case "Texture": return "Textures";
      case "Material": return "Materials";
      case "Mesh": return "Objects";
      case "Scene": return "Scenes";
    }
    return "Objects";
  };

  self.__buildTreeviewForScene = function (scene, sceneItem, treeview) {
    for (var i = 0; i < array_length(scene.children); i++) {
      var child = scene.children[i];
      self.__buildTreeviewForAssetRecursive(child, sceneItem, treeview);
    }
  };

  self.__buildTreeviewForAssetRecursive = function (asset, parentItem, treeview) {
    if (asset == undefined) return;

    var icon = self.__iconForType(asset.type);
    var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
      treeview: treeview,
      assetType: asset.type,
      type: asset.type,
      icon: icon,
      asset: asset
    });

    parentItem.addChild(tvItem, false);

    for (var i = 0, il = array_length(asset.children); i < il; i++) {
      var child = asset.children[i];
      self.__buildTreeviewForAssetRecursive(child, tvItem, treeview);
    }
    
    tvItem.__updateArrowVisibility();
  };

  self.__initEditorPropsRecursive = function (asset, node) {
    if (asset == undefined) return;

    var type = asset.type;
    if (asset[$ "isObject3D"] || type == "Scene" || type == "Object3D" || type == "Mesh" || type == "Camera" || type == "Bone") {
      if (asset[$ "__rotationEuler"] == undefined) {
        asset.__rotationEuler = euler_create();
      }

      if (is_struct(node) && struct_exists(node, "rotationEuler") && node.rotationEuler != undefined) {
        euler_copy(asset.__rotationEuler, node.rotationEuler);
      } else {
        euler_set_from_quaternion(asset.__rotationEuler, asset.rotation);
      }

      asset.matrixAutoUpdate = false;
      asset.updateMatrix();
      asset.updateMatrixWorld();
    }

    if (is_struct(node) && struct_exists(node, "children") && is_array(node.children) && struct_exists(asset, "children")) {
      var childNodes = node.children;
      var children = asset.children;
      var count = min(array_length(childNodes), array_length(children));
      for (var i = 0; i < count; i++) {
        self.__initEditorPropsRecursive(children[i], childNodes[i]);
      }
    }
  };

  self.__createAssetFromNode = function (projectDir, node) {
    if (node[$ "type"] == "Folder") {
      return new EditorFolder({ name: node[$ "name"], uuid: node[$ "uuid"] });
    }

    var asset = undefined;
    var type = node[$ "type"];
    var uuid = node[$ "uuid"];
    var typeDir = self.__getTypeDir(type);
    var assetDir = projectDir + "Assets/" + typeDir + "/" + uuid + "/";

    switch (type) {
      case "Texture": asset = new UeTexture(); break;
      case "Material": asset = new UeMeshStandardMaterial(); break;
      case "Mesh": asset = new UeStaticMesh(); break;
      case "Object3D": asset = new UeObject3D(); break;
      case "Scene": asset = new UeScene(); break;
      case "Camera": asset = new UeObject3D(); asset.isCamera = true; asset.type = "Camera"; break;
    }

    if (asset != undefined) {
      asset.__assetPath = assetDir + "asset.json";
      
      if (type == "Material") {
        asset.__json = node;
      }
      asset.fromJSON(node);
      self.__initEditorPropsRecursive(asset, node);

      if (type == "Mesh") {
        var geometryPath = assetDir + "geometry.buf";
        if (file_exists(geometryPath)) {
          var geometry = new UeGeometry({ canFreeze: true });
          if (struct_exists(node, "geometry") && node.geometry != undefined) {
            geometry.fromJSON(node.geometry);
          }
          geometry.import(geometryPath);
          geometry.__vbClone = geometry.cloneVb();
          geometry.freeze();
          asset.geometry = geometry;
        }
      }

      if (node != undefined && struct_exists(node, "__parentUI")) {
        asset.__parentUI = node[$ "__parentUI"];
      }

      var importFunc = asset[$ "import"];
      if (is_callable(importFunc)) {
        var texturePath = assetDir + "texture.png";
        if (file_exists(texturePath)) {
          asset.import(texturePath);
        }
      }
    }
    return asset;
  };

  self.__readJson = function (path) {
    var bf = buffer_load(path);
    if (bf == -1) return undefined;
    var str = buffer_read(bf, buffer_text);
    buffer_delete(bf);
    return json_parse(str);
  };
}
