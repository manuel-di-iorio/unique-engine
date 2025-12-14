function ProjectLoader() constructor {
  treeviewItemsByUUID = {};

  /**
   * Load project from assets.json
   * @param {Struct} projectManager - The project manager instance
   */
  function load(projectManager) {
    var projectDir = projectManager.projectDatafiles + "/Unique Project/";
    var assetsJsonPath = projectDir + "assets.json";

    if (!file_exists(assetsJsonPath)) return;

    var assetsData = __readJson(assetsJsonPath);
    
    // Apply settings
    if (assetsData[$ "settings"] != undefined) {
        self.__applyProjectSettings(assetsData.settings);
    }

    var treeview = global.UI.Main.Assets.Treeview;
    treeviewItemsByUUID = {};
    
    // 1. Create all Folders first (flat list from assets.json)
    var foldersMap = assetsData[$ "folders"] ?? {};
    var folderUUIDs = variable_struct_get_names(foldersMap);
    
    for (var i = 0; i < array_length(folderUUIDs); i++) {
        var uuid = folderUUIDs[i];
        var folderData = foldersMap[$ uuid];
        
        // Create Folder Asset
        var folder = new EditorFolder({
            name: folderData.name,
            uuid
        });
        
        // Create Treeview Item
        var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
            treeview,
            assetType: "Folder",
            type: "Folder",
            icon: sprUiFolder,
            asset: folder
        });
        
        treeviewItemsByUUID[$ uuid] = tvItem;
        oSceneEditor.assetManager.addAsset("Folder", folder);
    }
    
    // 2. Link Folders to their parents (reconstruct folder hierarchy)
    for (var i = 0; i < array_length(folderUUIDs); i++) {
        var uuid = folderUUIDs[i];
        var folderData = foldersMap[$ uuid];
        var tvItem = treeviewItemsByUUID[$ uuid];
        var folder = tvItem.asset;
        
        var parentUUID = folderData[$ "__parentUI"];
        
        if (parentUUID != undefined && treeviewItemsByUUID[$ parentUUID] != undefined) {
            var parentItem = treeviewItemsByUUID[$ parentUUID];
            parentItem.addChild(tvItem, false);
            
            // Add to parent asset children
            var parentAsset = parentItem.asset;
            if (parentAsset[$ "children"] != undefined) {
                array_push(parentAsset.children, folder);
            }
            folder.__parentUI = parentAsset;
        } else {
            // Root folder
            treeview.Items.add(tvItem);
        }
    }
    
    // 3. Convert __parentUI UUIDs to object references for all folders
    for (var i = 0; i < array_length(folderUUIDs); i++) {
        var uuid = folderUUIDs[i];
        var folder = treeviewItemsByUUID[$ uuid].asset;
        
        // If __parentUI is still a string (UUID), convert it to object reference
        if (folder[$ "__parentUI"] != undefined && is_string(folder.__parentUI)) {
            var parentUUID = folder.__parentUI;
            if (treeviewItemsByUUID[$ parentUUID] != undefined) {
                folder.__parentUI = treeviewItemsByUUID[$ parentUUID].asset;
            } else {
                folder.__parentUI = undefined;
            }
        }
    }
    
    // 4. Load Assets and place them in the correct folders
    var assetsList = assetsData.assets;
    for (var i = 0; i < array_length(assetsList); i++) {
        var assetEntry = assetsList[i];
        
        // Handle both old format (UUID string) and new format (object with id, name, type)
        var assetUuid = is_string(assetEntry) ? assetEntry : assetEntry.id;

        // Each asset entry is now a UUID; read its metadata.json to determine type/name
        var metadataPath = projectDir + "assets/" + assetUuid + "/metadata.json";
        if (!file_exists(metadataPath)) continue;

        var node = __readJson(metadataPath);
        
        // Ensure uuid is present on the node
        node.uuid = assetUuid;
        
        // Safety check: ModelInstance should not be in assets.json (they are part of Scene)
        if (node[$ "type"] == "ModelInstance") continue;

        var asset = __createAssetFromNode(projectDir, node);

        if (asset != undefined) {
            var icon = __iconForType(asset.type);
            var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
                treeview,
                assetType: asset.type,
                type: asset.type,
                icon,
                asset
            });

            treeviewItemsByUUID[$ asset.uuid] = tvItem;
            oSceneEditor.assetManager.addAsset(asset.type, asset);

            // Place in folder if metadata says so
            var parentUUID = undefined;
            if (asset[$ "__metadata"] != undefined && asset.__metadata[$ "__parentUI"] != undefined) {
                parentUUID = asset.__metadata.__parentUI;
            }

            if (parentUUID != undefined && treeviewItemsByUUID[$ parentUUID] != undefined) {
                var parentItem = treeviewItemsByUUID[$ parentUUID];
                parentItem.addChild(tvItem, false);

                // Add to parent asset
                var parentAsset = parentItem.asset;
                if (parentAsset.type == "Folder") {
                    array_push(parentAsset.children, asset);
                } else {
                    if (parentAsset[$ "add"] != undefined) parentAsset.add(asset);
                }
                // asset.parent = parentAsset;
            } else {
                // Root asset
                treeview.Items.add(tvItem);
            }
        }
    }

    // 5. Convert __parentUI UUIDs to object references for all assets
    var allAssets = oSceneEditor.assetManager.assets;
    for (var i = 0; i < array_length(allAssets); i++) {
        var asset = allAssets[i];
        
        // Skip folders (already processed)
        if (asset.type == "Folder") continue;
        
        // If __parentUI is still a string (UUID), convert it to object reference
        if (asset[$ "__parentUI"] != undefined && is_string(asset.__parentUI)) {
            var parentUUID = asset.__parentUI;
            if (treeviewItemsByUUID[$ parentUUID] != undefined) {
                asset.__parentUI = treeviewItemsByUUID[$ parentUUID].asset;
            } else {
                asset.__parentUI = undefined;
            }
        }
    }
    
    // 6. Link asset references (Materials <-> Meshes, etc.)
    __linkNodes();

    // Clear the cache
    treeviewItemsByUUID = {};
    
    projectManager.markAsSaved();
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
    
    var textures = assetManager.getAssetsByType("Texture");
    for (var i = 0; i < array_length(textures); i++) {
        var texture = textures[i];
        texturesByUUID[$ texture.uuid] = texture;
        // Load texture metadata
        if (texture[$ "__metadata"] != undefined) {
            texture.fromJSON(texture.__metadata);
            delete texture.__metadata;
        }
    }
    
    var meshes = assetManager.getAssetsByType("Mesh");
    for (var i = 0; i < array_length(meshes); i++) {
        var mesh = meshes[i];
        objectsByUUID[$ mesh.uuid] = mesh;
        // Load mesh metadata (transform, etc.)
        if (mesh[$ "__metadata"] != undefined) {
            mesh.fromJSON(mesh.__metadata);
        }
    }
    
    // 2. Link Materials (Textures)
    var materials = assetManager.getAssetsByType("Material");
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
        
        // Initial matrix update
        mesh.updateMatrix();
        mesh.updateMatrixWorld(true);
    }
    
    // 3. Link Scenes (ModelInstances)
    var scenes = assetManager.getAssetsByType("Scene");
    for (var i = 0; i < array_length(scenes); i++) {
        var scene = scenes[i];
        if (scene[$ "__metadata"] != undefined) {
            scene.fromJSON(scene.__metadata, objectsByUUID);
            delete scene.__metadata;
            
            scene.traverse(function(child) {
               child.__matrixAutoUpdate = child.matrixAutoUpdate;
               child.matrixAutoUpdate = false; 
            });
            
            scene.updateWorldMatrix(false, true);
            
            // 4. Update TreeView for new instances
            // The scene.fromJSON() created new ModelInstance objects and added them to the scene children
            // We need to create TreeView items for them
            if (treeviewItemsByUUID[$ scene.uuid] != undefined) {
                var sceneTreeItem = treeviewItemsByUUID[$ scene.uuid];
                
                // Process all top-level instances in the scene
                for (var j = 0; j < array_length(scene.children); j++) {
                    var child = scene.children[j];
                    if (child.type == "ModelInstance") {
                        __createInstanceTreeItems(child, sceneTreeItem);
                    }
                }
            }
        }
    }
  }

  /**
   * Private helper: Recursively create treeview items for ModelInstance and its children
   */
  function __createInstanceTreeItems(instance, parentTreeItem) {
      // Initialize rotation euler for inspector
      instance.__rotationEuler = new UeEuler();
      instance.__rotationEuler.setFromQuaternion(instance.rotation);
      
      // Create TreeView item for the instance
      var icon = __iconForType("ModelInstance");
      var tvItem = new UiTreeviewItem({ name: "UiTreeview.Item" }, {
          treeview: parentTreeItem.treeview,
          assetType: "ModelInstance",
          type: "ModelInstance",
          icon,
          asset: instance
      });
      
      // Add back-reference for mesh picking
      instance.__treeviewItem = tvItem;
      
      parentTreeItem.addChild(tvItem, false);
      
      // Recursively create treeview items for children (submeshes)
      for (var k = 0; k < array_length(instance.children); k++) {
          var childInstance = instance.children[k];
          if (childInstance.type == "ModelInstance") {
              __createInstanceTreeItems(childInstance, tvItem);
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
      var folder = new EditorFolder({
        name: node.name,
        uuid: node.uuid,
      });
      return folder;
    }

    var asset = undefined;
    switch (node.type) {
      case "Texture": asset = new UeTexture(); break;
      case "Material": asset = new UeMaterial(); break;
      case "Mesh": asset = new UeStaticMesh(); break;
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
        // Load __static field from metadata (used for export)
        asset.__matrixAutoUpdate = meta[$ "matrixAutoUpdate"] ?? false;
        
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
          var geometry = new UeBufferGeometry({ canFreeze: true });
          geometry.import(geometryPath);
          geometry.__vbClone = geometry.cloneVb();
          geometry.freeze();
          asset.geometry = geometry;
        }
      }
      
      // Load __parentUI from metadata (for treeview organization)
      if (asset.__metadata != undefined && asset.__metadata[$ "__parentUI"] != undefined) {
        asset.__parentUI = asset.__metadata.__parentUI;
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

  function __readJson(filePath) {
      var buf = buffer_load(filePath);
      var jsonString = buffer_read(buf, buffer_text);
      buffer_delete(buf);
      return json_parse(jsonString);
  }
}
