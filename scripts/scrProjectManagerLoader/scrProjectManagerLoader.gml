/// @description Project Loader - Handles loading project data and assets

function ProjectLoader() constructor {
    
    /**
     * Load project from ue.json
     * @param {Struct} projectManager - The project manager instance
     */
    function load(projectManager) {
      var projectDir = projectManager.projectDatafiles + "/Unique Project/";
      var assetsJsonPath = projectDir + "assets.json";
      var projectJsonPath = projectDir + "project.json";
      
      // Check if project files exist
      if (!file_exists(assetsJsonPath) || !file_exists(projectJsonPath)) {
          show_debug_message("Project files not found. Project path set, but no assets to load.");
          return;
      }
      
      // Read and parse both files
      var assetsData = __readJson(assetsJsonPath);
      var projectData = __readJson(projectJsonPath);
      
      if (assetsData == undefined || projectData == undefined) {
          show_debug_message("Invalid project file format.");
          return;
      }
      
      // Load project data
      if (projectData[$ "hierarchy"] == undefined || assetsData == undefined) {
          show_debug_message("Invalid project file format.");
          return;
      }
      
      __loadAssets(projectData, assetsData, projectDir);
      
      projectManager.markAsSaved();
      show_debug_message("Project loaded successfully!");
    }
    
    /**
     * Load assets from project data
     */
    function __loadAssets(projectData, assetsData, projectDir) {
      var hierarchy = projectData.hierarchy;
      var assetsLists = assetsData;
      
      // Build folder hierarchy first
      var folderMap = {}; // name -> folder struct
      var treeviewItemMap = {}; // name -> treeviewItem
      
      __buildFolders(hierarchy, folderMap, treeviewItemMap);
      
      // Load root assets and place them in hierarchy
      var assetsByUUID = {};
      
      __loadAssetsList(assetsLists.textures, projectDir, "Texture", hierarchy, treeviewItemMap, folderMap, assetsByUUID, sprUiTexture);
      __loadAssetsList(assetsLists.materials, projectDir, "Material", hierarchy, treeviewItemMap, folderMap, assetsByUUID, sprUiMaterial);
      __loadAssetsList(assetsLists.models, projectDir, "Mesh", hierarchy, treeviewItemMap, folderMap, assetsByUUID, sprUiObject);
      
      // Link references (textures in materials, materials in meshes) before loading scenes
      __linkReferences(assetsByUUID);
      
      // Load scenes last, after all models are loaded and linked
      __loadAssetsList(assetsLists.scenes, projectDir, "Scene", hierarchy, treeviewItemMap, folderMap, assetsByUUID, sprUiScene);
    }
    
    /**
     * Build folder hierarchy
     */
    function __buildFolders(hierarchy, folderMap, treeviewItemMap) {
      __buildFoldersRecursive(hierarchy, undefined, folderMap, treeviewItemMap);
    }
    
    /**
     * Build folders recursively from tree structure
     */
    function __buildFoldersRecursive(entries, parentFolder, folderMap, treeviewItemMap) {
      var treeview = global.UI.Main.Assets.Treeview;
      
      for (var i = 0; i < array_length(entries); i++) {
          var entry = entries[i];
          
          // Check if entry is a folder (has children) or asset
          // Folders have key="fld/name" and children array
          if (entry[$ "key"] != undefined && entry[$ "children"] != undefined) {
              var key = entry.key;
              var slashPos = string_pos("/", key);
              if (slashPos > 0 && string_copy(key, 1, slashPos - 1) == "fld") {
                  var folderName = string_delete(key, 1, slashPos);
                  
                  // Create folder
                  var folder = {
                      type: "Folder",
                      name: folderName,
                      uuid: ueUuid(),
                      children: []
                  };
                  
                  folderMap[$ folderName] = folder;
                  
                  // Create treeview item
                  var parentTreeviewItem = parentFolder != undefined ? treeviewItemMap[$ parentFolder.name] : undefined;
                  
                  var folderItem = new UiTreeviewItem({
                      name: "UiTreeview.Item",
                      paddingVertical: 2.5
                  }, {
                      treeview: treeview,
                      assetType: "Folder",
                      type: "Folder",
                      icon: sprUiFolder,
                      asset: folder
                  });
                  
                  if (parentTreeviewItem != undefined) {
                      parentTreeviewItem.addChild(folderItem);
                      array_push(parentFolder.children, folder);
                      folder.parent = parentFolder;
                  } else {
                      treeview.Items.add(folderItem);
                  }
                  
                  treeviewItemMap[$ folderName] = folderItem;
                  
                  // Add to asset manager
                  oSceneEditor.assetManager.addAsset("Folder", folder, parentFolder);
                  
                  // Process children recursively
                  if (array_length(entry.children) > 0) {
                      __buildFoldersRecursive(entry.children, folder, folderMap, treeviewItemMap);
                  }
              }
          }
      }
    }
    
    /**
     * Load a list of assets of the same type
     */
    function __loadAssetsList(assetUUIDs, projectDir, assetType, hierarchy, treeviewItemMap, folderMap, assetsByUUID, icon) {
      if (assetUUIDs == undefined) return;
      
      var typeFolder = "";
      switch (assetType) {
          case "Texture": typeFolder = "textures/"; break;
          case "Material": typeFolder = "materials/"; break;
          case "Mesh": typeFolder = "meshes/"; break;
          case "Scene": typeFolder = "scenes/"; break;
      }
      
      for (var i = 0; i < array_length(assetUUIDs); i++) {
          var assetUUID = assetUUIDs[i];
          var asset = undefined;
          
          switch (assetType) {
              case "Texture":
                  asset = __loadTexture(assetUUID, projectDir + typeFolder);
                  break;
              case "Material":
                  asset = __loadMaterial(assetUUID, projectDir + typeFolder);
                  break;
              case "Mesh":
                  asset = __loadMesh(assetUUID, projectDir + typeFolder, assetsByUUID);
                  break;
              case "Scene":
                  asset = __loadScene(assetUUID, projectDir + typeFolder, assetsByUUID);
                  break;
          }
          
          if (asset != undefined) {
              assetsByUUID[$ asset.uuid] = asset;
              var treeviewItem = __placeInHierarchy(asset, hierarchy, treeviewItemMap, folderMap, icon);
              
              // For scenes, add instances as treeview children
              if (assetType == "Scene" && asset.children != undefined) {
                  __addSceneInstancesToTreeview(asset, treeviewItem);
              }
              
              // For meshes, add submeshes as treeview children
              if (assetType == "Mesh" && asset.children != undefined && array_length(asset.children) > 0) {
                  __addSubmeshesToTreeview(asset, treeviewItem);
              }
          }
      }
    }
    
    /**
     * Load a texture asset
     */
    function __loadTexture(assetUUID, assetsDir) {
        var assetDir = assetsDir + assetUUID + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        var asset = new UeTexture().fromJSON(metadata);
        
        // Load sprite if exists
        var texturePath = assetDir + "texture.png";
        if (file_exists(texturePath)) {
            var loadedSprite = sprite_add(texturePath, 1, false, false, 0, 0);
            if (loadedSprite != -1) {
                asset.sprite = loadedSprite;
                asset.__cachedSprite = loadedSprite;
                asset.__cachedTexture = sprite_get_texture(loadedSprite, 0);
            }
        }
        
        return asset;
    }
    
    /**
     * Load a material asset
     */
    function __loadMaterial(assetUUID, assetsDir) {
        var assetDir = assetsDir + assetUUID + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        // Convert shader name to asset index
        if (metadata.shader != undefined) {
            metadata.shader = asset_get_index(metadata.shader);
        }
        
        var asset = new UeMaterial().fromJSON(metadata, {});
        
        return asset;
    }
    
    /**
     * Load a mesh asset
     */
    function __loadMesh(assetUUID, assetsDir, assetsByUUID = undefined) {
        var assetDir = assetsDir + assetUUID + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        // Load geometry if exists
        var geometryPath = assetDir + "geometry.buf";
        var geometry = undefined;
        
        if (file_exists(geometryPath) && metadata[$ "geometry"] != undefined) {
            geometry = new UeBufferGeometry().fromJSON(metadata.geometry);
            geometry.import(geometryPath);
        }
        
        var asset = new UeMesh(geometry).fromJSON(metadata);
        
        // Initialize editor-specific property for rotation display
        asset.__rotationEuler = new UeEuler();
        
        // Register this mesh in assetsByUUID if provided
        if (assetsByUUID != undefined && asset.uuid != undefined) {
            assetsByUUID[$ asset.uuid] = asset;
        }
        
        // Store material UUID temporarily for linking later
        if (metadata[$ "material"] != undefined) {
            asset.materialUUID = metadata.material;
        }
        
        // Load submeshes recursively from subdirectories using children UUIDs
        if (metadata[$ "children"] != undefined && is_array(metadata.children)) {
            for (var i = 0; i < array_length(metadata.children); i++) {
                var childData = metadata.children[i];
                var submeshUUID = is_struct(childData) ? childData.uuid : childData;
                var submesh = __loadMesh(submeshUUID, assetDir, assetsByUUID);
                if (submesh != undefined) {
                    submesh.parent = asset;
                    asset.add(submesh);
                }
            }
        }
        
        return asset;
    }
    
    /**
     * Load a scene asset
     */
    function __loadScene(assetUUID, assetsDir, assetsByUUID = {}) {
      var assetDir = assetsDir + assetUUID + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        // Use the assetsByUUID map directly for linking instances to models
        var asset = new UeScene().fromJSON(metadata, assetsByUUID);
        
        // Register instances in assetsByUUID for reference
        if (asset.children != undefined) {
            for (var i = 0; i < array_length(asset.children); i++) {
                var child = asset.children[i];
                if (child[$ "type"] == "ModelInstance" && child.uuid != undefined) {
                    assetsByUUID[$ child.uuid] = child;
                }
            }
        }
        
        return asset;
    }
    
    /**
     * Place asset in correct position in hierarchy
     */
    function __placeInHierarchy(asset, hierarchy, treeviewItemMap, folderMap, icon) {
        var treeview = global.UI.Main.Assets.Treeview;
        var parentFolder = undefined;
        
        // Find parent folder by searching in hierarchy tree
        parentFolder = __findAssetParent(asset.name, hierarchy, folderMap);
        
        var parentTreeviewItem = parentFolder != undefined ? treeviewItemMap[$ parentFolder.name] : undefined;
        
        // Create treeview item
        var assetItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
            paddingVertical: 2.5
        }, {
            treeview: treeview,
            assetType: asset.type,
            type: asset.type,
            icon: icon,
            asset: asset
        });
        
        if (parentTreeviewItem != undefined) {
            parentTreeviewItem.addChild(assetItem);
            if (parentFolder != undefined) {
                array_push(parentFolder.children, asset);
                asset.parent = parentFolder;
            }
        } else {
            treeview.Items.add(assetItem);
        }
        
        // Add to asset manager
        var typeKey = asset.type;
        oSceneEditor.assetManager.addAsset(typeKey, asset, parentFolder);
        
        return assetItem;
    }
    
    /**
     * Add scene instances to treeview as children
     */
    function __addSceneInstancesToTreeview(scene, sceneTreeviewItem) {
        var treeview = global.UI.Main.Assets.Treeview;
        
        if (scene.children == undefined) return;
        
        for (var i = 0; i < array_length(scene.children); i++) {
            var instance = scene.children[i];
            
            if (instance[$ "type"] == "ModelInstance") {
                // Create treeview item for instance
                var instanceItem = new UiTreeviewItem({
                    name: "UiTreeview.Item",
                    paddingVertical: 2.5
                }, {
                    treeview: treeview,
                    assetType: "ModelInstance",
                    type: "ModelInstance",
                    icon: sprUiObject,
                    asset: instance
                });
                
                sceneTreeviewItem.addChild(instanceItem);
                
                // Add to asset manager
                oSceneEditor.assetManager.addAsset("Mesh", instance, scene);
            }
        }
    }
    
    /**
     * Add submeshes to treeview as children recursively
     */
    function __addSubmeshesToTreeview(mesh, meshTreeviewItem) {
        var treeview = global.UI.Main.Assets.Treeview;
        
        if (mesh.children == undefined) return;
        
        for (var i = 0; i < array_length(mesh.children); i++) {
            var submesh = mesh.children[i];
            
            // Create treeview item for submesh
            var submeshItem = new UiTreeviewItem({
                name: "UiTreeview.Item",
                paddingVertical: 2.5
            }, {
                treeview: treeview,
                assetType: "Mesh",
                type: "Mesh",
                icon: sprUiObject,
                asset: submesh
            });
            
            meshTreeviewItem.addChild(submeshItem);
            
            // Recursively add sub-submeshes
            if (submesh.children != undefined && array_length(submesh.children) > 0) {
                __addSubmeshesToTreeview(submesh, submeshItem);
            }
        }
    }
    
    /**
     * Find parent folder for an asset in hierarchy tree
     */
    function __findAssetParent(assetName, entries, folderMap) {
        for (var i = 0; i < array_length(entries); i++) {
            var entry = entries[i];
            
            // Check if this is a folder (has key and children)
            if (entry[$ "key"] != undefined && entry[$ "children"] != undefined) {
                var key = entry.key;
                var slashPos = string_pos("/", key);
                if (slashPos > 0 && string_copy(key, 1, slashPos - 1) == "fld") {
                    var folderName = string_delete(key, 1, slashPos);
                    
                    // Check children for asset
                    for (var j = 0; j < array_length(entry.children); j++) {
                        var child = entry.children[j];
                        
                        // Parse child entry { key: "type/name" }
                        if (child[$ "key"] != undefined) {
                            var childKey = child.key;
                            var childSlashPos = string_pos("/", childKey);
                            if (childSlashPos > 0) {
                                var childName = string_delete(childKey, 1, childSlashPos);
                                if (childName == assetName) {
                                    return folderMap[$ folderName];
                                }
                            }
                        }
                    }
                    
                    // Search recursively in subfolders
                    var found = __findAssetParent(assetName, entry.children, folderMap);
                    if (found != undefined) return found;
                }
            }
        }
        
        return undefined;
    }
    
    /**
     * Link asset references
     */
    function __linkReferences(assetsByUUID) {
        var assetUUIDs = variable_struct_get_names(assetsByUUID);
        
        for (var i = 0; i < array_length(assetUUIDs); i++) {
            var assetUUID = assetUUIDs[i];
            var asset = assetsByUUID[$ assetUUID];
            
            // Link textures in materials
            if (asset[$ "type"] == "Material" && asset[$ "textures"] != undefined) {
                var savedTextures = asset.textures; // Store UUIDs temporarily
                asset.textures = {}; // Reset to empty object
                var textureSlots = variable_struct_get_names(savedTextures);
                for (var j = 0; j < array_length(textureSlots); j++) {
                    var slot = textureSlots[j];
                    var textureUUID = savedTextures[$ slot];
                    
                    if (is_string(textureUUID) && textureUUID != "" && assetsByUUID[$ textureUUID] != undefined) {
                        asset.textures[$ slot] = assetsByUUID[$ textureUUID];
                    } else {
                        asset.textures[$ slot] = undefined;
                    }
                }
                
                asset.build();
            }
            
            // Link materials in meshes
            if (asset[$ "type"] == "Mesh" && asset[$ "materialUUID"] != undefined) {
                var materialUUID = asset.materialUUID;
                if (assetsByUUID[$ materialUUID] != undefined) {
                    asset.material = assetsByUUID[$ materialUUID];
                }
                delete asset.materialUUID;
            }
        }
    }
    
    /**
     * Read JSON from file
     */
    function __readJson(filePath) {
        if (!file_exists(filePath)) return undefined;
        
        var file = file_text_open_read(filePath);
        var jsonString = "";
        while (!file_text_eof(file)) {
            jsonString += file_text_read_string(file);
            file_text_readln(file);
        }
        file_text_close(file);
        
        return json_parse(jsonString);
    }
}

