function ProjectManager() constructor {
  self.loaded = false;
  self.changes = {}; // Struct con UUID come chiave
  self.hasUnsavedChanges = false;
  self.projectPath = "";           // Full path to .yyp file
  self.projectLocation = "";       // Directory containing the .yyp
  self.projectDatafiles = "";      // Path to datafiles folder
  self.projectName = "Untitled";
  
  function setProjectPath(path) {
    self.projectPath = path;
    self.projectLocation = filename_path(path);
    self.projectDatafiles = self.projectLocation + "datafiles";
    
    var projectName = filename_name(path);
    projectName = string_copy(projectName, 1, string_length(projectName) - 4);
    self.projectName = projectName;
    
    self.updateWindowCaption();
  }
  
  /**
   * Update window caption with unsaved changes indicator
   */
  function updateWindowCaption() {
    var caption = self.projectName;
    if (self.hasUnsavedChanges) {
      caption += "*";
    }
    caption += " - Unique Engine";
    window_set_caption(caption);
  }

  /**
   * Save the entire project
   */
  function save() {
    // Create project directory structure
    var projectDir = self.projectDatafiles + "/Unique Project/";
    var assetsDir = projectDir + "assets/";
    
    // Ensure directories exist
    if (!directory_exists(projectDir)) {
      directory_create(projectDir);
    }
    if (!directory_exists(assetsDir)) {
      directory_create(assetsDir);
    }
    
    // Check if ue.json exists - if not, save everything
    var ueJsonPath = projectDir + "ue.json";
    var isFirstSave = !file_exists(ueJsonPath);
    
    if (isFirstSave) {
      // First save: save everything
      // Build project hierarchy
      var projectData = __buildProjectHierarchy();
      
      // Save main project file
      var projectJson = json_stringify(projectData, true);
      var projectFile = file_text_open_write(ueJsonPath);
      file_text_write_string(projectFile, projectJson);
      file_text_close(projectFile);
      
      // Save individual assets
      __saveAssets(assetsDir);
    } else {
      // Incremental save: save only changes
      __saveChanges(assetsDir);
      
      // Rebuild and save the hierarchy with current state
      var projectData = __buildProjectHierarchy();
      var projectJson = json_stringify(projectData, true);
      var projectFile = file_text_open_write(ueJsonPath);
      file_text_write_string(projectFile, projectJson);
      file_text_close(projectFile);
    }
    
    self.markAsSaved();
  }
  
  /**
   * Build the project hierarchy structure
   */
  function __buildProjectHierarchy() {
    var assetManager = oSceneEditor.assetManager;
    var hierarchy = [];
    var addedAssets = {}; // Track already added assets by name to avoid duplicates
    
    // Add folders first (they will recursively add their children)
    for (var i = 0; i < array_length(assetManager.folders); i++) {
      __addAssetRecursive(assetManager.folders[i], undefined, hierarchy);
      __markAssetsAsAdded(assetManager.folders[i], addedAssets);
    }
    
    // Add root assets (skip if already added by folder)
    for (var i = 0; i < array_length(assetManager.textures); i++) {
      var asset = assetManager.textures[i];
      if (addedAssets[$ asset.name] == undefined) {
        __addAssetRecursive(asset, undefined, hierarchy);
      }
    }
    for (var i = 0; i < array_length(assetManager.materials); i++) {
      var asset = assetManager.materials[i];
      if (addedAssets[$ asset.name] == undefined) {
        __addAssetRecursive(asset, undefined, hierarchy);
      }
    }
    for (var i = 0; i < array_length(assetManager.models); i++) {
      var asset = assetManager.models[i];
      if (addedAssets[$ asset.name] == undefined) {
        __addAssetRecursive(asset, undefined, hierarchy);
      }
    }
    for (var i = 0; i < array_length(assetManager.scenes); i++) {
      var asset = assetManager.scenes[i];
      if (addedAssets[$ asset.name] == undefined) {
        __addAssetRecursive(asset, undefined, hierarchy);
      }
    }
    
    return {
      version: global.UE_VERSION,
      assets: hierarchy,
      settings: {
        // Project settings can go here
      }
    };
  }
  
  /**
   * Save individual asset files
   */
  function __saveAssets(assetsDir) {
    var assetManager = oSceneEditor.assetManager;
    
    // Save textures (as sprites)
    for (var i = 0; i < array_length(assetManager.textures); i++) {
      var texture = assetManager.textures[i];
      __saveTexture(texture, assetsDir);
    }
    
    // Save materials
    for (var i = 0; i < array_length(assetManager.materials); i++) {
      var material = assetManager.materials[i];
      __saveMaterial(material, assetsDir);
    }
    
    // Save models (meshes)
    for (var i = 0; i < array_length(assetManager.models); i++) {
      var model = assetManager.models[i];
      __saveMesh(model, assetsDir);
    }
    
    // Save scenes
    for (var i = 0; i < array_length(assetManager.scenes); i++) {
      var scene = assetManager.scenes[i];
      __saveScene(scene, assetsDir);
    }
  }
  
  /**
   * Save only changed assets (incremental save)
   */
  function __saveChanges(assetsDir) {
    var uuids = variable_struct_get_names(self.changes);
    
    for (var i = 0; i < array_length(uuids); i++) {
      var uuid = uuids[i];
      var change = self.changes[$ uuid];
      var asset = change.asset;
      var action = change.action;
      
      switch (action) {
        case "create":
        case "edit":
          // Save or update the asset
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
              // Folders don't have files, just hierarchy in ue.json
              break;
          }
          break;
          
        case "delete":
          // Delete the asset directory
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
    
    // Save texture metadata
    var metadata = texture.toJSON();
    
    var metadataJson = json_stringify(metadata, true);
    var metadataFile = file_text_open_write(assetDir + "metadata.json");
    file_text_write_string(metadataFile, metadataJson);
    file_text_close(metadataFile);
    
    // Save sprite as PNG if exists
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
    
    // Save material data
    var materialData = material.toJSON();
    
    // Add texture references
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
    
    var materialJson = json_stringify(materialData, true);
    var materialFile = file_text_open_write(assetDir + "metadata.json");
    file_text_write_string(materialFile, materialJson);
    file_text_close(materialFile);
  }
  
  /**
   * Save a scene asset
   */
  function __saveScene(scene, assetsDir) {
    var assetDir = assetsDir + scene.name + "/";
    if (!directory_exists(assetDir)) {
      directory_create(assetDir);
    }
    
    // Save scene metadata
    var sceneData = scene.toJSON();
    
    var sceneJson = json_stringify(sceneData, true);
    var sceneFile = file_text_open_write(assetDir + "metadata.json");
    file_text_write_string(sceneFile, sceneJson);
    file_text_close(sceneFile);
  }
  
  /**
   * Save a mesh asset recursively
   */
  function __saveMesh(mesh, assetsDir) {
    var assetDir = assetsDir + mesh.name + "/";
    if (!directory_exists(assetDir)) {
      directory_create(assetDir);
    }
    
    // Save mesh metadata
    var meshData = mesh.toJSON();
    
    var meshJson = json_stringify(meshData, true);
    var meshFile = file_text_open_write(assetDir + "metadata.json");
    file_text_write_string(meshFile, meshJson);
    file_text_close(meshFile);
    
    // Save geometry buffer if exists
    if (mesh.geometry != undefined && mesh.geometry[$ "export"] != undefined) {
      mesh.geometry.export(assetDir + "geometry.buf");
    }
    
    // Save children recursively
    if (mesh[$ "children"] != undefined) {
      for (var i = 0; i < array_length(mesh.children); i++) {
        __saveMesh(mesh.children[i], assetsDir);
      }
    }
  }
  
  function markAsSaved() {
    self.hasUnsavedChanges = false;
    self.changes = {};
    self.updateWindowCaption();
  }

  function markAsUnsaved() {
    self.hasUnsavedChanges = true;
    self.updateWindowCaption();
  }

  function clear() {
    self.changes = {};
    self.hasUnsavedChanges = false;
  }

  function clearProject() {
    var ui = global.UI.Main;
    self.clear();
    oSceneEditor.assetManager.clear();
    oSceneEditor.editorManager.clear();
    oSceneEditor.sceneManager.clear();
    ui.Inspector.destroy();
    ui.Assets.destroy();
    ui.Scene.destroy();
    // ui.SceneTools.destroy();
  }
  
  /**
   * Load project from ue.json
   */
  function load() {
    var projectDir = self.projectDatafiles + "/Unique Project/";
    var ueJsonPath = projectDir + "ue.json";
    
    // Check if ue.json exists
    if (!file_exists(ueJsonPath)) {
      show_debug_message("No ue.json found. Project path set, but no assets to load.");
      return;
    }
    
    // Read and parse ue.json
    var file = file_text_open_read(ueJsonPath);
    var jsonString = "";
    while (!file_text_eof(file)) {
      jsonString += file_text_read_string(file);
      file_text_readln(file);
    }
    file_text_close(file);
    
    var projectData = json_parse(jsonString);
    
    if (projectData == undefined || projectData[$ "assets"] == undefined) {
      show_debug_message("Invalid project file format.");
      return;
    }
    
    // Load assets
    var assetsDir = projectDir + "assets/";
    __loadAssets(projectData.assets, assetsDir);
    
    self.markAsSaved();
    show_debug_message("Project loaded successfully!");
  }
  
  /**
   * Load assets from hierarchy
   */
  function __loadAssets(assetsHierarchy, assetsDir) {
    for (var i = 0; i < array_length(assetsHierarchy); i++) {
      var assetEntry = assetsHierarchy[i];
      __loadAssetRecursive(assetEntry, assetsDir, undefined);
    }
  }
  
  /**
   * Recursively load an asset and its children
   */
  function __loadAssetRecursive(assetEntry, assetsDir, parentTreeviewItem) {
    var assetName = assetEntry.name;
    var assetPath = assetEntry[$ "path"];
    
    if (assetPath == undefined) return;
    
    // Parse type from path (e.g., "FLD:Folder1" -> "FLD")
    var colonPos = string_pos(":", assetPath);
    if (colonPos == 0) return;
    
    var lastSlashPos = string_last_pos("/", assetPath);
    var pathPart = lastSlashPos > 0 ? string_copy(assetPath, lastSlashPos + 1, string_length(assetPath)) : assetPath;
    
    var typePrefix = string_copy(pathPart, 1, colonPos - 1);
    var assetType = "";
    
    switch(typePrefix) {
      case "FLD": assetType = "Folder"; break;
      case "TXR": assetType = "Texture"; break;
      case "MTL": assetType = "Material"; break;
      case "MSH": assetType = "Mesh"; break;
      case "SCN": assetType = "Scene"; break;
      default: return;
    }
    
    // Load asset data from file
    var assetDir = assetsDir + assetName + "/";
    var metadataPath = assetDir + "metadata.json";
    
    var asset = undefined;
    var treeviewItem = undefined;
    
    if (assetType == "Folder") {
      // Create folder struct
      asset = {
        type: "Folder",
        name: assetName,
        uuid: ueUuid(),
        children: [],
        // @todo missing add method?
      };
      
      // Add to treeview
      var treeview = global.UI.Main.Assets.Treeview;
      var icon = sprUiFolder;
      
      treeviewItem = new UiTreeviewItem({ 
        name: "UiTreeview.Item", 
        paddingVertical: 2.5 
      }, {
        treeview: parentTreeviewItem != undefined ? parentTreeviewItem.treeview : treeview,
        name: assetName,
        assetType: "Folder",
        type: "Folder",
        icon,
        asset
      });
      
      if (parentTreeviewItem != undefined) {
        parentTreeviewItem.addChild(treeviewItem);
      } else {
        treeview.Items.add(treeviewItem);
      }
      
      // Add to asset manager
      var parentAsset = parentTreeviewItem != undefined ? parentTreeviewItem.asset : undefined;
      oSceneEditor.assetManager.addAsset("folder", asset, parentAsset);
      
    } else if (file_exists(metadataPath)) {
      // Load metadata
      var metaFile = file_text_open_read(metadataPath);
      var metaJson = "";
      while (!file_text_eof(metaFile)) {
        metaJson += file_text_read_string(metaFile);
        file_text_readln(metaFile);
      }
      file_text_close(metaFile);
      
      var metadata = json_parse(metaJson);
      
      // Create asset based on type
      switch(assetType) {
        case "Texture":
          asset = new UeTexture(undefined, metadata);
          asset.name = assetName;
          
          // Load sprite if exists
          // @todo implement import() and export()
          var texturePath = assetDir + "texture.png";
          if (file_exists(texturePath)) {
            var loadedSprite = sprite_add(texturePath, 1, false, false, 0, 0);
            if (loadedSprite != -1) {
              asset.sprite = loadedSprite;
              asset.__cachedSprite = loadedSprite;
              asset.__cachedTexture = sprite_get_texture(loadedSprite, 0);
            }
          }
          break;
          
        case "Material":
          log(metadata)
          asset = new UeMaterial(metadata);
          asset.name = assetName;
          // Textures will be linked after all assets are loaded
          break;
          
        case "Mesh":
          asset = new UeMesh(undefined, undefined, metadata);
          asset.name = assetName;
          
          // Load geometry if exists
          var geometryPath = assetDir + "geometry.buf";
          if (file_exists(geometryPath)) {
            asset.geometry = new UeBufferGeometry();
            // import() @todo
            // asset.geometry.load(geometryPath);
          }
          break;
          
        case "Scene":
          asset = new UeScene(metadata);
          asset.name = assetName;
          break;
      }
      
      if (asset != undefined) {
        // Add to treeview
        var treeview = global.UI.Main.Assets.Treeview;
        var icon = undefined;
        
        switch(assetType) {
          case "Texture": icon = sprUiTexture; break;
          case "Material": icon = sprUiMaterial; break;
          case "Mesh": icon = sprUiObject; break;
          case "Scene": icon = sprUiScene; break;
        }
        
        treeviewItem = new UiTreeviewItem({ 
          name: "UiTreeview.Item", 
          paddingVertical: 2.5 
        }, {
          treeview: parentTreeviewItem != undefined ? parentTreeviewItem.treeview : treeview,
          assetType: assetType,
          type: assetType,
          icon: icon,
          asset: asset
        });
        
        if (parentTreeviewItem != undefined) {
          parentTreeviewItem.addChild(treeviewItem);
        } else {
          treeview.Items.add(treeviewItem);
        }
        
        // Add to asset manager
        var typeKey = string_lower(assetType);
        if (typeKey == "mesh") typeKey = "model";
        var parentAsset = parentTreeviewItem != undefined ? parentTreeviewItem.asset : undefined;
        oSceneEditor.assetManager.addAsset(typeKey, asset, parentAsset);
      }
    }
    
    // Recursively load children (if they exist in the hierarchy)
    // Children are inline in the assets array, we need to find them
    // For now, we skip this as the hierarchy is flat
  }
}

// ============== HELPER FUNCTIONS ==============

/**
 * Create asset entry for hierarchy
 * @param {Struct} asset - The asset to create entry for
 * @param {String} parentPath - Parent path (e.g., "FLD+test" or "MSH+Cat")
 */
function __createAssetEntry(asset, parentPath) {
  // Get type prefix (3-letter codes)
  var typePrefix = "";
  switch(asset.type) {
    case "Folder": typePrefix = "FLD"; break;
    case "Texture": typePrefix = "TXR"; break;
    case "Material": typePrefix = "MTL"; break;
    case "Mesh": typePrefix = "MSH"; break;
    case "Scene": typePrefix = "SCN"; break;
    case "ModelInstance": typePrefix = "INS"; break;
    default: typePrefix = "AST"; break;
  }
  
  // Build path with type prefix
  var path = "";
  if (parentPath == undefined) {
    // Root level: type+name
    path = typePrefix + ":" + asset.name;
  } else {
    // Child: parentPath/type+name (+ only for type prefix)
    path = parentPath + "/" + typePrefix + ":" + asset.name;
  }
  
  var entry = {
    name: asset.name
  };
  
  // Only include path if not empty
  if (path != "") {
    entry.path = path;
  }
  
  return entry;
}

/**
 * Recursive function to add asset and children to hierarchy
 * @param {Struct} asset - The asset to add
 * @param {String} parentPath - Parent path (e.g., "folder1/folder2")
 * @param {Array} hierarchy - Array to add entries to
 */
function __addAssetRecursive(asset, parentPath, hierarchy) {
  var entry = __createAssetEntry(asset, parentPath);
  array_push(hierarchy, entry);
  
  // Add children recursively with updated path
  if (asset[$ "children"] != undefined) {
    var currentPath = entry.path;
    for (var i = 0; i < array_length(asset.children); i++) {
      __addAssetRecursive(asset.children[i], currentPath, hierarchy);
    }
  }
}

/**
 * Mark asset and its children as already added (recursive)
 * @param {Struct} asset - The asset to mark
 * @param {Struct} addedAssets - Map of added asset names
 */
function __markAssetsAsAdded(asset, addedAssets) {
  addedAssets[$ asset.name] = true;
  
  if (asset[$ "children"] != undefined) {
    for (var i = 0; i < array_length(asset.children); i++) {
      __markAssetsAsAdded(asset.children[i], addedAssets);
    }
  }
}
