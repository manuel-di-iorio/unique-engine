/// @description Project Saver - Handles saving project data and assets

function UeProjectSaver() constructor {
    
    /**
     * Save the entire project
     * @param {Struct} projectManager - The project manager instance
     */
    function save(projectManager) {
        var projectDir = projectManager.projectDatafiles + "/Unique Project/";
        
        // Ensure directories exist
        if (!directory_exists(projectDir)) {
            directory_create(projectDir);
        }
        
        // Check if project files exist
        var assetsJsonPath = projectDir + "assets.json";
        var projectJsonPath = projectDir + "project.json";
        var isFirstSave = !file_exists(assetsJsonPath) || !file_exists(projectJsonPath);
        
        if (isFirstSave) {
            // First save: save everything
            __saveAll(projectManager, assetsJsonPath, projectJsonPath, projectDir);
        } else {
            // Incremental save: save only changes
            __saveIncremental(projectManager, assetsJsonPath, projectJsonPath, projectDir);
        }
        
        projectManager.markAsSaved();
    }

    /**
     * Save all assets (first save)
     */
    function __saveAll(projectManager, assetsJsonPath, projectJsonPath, projectDir) {
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
        __saveAllAssets(projectDir);
    }
    
    /**
     * Save only changed assets (incremental save)
     */
    function __saveIncremental(projectManager, assetsJsonPath, projectJsonPath, projectDir) {
        // Save changed assets
        __saveChangedAssets(projectManager.changes, projectDir);
        
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
      
      // Add root-level assets (not in folders) to hierarchy
      for (var i = 0; i < array_length(assetManager.textures); i++) {
          var parent = assetManager.textures[i][$ "parent"];
          // Skip if parent is a Folder
          if (parent != undefined && parent[$ "type"] == "Folder") continue;
          
          array_push(hierarchy, { key: "txr/" + assetManager.textures[i].name });
      }
      
      for (var i = 0; i < array_length(assetManager.materials); i++) {
          var parent = assetManager.materials[i][$ "parent"];
          // Skip if parent is a Folder
          if (parent != undefined && parent[$ "type"] == "Folder") continue;
          
          array_push(hierarchy, { key: "mtl/" + assetManager.materials[i].name });
      }
      
      for (var i = 0; i < array_length(assetManager.models); i++) {
          var parent = assetManager.models[i][$ "parent"];
          // Skip if parent is a Folder
          if (parent != undefined && parent[$ "type"] == "Folder") continue;
          
          array_push(hierarchy, { key: "msh/" + assetManager.models[i].name });
      }
      
      for (var i = 0; i < array_length(assetManager.scenes); i++) {
          var parent = assetManager.scenes[i][$ "parent"];
          // Skip if parent is a Folder
          if (parent != undefined && parent[$ "type"] == "Folder") continue;
          
          array_push(hierarchy, { key: "scn/" + assetManager.scenes[i].name });
      }
      
      // Build assets lists (all assets), including those inside folders
      var assets = {
          textures: [],
          materials: [],
          models: [],
          scenes: []
      };

      var allTextures = assetManager.getAllAssetsByType("Texture");
      for (var i = 0; i < array_length(allTextures); i++) {
          array_push(assets.textures, allTextures[i].uuid);
      }

      var allMaterials = assetManager.getAllAssetsByType("Material");
      for (var i = 0; i < array_length(allMaterials); i++) {
          array_push(assets.materials, allMaterials[i].uuid);
      }

      var allModels = assetManager.getAllAssetsByType("Mesh");
      for (var i = 0; i < array_length(allModels); i++) {
          var model = allModels[i];
          // Skip submeshes (children of other meshes) and instances (children of scenes)
          if (model[$ "parent"] != undefined) {
              var parentType = model.parent[$ "type"];
              if (parentType == "Mesh" || parentType == "Scene") {
                  continue;
              }
          }
          array_push(assets.models, model.uuid);
      }

      var allScenes = assetManager.getAllAssetsByType("Scene");
      for (var i = 0; i < array_length(allScenes); i++) {
          array_push(assets.scenes, allScenes[i].uuid);
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
              key: "fld/" + folder.name,
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
                      // Add all non-folder assets to hierarchy as { key: "type/name" }
                      // Mesh and Scene children are saved in their metadata files
                      var typePrefix = __getTypePrefix(child[$ "type"]);
                      var assetEntry = {
                          key: typePrefix + "/" + child.name
                      };
                      array_push(entry.children, assetEntry);
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

      var allTextures = assetManager.getAllAssetsByType("Texture");
      for (var i = 0; i < array_length(allTextures); i++) {
          __saveTexture(allTextures[i], assetsDir);
      }

      var allMaterials = assetManager.getAllAssetsByType("Material");
      for (var i = 0; i < array_length(allMaterials); i++) {
          __saveMaterial(allMaterials[i], assetsDir);
      }

      var allModels = assetManager.getAllAssetsByType("Mesh");
      for (var i = 0; i < array_length(allModels); i++) {
          __saveMesh(allModels[i], assetsDir);
      }

      var allScenes = assetManager.getAllAssetsByType("Scene");
      for (var i = 0; i < array_length(allScenes); i++) {
          __saveScene(allScenes[i], assetsDir);
      }
    }
    
    /**
     * Save only changed assets
     */
    function __saveChangedAssets(changes, projectDir) {
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
                          __saveTexture(asset, projectDir);
                          break;
                      case "Material":
                          __saveMaterial(asset, projectDir);
                          break;
                      case "Mesh":
                          __saveMesh(asset, projectDir);
                          break;
                      case "Scene":
                          __saveScene(asset, projectDir);
                          break;
                      case "Folder":
                          // Folders don't have files
                          break;
                  }
                  break;
                  
              case "delete":
                  var typeFolder = "";
                  switch (asset.type) {
                      case "Texture": typeFolder = "textures/"; break;
                      case "Material": typeFolder = "materials/"; break;
                      case "Mesh": typeFolder = "meshes/"; break;
                      case "Scene": typeFolder = "scenes/"; break;
                  }
                  if (typeFolder != "") {
                      var assetDir = projectDir + typeFolder + asset.uuid + "/";
                      if (directory_exists(assetDir)) {
                          directory_destroy(assetDir);
                      }
                  }
                  break;
          }
      }
    }
    
    /**
     * Save a texture asset
     */
    function __saveTexture(texture, projectDir) {
      var texturesDir = projectDir + "textures/";
      if (!directory_exists(texturesDir)) {
          directory_create(texturesDir);
      }
      
      var assetDir = texturesDir + texture.uuid + "/";
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
    function __saveMaterial(material, projectDir) {
      var materialsDir = projectDir + "materials/";
      if (!directory_exists(materialsDir)) {
          directory_create(materialsDir);
      }
      
      var assetDir = materialsDir + material.uuid + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      var materialData = material.toJSON();
      
      // Add texture references (UUIDs instead of objects)
      if (material[$ "textures"] != undefined) {
          materialData.textures = {};
          var texNames = variable_struct_get_names(material.textures);
          for (var i = 0; i < array_length(texNames); i++) {
              var texName = texNames[i];
              var tex = material.textures[$ texName];
              if (tex != undefined && tex[$ "uuid"] != undefined) {
                  materialData.textures[$ texName] = tex.uuid;
              }
          }
      }
      
      __writeJson(assetDir + "metadata.json", materialData);
    }
    
    /**
     * Save a scene asset
     */
    function __saveScene(scene, projectDir) {
      var scenesDir = projectDir + "scenes/";
      if (!directory_exists(scenesDir)) {
          directory_create(scenesDir);
      }
      
      var assetDir = scenesDir + scene.uuid + "/";
      if (!directory_exists(assetDir)) {
          directory_create(assetDir);
      }
      
      var sceneData = scene.toJSON();
      __writeJson(assetDir + "metadata.json", sceneData);
    }
    
    /**
     * Save a mesh asset
     */
    function __saveMesh(mesh, projectDir, isSubmesh = false) {
      // Only add meshes/ folder for root meshes, not for submeshes
      var baseDir = projectDir;
      if (!isSubmesh) {
          baseDir = projectDir + "meshes/";
          if (!directory_exists(baseDir)) {
              directory_create(baseDir);
          }
      }
      
      var assetDir = baseDir + mesh.uuid + "/";
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
      
      // Save children recursively in subdirectories (mark as submesh)
      if (mesh[$ "children"] != undefined) {
          for (var i = 0; i < array_length(mesh.children); i++) {
              __saveMesh(mesh.children[i], assetDir, true);
          }
      }
    }
    
    /**
     * Get 3-letter type prefix for an asset
     */
    function __getTypePrefix(assetType) {
      switch(assetType) {
          case "Folder": return "fld";
          case "Texture": return "txr";
          case "Material": return "mtl";
          case "Mesh": return "msh";
          case "Scene": return "scn";
          case "ModelInstance": return "ins";
          default: return "ast";
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
