function Project() constructor {

  self.path = undefined;
  self.yypPath = undefined;
  self.projectPath = undefined;
  self.projectDatafiles = undefined;
  self.uePath = undefined;
  self.data = undefined;
  self.gmResources = undefined;

  /// Save the initial ue.json file in the datafiles of the project
  function initUe(yypPath) {
    self.yypPath = yypPath;
    self.projectPath = filename_dir(self.yypPath);
    self.projectDatafiles = self.path + "/datafiles";
    self.uePath = self.projectDatafiles + "/ue.json";

    self.data = {
      version: global.UE_VERSION,
      assets: {
        textures: {},
        materials: {},
        models: {},
        lights: {},
        cameras: {},
        scenes: {}
      }
    };

    // List of all GM resources names, in order to avoid duplicates
    // Load GM resource names from the .yyp project file to avoid duplicates
    var _yypData = self.__readYypFile();
    self.gmResources = {};

    for (var i = 0, il = array_length(_yypData.resources); i < il; i++) {
      var res = _yypData.resources[i];
      self.gmResources[$ res.id.name] = true;
    }

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
  }

  /**
   * Reads the .yyp project file and returns its data as a JSON object
   */
  function __readYypFile() {
    var yypPath = self.path;
    var file = file_text_open_read(yypPath);
    var jsonStr = "";
    while (!file_text_eof(file)) {
      jsonStr += file_text_read_string(file);
    }
    file_text_close(file);
    return json_parse(jsonStr);
  }

  /**
   * Checks if a resource name is available (not already used in the project)
   */
  function isResourceNameAvailable(_name) {
    return self.gmResources[$ _name] == undefined;
  }

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
