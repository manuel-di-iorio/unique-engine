function ProjectLoader() constructor {
  treeviewItemsByUUID = {};

  /**
   * Load project from project.json
   * @param {Struct} projectManager - The project manager instance
   */
  function load(projectManager) {
    var projectDir = projectManager.projectDatafiles + "/Unique Project/";
    var projectJsonPath = projectDir + "project.json";

    if (!file_exists(projectJsonPath)) return;

    var projectData = __readJson(projectJsonPath);
    
    // Apply settings
    if (projectData[$ "settings"] != undefined) {
        self.__applyProjectSettings(projectData.settings);
    }

    var treeview = global.UI.Main.Assets.Treeview;
    __recurseNodes(projectDir, treeview, projectData.assets, undefined, undefined);
    __linkNodes();
    
    // Clear the cache
    treeviewItemsByUUID = {};
    
    projectManager.markAsSaved();
    show_debug_message("Project loaded successfully!");
  }
  
  function __applyProjectSettings(settings) {
      // Counters
      if (settings[$ "counters"] != undefined) {
          var c = settings.counters;
          if (c[$ "textures"] != undefined) global.UI_ASSETS_TEXTURES_ID = c.textures;
          if (c[$ "materials"] != undefined) global.UI_ASSETS_MATERIALS_ID = c.materials;
          if (c[$ "models"] != undefined) global.UI_ASSETS_MODELS_ID = c.models;
          if (c[$ "lights"] != undefined) global.UI_ASSETS_LIGHTS_ID = c.lights;
          if (c[$ "cameras"] != undefined) global.UI_ASSETS_CAMERAS_ID = c.cameras;
          if (c[$ "scenes"] != undefined) global.UI_ASSETS_SCENES_ID = c.scenes;
          if (c[$ "instances"] != undefined) global.UI_ASSETS_INSTANCE_ID = c.instances;
          if (c[$ "folders"] != undefined) global.UI_ASSETS_FOLDERS_ID = c.folders;
      }
      
      // Camera
      if (settings[$ "camera"] != undefined) {
          var c = settings.camera;
          var sm = oSceneEditor.sceneManager;
          
          if (sm.camera != undefined && c[$ "position"] != undefined) {
              sm.camera.setPosition(c.position[0], c.position[1], c.position[2]);
          }
          
          if (sm.orbit != undefined) {
              if (c[$ "target"] != undefined) {
                  sm.orbit.target.set(c.target[0], c.target[1], c.target[2]);
              }
              if (c[$ "dampingFactor"] != undefined) {
                  sm.orbit.dampingFactor = c.dampingFactor;
              }
              sm.orbit.updateSphericalCoordinates();
              sm.orbit.update(); // Ensure orbit is updated
          }
          
          // Update UI button
          oSceneEditor.editorManager.sceneTools.updateDampingButton();
      }
      
      // Grid Enabled
      if (settings[$ "gridEnabled"] != undefined) {
          var sm = oSceneEditor.sceneManager;
          sm.gridEnabled = settings.gridEnabled;
          sm.grid.visible = settings.gridEnabled;
          
          oSceneEditor.editorManager.sceneTools.updateGridButton();
      }
      
      // Gizmos
      if (settings[$ "gizmos"] != undefined) {
          var g = settings.gizmos;
          var sm = oSceneEditor.sceneManager;
          
          if (g[$ "showBoxColliders"] != undefined) {
              sm.showBoxColliders = g.showBoxColliders;
              sm.boxHelper.visible = sm.showBoxColliders;
          }
          
          // Update UI button
          oSceneEditor.editorManager.sceneTools.updateBoxCollidersButton();
      }
  }
    
  function __linkNodes() {
    var assetManager = oSceneEditor.assetManager;
    
    // 1. Collect all assets by UUID for linking
    var texturesByUUID = {};
    var objectsByUUID = {};
    
    var textures = assetManager.getAllAssetsByType("Texture");
    for (var i = 0; i < array_length(textures); i++) {
        var texture = textures[i];
        texturesByUUID[$ texture.uuid] = texture;
        // Load texture metadata
        if (texture[$ "__metadata"] != undefined) {
            texture.fromJSON(texture.__metadata);
            delete texture.__metadata;
        }
    }
    
    var meshes = assetManager.getAllAssetsByType("Mesh");
    for (var i = 0; i < array_length(meshes); i++) {
        var mesh = meshes[i];
        objectsByUUID[$ mesh.uuid] = mesh;
        // Load mesh metadata (transform, etc.)
        if (mesh[$ "__metadata"] != undefined) {
            mesh.fromJSON(mesh.__metadata);
        }
    }
    
    // 2. Link Materials (Textures)
    var materials = assetManager.getAllAssetsByType("Material");
    var materialsByUUID = {};
    for (var i = 0; i < array_length(materials); i++) {
        var material = materials[i];
        materialsByUUID[$ material.uuid] = material;
        if (material[$ "__metadata"] != undefined) {
            material.fromJSON(material.__metadata, texturesByUUID);
            delete material.__metadata;
        }
    }
    
    // 3. Link Meshes (Materials)
    for (var i = 0; i < array_length(meshes); i++) {
        var mesh = meshes[i];
        if (mesh[$ "__metadata"] != undefined) {
            var materialUUID = mesh.__metadata[$ "material"];
            if (materialUUID != undefined && materialsByUUID[$ materialUUID] != undefined) {
                mesh.material = materialsByUUID[$ materialUUID];
            }
            delete mesh.__metadata;
        }
    }
    
    // 3. Link Scenes (ModelInstances)
    var scenes = assetManager.getAllAssetsByType("Scene");
    for (var i = 0; i < array_length(scenes); i++) {
        var scene = scenes[i];
        if (scene[$ "__metadata"] != undefined) {
            scene.fromJSON(scene.__metadata, objectsByUUID);
            delete scene.__metadata;
            
            // 4. Update TreeView for new instances
            // The scene.fromJSON() created new ModelInstance objects and added them to the scene children
            // We need to create TreeView items for them
            if (treeviewItemsByUUID[$ scene.uuid] != undefined) {
                var sceneTreeItem = treeviewItemsByUUID[$ scene.uuid];
                
                // We need to find which children were added as instances
                for (var j = 0; j < array_length(scene.children); j++) {
                    var child = scene.children[j];
                    if (child.type == "ModelInstance") {
                        // Initialize rotation euler for inspector
                        child.__rotationEuler = new UeEuler();
                        child.__rotationEuler.setFromQuaternion(child.rotation);
                        
                        // Create TreeView item for the instance
                        var icon = __iconForType("ModelInstance");
                        var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item", paddingVertical: 2.5 }, {
                            treeview: sceneTreeItem.treeview,
                            assetType: "ModelInstance",
                            type: "ModelInstance",
                            icon,
                            asset: child
                        });
                        sceneTreeItem.addChild(tvItem);
                    }
                }
            }
        }
    }
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
      case "ModelInstance": return sprUiObject;

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
      case "Camera": asset = new UeObject3D(); asset.isCamera = true; asset.type = "Camera"; break;
    }

    if (asset != undefined) {
      asset.name = node.name;
      asset.uuid = node.uuid;

      // Import the asset metadata
      var metadataPath = projectDir + "assets/" + node.uuid + "/metadata.json";
      if (file_exists(metadataPath)) {
        var meta = __readJson(metadataPath);
        asset.__metadata = meta;
      }

      // For meshes, add the rotation euler
      if (asset.type == "Mesh") {
        // Load Euler rotation from metadata if available, otherwise create from quaternion
        if (meta[$ "ex"] != undefined && meta[$ "ey"] != undefined && meta[$ "ez"] != undefined) {
          asset.__rotationEuler = new UeEuler(
            meta[$ "ex"],
            meta[$ "ey"],
            meta[$ "ez"],
            meta[$ "eo"] ?? "XYZ"
          );
        } else {
          asset.__rotationEuler = new UeEuler();
          asset.__rotationEuler.setFromQuaternion(asset.rotation);
        }
        
        // Load geometry if it exists
        var geometryPath = projectDir + "assets/" + node.uuid + "/geometry.buf";
        if (file_exists(geometryPath)) {
          var geometry = new UeBufferGeometry();
          geometry.import(geometryPath);
          asset.geometry = geometry;
        }
      }

      // Attempt to import binary resources (textures) if import() exists
      if (is_callable(asset[$ "import"])) {
        var assetPath = projectDir + "assets/" + node.uuid;
        if (directory_exists(assetPath)) {
          if (node.type == "Texture" && file_exists(assetPath + "/texture.png")) {
            asset.import(assetPath + "/texture.png");
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
      
      if (node[$ "uuid"] != undefined) {
        treeviewItemsByUUID[$ node.uuid] = tvItem;
      }

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
