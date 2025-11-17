/// @description Project Saver - Handles saving project data and assets

function UeProjectSaver() constructor {
    
    /**
     * Save the entire project
     * @param {Struct} projectManager - The project manager instance
     */
    function save(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        var assetsDir = projectDir + "assets/";
        
        // Ensure directories exist
        if (!directory_exists(projectDir)) {
            directory_create(projectDir);
        }
        if (!directory_exists(assetsDir)) {
            directory_create(assetsDir);
        }
        
        // Check if project files exist
        var assetsJsonPath = projectDir + "assets.json";
        var projectJsonPath = projectDir + "project.json";
        var isFirstSave = !file_exists(assetsJsonPath) || !file_exists(projectJsonPath);
        
        if (isFirstSave) {
            // First save: save everything
            __saveAll(projectManager, assetsJsonPath, projectJsonPath, assetsDir);
        } else {
            // Incremental save: save only changes
            __saveIncremental(projectManager, assetsJsonPath, projectJsonPath, assetsDir);
        }
        
        projectManager.markAsSaved();
    }

    /**
     * Save all assets (first save)
     */
    function __saveAll(projectManager, assetsJsonPath, projectJsonPath, assetsDir) {
        // Build project data
        var data = __buildProjectData();
        
        // Save assets list
        __writeJson(assetsJsonPath, data.assets);
        
        // Save project data (hierarchy + settings)
        __writeJson(projectJsonPath, {
            hierarchy: data.hierarchy,
            settings: data.settings
        });
        
        // Save individual asset files
        __saveAllAssets(assetsDir);
    }
    
    /**
     * Save only changed assets (incremental save)
     */
    function __saveIncremental(projectManager, assetsJsonPath, projectJsonPath, assetsDir) {
        // Save changed assets
        __saveChangedAssets(projectManager.changes, assetsDir);
        
        // Rebuild and save project data
        var data = __buildProjectData();
        __writeJson(assetsJsonPath, data.assets);
        __writeJson(projectJsonPath, {
            hierarchy: data.hierarchy,
            settings: data.settings
        });
    }
    
    /**
     * Build the project data structure
     */
    function __buildProjectData() {
      var assetManager = oSceneEditor.assetManager;
      
      // Build hierarchy array (folders and their organization)
      var hierarchy = [];
      __buildHierarchyRecursive(assetManager.folders, undefined, hierarchy);
      
      // Build assets lists (only root-level assets)
      var assets = {
          textures: [],
          materials: [],
          models: [],
          scenes: []
      };
      
      for (var i = 0; i < array_length(assetManager.textures); i++) {
          array_push(assets.textures, assetManager.textures[i].name);
      }
      
      for (var i = 0; i < array_length(assetManager.materials); i++) {
          array_push(assets.materials, assetManager.materials[i].name);
      }
      
      for (var i = 0; i < array_length(assetManager.models); i++) {
          array_push(assets.models, assetManager.models[i].name);
      }
      
      for (var i = 0; i < array_length(assetManager.scenes); i++) {
          array_push(assets.scenes, assetManager.scenes[i].name);
      }
      
      return {
          hierarchy: hierarchy,
          assets: assets,
          settings: {}
      };
    }

    /**
     * Build hierarchy recursively (folders and asset organization)
     */
    function __buildHierarchyRecursive(folders, parentName, hierarchy) {
      for (var i = 0; i < array_length(folders); i++) {
          var folder = folders[i];
          
          var entry = {
              type: "FLD",
              name: folder.name,
              children: []
          };
          
          array_push(hierarchy, entry);
          
          // Process children
          if (folder[$ "children"] != undefined) {
              var childFolders = [];
              for (var j = 0; j < array_length(folder.children); j++) {
                  var child = folder.children[j];
                  if (child[$ "type"] == "Folder") {
                      array_push(childFolders, child);
                  } else {
                      // Add non-folder assets (only textures and materials)
                      var childType = child[$ "type"];
                      if (childType == "Texture" || childType == "Material") {
                          var assetEntry = {
                              type: __getTypePrefix(childType),
                              name: child.name
                          };
                          array_push(entry.children, assetEntry);
                      }
                  }
              }
              
              if (array_length(childFolders) > 0) {
                  __buildHierarchyRecursive(childFolders, folder.name, entry.children);
              }
          }
      }
    }
    
    /**
     * Save all asset files
     */
    function __saveAllAssets(assetsDir) {
      var assetManager = oSceneEditor.assetManager;
      
      for (var i = 0; i < array_length(assetManager.textures); i++) {
          __saveTexture(assetManager.textures[i], assetsDir);
      }
      
      for (var i = 0; i < array_length(assetManager.materials); i++) {
          __saveMaterial(assetManager.materials[i], assetsDir);
      }
      
      for (var i = 0; i < array_length(assetManager.models); i++) {
          __saveMesh(assetManager.models[i], assetsDir);
      }
      
      for (var i = 0; i < array_length(assetManager.scenes); i++) {
          __saveScene(assetManager.scenes[i], assetsDir);
      }
    }
    
    /**
     * Save only changed assets
     */
    function __saveChangedAssets(changes, assetsDir) {
      var uuids = variable_struct_get_names(changes);
      
      for (var i = 0; i < array_length(uuids); i++) {
          var uuid = uuids[i];
          var change = changes[$ uuid];
          var asset = change.asset;
          var action = change.action;
          
          switch (action) {
              case "create":
              case "edit":
                  switch (asset.type) {
                      case "Texture":
                          __saveTexture(asset, assetsDir);
                          break;
                      case "Material":
                          __saveMaterial(asset, assetsDir);
                          break;
                      case "Mesh":
                          __saveMesh(asset, assetsDir);
                          break;
                      case "Scene":
                          __saveScene(asset, assetsDir);
                          break;
                      case "Folder":
                          // Folders don't have files
                          break;
                  }
                  break;
                  
              case "delete":
                  var assetDir = assetsDir + asset.name + "/";
                  if (directory_exists(assetDir)) {
                      directory_destroy(assetDir);
                  }
                  break;
          }
      }
    }
    
    /**
     * Save a texture asset
     */
    function __saveTexture(texture, assetsDir) {
      var assetDir = assetsDir + texture.name + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      // Save metadata
      var metadata = texture.toJSON();
      __writeJson(assetDir + "metadata.json", metadata);
      
      // Save sprite as PNG
      if (texture.sprite != undefined) {
          var spriteSurf = surface_create(sprite_get_width(texture.sprite), sprite_get_height(texture.sprite));
          surface_set_target(spriteSurf);
          draw_clear_alpha(c_black, 0);
          draw_sprite(texture.sprite, 0, 0, 0);
          surface_reset_target();
          surface_save(spriteSurf, assetDir + "texture.png");
          surface_free(spriteSurf);
      }
    }

    /**
     * Save a material asset
     */
    function __saveMaterial(material, assetsDir) {
      var assetDir = assetsDir + material.name + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      var materialData = material.toJSON();
      
      // Add texture references (names instead of objects)
      if (material[$ "textures"] != undefined) {
          materialData.textures = {};
          var texNames = variable_struct_get_names(material.textures);
          for (var i = 0; i < array_length(texNames); i++) {
              var texName = texNames[i];
              var tex = material.textures[$ texName];
              if (tex != undefined) {
                  materialData.textures[$ texName] = tex.name;
              }
          }
      }
      
      __writeJson(assetDir + "metadata.json", materialData);
    }
    
    /**
     * Save a scene asset
     */
    function __saveScene(scene, assetsDir) {
      var assetDir = assetsDir + scene.name + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      var sceneData = scene.toJSON();
      __writeJson(assetDir + "metadata.json", sceneData);
    }
    
    /**
     * Save a mesh asset
     */
    function __saveMesh(mesh, assetsDir) {
      var assetDir = assetsDir + mesh.name + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      var meshData = mesh.toJSON();
      
      // Add geometry data if exists
      if (mesh.geometry != undefined) {
          meshData.geometry = mesh.geometry.toJSON();
      }
      
      __writeJson(assetDir + "metadata.json", meshData);
      
      // Save geometry buffer
      if (mesh[$ "geometry"] != undefined) {
          mesh.geometry.export(assetDir + "geometry.buf");
      }
      
      // Save children recursively
      if (mesh[$ "children"] != undefined) {
          for (var i = 0; i < array_length(mesh.children); i++) {
              __saveMesh(mesh.children[i], assetsDir);
          }
      }
    }
    
    /**
     * Get 3-letter type prefix for an asset
     */
    function __getTypePrefix(assetType) {
      switch(assetType) {
          case "Folder": return "FLD";
          case "Texture": return "TXR";
          case "Material": return "MTL";
          case "Mesh": return "MSH";
          case "Scene": return "SCN";
          case "ModelInstance": return "INS";
          default: return "AST";
      }
    }
    
    /**
     * Write JSON to file
     */
    function __writeJson(filePath, data) {
        var jsonString = json_stringify(data, true);
        var file = file_text_open_write(filePath);
        file_text_write_string(file, jsonString);
        file_text_close(file);
    }
}
