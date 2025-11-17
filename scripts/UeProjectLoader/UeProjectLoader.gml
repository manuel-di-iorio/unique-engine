/// @description Project Loader - Handles loading project data and assets

function UeProjectLoader() constructor {
    
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
      var assetsDir = projectDir + "assets/";
      
      if (projectData[$ "hierarchy"] == undefined || assetsData == undefined) {
          show_debug_message("Invalid project file format.");
          return;
      }
      
      __loadAssets(projectData, assetsData, assetsDir);
      
      projectManager.markAsSaved();
      show_debug_message("Project loaded successfully!");
    }
    
    /**
     * Load assets from project data
     */
    function __loadAssets(projectData, assetsData, assetsDir) {
      var hierarchy = projectData.hierarchy;
      var assetsLists = assetsData;
      
      // Build folder hierarchy first
      var folderMap = {}; // name -> folder struct
      var treeviewItemMap = {}; // name -> treeviewItem
      
      __buildFolders(hierarchy, folderMap, treeviewItemMap);
      
      // Load root assets and place them in hierarchy
      var assetsByName = {};
      
      __loadAssetsList(assetsLists.textures, assetsDir, "texture", hierarchy, treeviewItemMap, folderMap, assetsByName, sprUiTexture);
      __loadAssetsList(assetsLists.materials, assetsDir, "material", hierarchy, treeviewItemMap, folderMap, assetsByName, sprUiMaterial);
      __loadAssetsList(assetsLists.models, assetsDir, "model", hierarchy, treeviewItemMap, folderMap, assetsByName, sprUiObject);
      __loadAssetsList(assetsLists.scenes, assetsDir, "scene", hierarchy, treeviewItemMap, folderMap, assetsByName, sprUiScene);
      
      // Link references (textures in materials, materials in meshes)
      __linkReferences(assetsByName);
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
          if (entry.type != "FLD") continue;
          
          var folderName = entry.name;
          
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
          oSceneEditor.assetManager.addAsset("folder", folder, parentFolder);
          
          // Process children recursively
          if (entry[$ "children"] != undefined && array_length(entry.children) > 0) {
              __buildFoldersRecursive(entry.children, folder, folderMap, treeviewItemMap);
          }
      }
    }
    
    /**
     * Load a list of assets of the same type
     */
    function __loadAssetsList(assetNames, assetsDir, assetType, hierarchy, treeviewItemMap, folderMap, assetsByName, icon) {
      if (assetNames == undefined) return;
      
      for (var i = 0; i < array_length(assetNames); i++) {
          var assetName = assetNames[i];
          var asset = undefined;
          
          switch (assetType) {
              case "texture":
                  asset = __loadTexture(assetName, assetsDir);
                  break;
              case "material":
                  asset = __loadMaterial(assetName, assetsDir);
                  break;
              case "model":
                  asset = __loadMesh(assetName, assetsDir);
                  break;
              case "scene":
                  asset = __loadScene(assetName, assetsDir);
                  break;
          }
          
          if (asset != undefined) {
              assetsByName[$ assetName] = asset;
              __placeInHierarchy(asset, hierarchy, treeviewItemMap, folderMap, icon);
          }
      }
    }
    
    /**
     * Load a texture asset
     */
    function __loadTexture(assetName, assetsDir) {
        var assetDir = assetsDir + assetName + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        var asset = new UeTexture().fromJSON(metadata);
        asset.name = assetName;
        
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
    function __loadMaterial(assetName, assetsDir) {
        var assetDir = assetsDir + assetName + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        // Convert shader name to asset index
        if (metadata.shader != undefined) {
            metadata.shader = asset_get_index(metadata.shader);
        }
        
        var asset = new UeMaterial().fromJSON(metadata, {});
        asset.name = assetName;
        
        // Store texture names temporarily for linking later
        if (metadata[$ "textures"] != undefined) {
            asset.textures = metadata.textures;
        }
        
        return asset;
    }
    
    /**
     * Load a mesh asset
     */
    function __loadMesh(assetName, assetsDir) {
        var assetDir = assetsDir + assetName + "/";
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
        asset.name = assetName;
        
        // Store material name temporarily for linking later
        if (metadata[$ "material"] != undefined) {
            asset.materialName = metadata.material;
        }
        
        return asset;
    }
    
    /**
     * Load a scene asset
     */
    function __loadScene(assetName, assetsDir) {
      var assetDir = assetsDir + assetName + "/";
        var metadata = __readJson(assetDir + "metadata.json");
        
        if (metadata == undefined) return undefined;
        
        var asset = new UeScene().fromJSON(metadata, {});
        asset.name = assetName;
        
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
        var typeKey = string_lower(asset.type);
        if (typeKey == "mesh") typeKey = "model";
        oSceneEditor.assetManager.addAsset(typeKey, asset, parentFolder);
    }
    
    /**
     * Find parent folder for an asset in hierarchy tree
     */
    function __findAssetParent(assetName, entries, folderMap) {
        for (var i = 0; i < array_length(entries); i++) {
            var entry = entries[i];
            
            // Check if this folder contains the asset
            if (entry.type == "FLD" && entry[$ "children"] != undefined) {
                for (var j = 0; j < array_length(entry.children); j++) {
                    var child = entry.children[j];
                    if (child.name == assetName) {
                        return folderMap[$ entry.name];
                    }
                }
                
                // Search recursively in subfolders
                var found = __findAssetParent(assetName, entry.children, folderMap);
                if (found != undefined) return found;
            }
        }
        
        return undefined;
    }
    
    /**
     * Link asset references
     */
    function __linkReferences(assetsByName) {
        var assetNames = variable_struct_get_names(assetsByName);
        
        for (var i = 0; i < array_length(assetNames); i++) {
            var assetName = assetNames[i];
            var asset = assetsByName[$ assetName];
            
            // Link textures in materials
            if (asset[$ "type"] == "Material" && asset[$ "textures"] != undefined) {
                var textureSlots = variable_struct_get_names(asset.textures);
                for (var j = 0; j < array_length(textureSlots); j++) {
                    var slot = textureSlots[j];
                    var textureName = asset.textures[$ slot];
                    
                    if (is_string(textureName) && textureName != "" && assetsByName[$ textureName] != undefined) {
                        asset.textures[$ slot] = assetsByName[$ textureName];
                    } else {
                        // Remove invalid texture reference
                        asset.textures[$ slot] = undefined;
                    }
                }
                asset.build();
            }
            
            // Link materials in meshes
            if (asset[$ "type"] == "Mesh" && asset[$ "materialName"] != undefined) {
                var materialName = asset.materialName;
                if (assetsByName[$ materialName] != undefined) {
                    asset.material = assetsByName[$ materialName];
                }
                delete asset.materialName;
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

