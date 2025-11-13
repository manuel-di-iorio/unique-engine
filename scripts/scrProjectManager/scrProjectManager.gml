function Project() constructor {

  self.path = undefined;
  self.yypPath = undefined;
  self.yypDir = undefined;
  self.datafiles = undefined;
  self.assetsPath = undefined;
  self.uePath = undefined;
  self.ueData = undefined;
  self.gmResources = undefined;
  self.assetsMap = {};

  /// Save the initial ue.json file in the datafiles of the project
  function initUe(yypPath) {
    self.yypPath = yypPath;
    self.yypDir = filename_dir(self.yypPath);
    self.datafiles = self.yypDir + "/datafiles";
    self.assetsPath = self.datafiles + "/ue-assets";
    self.uePath = self.datafiles + "/ue.json";

    // Create ue-assets directories if it doesn't exist
    if (!directory_exists(self.assetsPath)) {
      directory_create(self.assetsPath);
    }

    self.ueData = {
      version: global.UE_VERSION,
      assets: []
    };

    // List of all GM resources names, in order to avoid duplicates
    // Load GM resource names from the .yyp project file to avoid duplicates
    // var _yypData = self.__readYypFile();
    // self.gmResources = {};

    // for (var i = 0, il = array_length(_yypData.resources); i < il; i++) {
    //   var res = _yypData.resources[i];
    //   self.gmResources[$ res.id.name] = true;
    // }

    // Create or read the ue.json file with the initial data
    if (!file_exists(self.uePath)) {
      self.__writeUeFile();
    } else {
      self.__readUeFile();
    }
  }

  /**
   * Writes the ue.json file to the project's datafiles folder
   */
  function __writeUeFile() {
    var jsonStr = json_stringify(self.data);
    var file = file_text_open_write(self.uePath);
    file_text_write_string(file, jsonStr);
    file_text_close(file);
  }

  /**
   * Reads the ue.json file from the project's datafiles folder
   */
  function __readUeFile() {
    var file = file_text_open_read(self.uePath);
    var jsonStr = "";
    while (!file_text_eof(file)) {
      jsonStr += file_text_read_string(file);
    }
    file_text_close(file);
    self.data = json_parse(jsonStr);

    // Svuota la treeview
    var treeview = global.UI.Main.Assets.Treeview;
    treeview.Items.destroyChildren();

    // Helper per creare asset e treeview ricorsivamente
    function createAssetAndTreeview(assetData, parentTreeviewItem) {
      var asset = undefined, icon = undefined;
      switch (assetData.type) {
        case "texture":
          asset = new UeTexture();
          icon = sprUiTexture;
          break;
        case "material":
          asset = new UeMaterial();
          icon = sprUiMaterial;
          break;
        case "mesh":
          asset = new UeMesh();
          icon = sprUiObject;
          break;
        case "scene":
          asset = new UeScene();
          icon = sprUiScene;
          break;
      }
      if (asset == undefined) return;

      // asset.fromJSON(assetData);

      // Crea l'item nella treeview
      var treeviewItem = __editorTreeview_createTreeviewItem(asset, parentTreeviewItem, icon);

      // Gestione children per mesh e scene
      if (assetData.children != undefined) {
        for (var i = 0, il = array_length(assetData.children); i < il; i++) {
          createAssetAndTreeview(assetData.children[i], treeviewItem);
        }
      }
      // Gestione modelinstances per scene
      if (assetData.modelinstances != undefined) {
        for (var j = 0, jl = array_length(assetData.modelinstances); j < jl; j++) {
          createAssetAndTreeview(assetData.modelinstances[j], treeviewItem);
        }
      }
    }

    // Carica tutti gli asset per tipo
    var assetsByType = self.data.assets;
    var types = ["texture", "material", "mesh", "scene"];

    for (var t = 0, tl = array_length(types); t < tl; t++) {
      var type = types[t];

      if (assetsByType[$ type] == undefined) continue;
      var assetList = variable_struct_get_names(assetsByType[$ type]);

      for (var a = 0, al = array_length(assetList); a < al; a++) {
        var assetName = assetList[a];
        var assetData = assetsByType[$ type][$ assetName];
        
        // In free mode, add directly to root Items
        var parentTreeviewItem = { Items: treeview.Items, treeview: treeview };
        
        createAssetAndTreeview(assetData, parentTreeviewItem);
      }
    }
  }

  /**
   * Reads the .yyp project file and returns its data as a JSON object
   */
  // function __readYypFile() {
  //   var yypPath = self.path;
  //   var file = file_text_open_read(yypPath);
  //   var jsonStr = "";
  //   while (!file_text_eof(file)) {
  //     jsonStr += file_text_read_string(file);
  //   }
  //   file_text_close(file);
  //   return json_parse(jsonStr);
  // }

  /**
   * Checks if a resource name is available (not already used in the project)
   */
  // function isResourceNameAvailable(_name) {
  //   return self.gmResources[$ _name] == undefined;
  // }

  /**
   * Adds an UE asset to the ue.json file
   */
  function addAsset(_type, _assetData) {
    if (!self.isResourceNameAvailable(_assetData.name)) {
      show_message_async("There is already a GM resource with the name '" + _assetData.name + "'. Please rename it to avoid conflicts.");
      return;
    }

    self.gmResources[$ _assetData.name] = true;
    self.data.assets[$ _type][$ _assetData.name] = _assetData;
    self.__writeUeFile();
  }

  /**
   * Deletes an UE asset from the ue.json file
   */
  function deleteAsset(_type, _assetName) {
    delete self.gmResources[$ _assetName];
    delete self.data.assets[$ _type][$ _assetName];
    self.__writeUeFile();
  }

  /**
   * Updates an existing UE asset in the ue.json file
   */
  function updateAsset(_type, _assetData) {
    self.data.assets[$ _type][$ _assetData.name] = _assetData;
    self.__writeUeFile();
  }

  /** 
   * Returns a single asset struct by type and name (or undefined)
   */
  function getAsset(_type, _name) {
    return self.data.assets[$ _type][$ _name];
  }
}
