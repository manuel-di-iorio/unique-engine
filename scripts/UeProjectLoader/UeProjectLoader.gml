function UeProjectLoader(data = {}) constructor {
  self.autoLoad = data[$ "autoLoad"] ?? true;

  self.models = [];
  self.scenes = [];
  self.textures = [];
  self.materials = [];
  self.assets = {};
  self.scene = new UeScene();
  self.__projectDir = "datafiles/Unique Project/";

  // Load all assets
  function load() {
    var assetsPath = self.__projectDir + "assets.json";
    if (!file_exists(assetsPath)) return;

    // Read the json
    var _assetsMap = self.__readJson(assetsPath);

    // reset
    self.assets = {};
    self.models = [];
    self.scenes = [];
    self.textures = [];
    self.materials = [];

    if (_assetsMap == undefined) return;

    // Case A: flat top-level array of uuids
    if (array_length(_assetsMap) > 0) {
      for (var i = 0; i < array_length(_assetsMap); i++) {
        var uuid = _assetsMap[i];
        self.assets[$ uuid] = { uuid: uuid };
        array_push(self.models, uuid);
      }
    } else {
      // Case B: legacy object with named lists
      if (_assetsMap[$ "assets"] != undefined && array_length(_assetsMap[$ "assets"]) > 0) {
        for (var j = 0; j < array_length(_assetsMap[$ "assets"]); j++) {
          var u = _assetsMap[$ "assets"][j];
          self.assets[$ u] = { uuid: u };
          array_push(self.models, u);
        }
      }

      if (_assetsMap[$ "models"] != undefined) {
        for (var k = 0; k < array_length(_assetsMap[$ "models"]); k++) {
          var m = _assetsMap[$ "models"][k];
          self.assets[$ m] = { uuid: m, type: "model" };
          array_push(self.models, m);
        }
      }
      if (_assetsMap[$ "scenes"] != undefined) {
        for (var s = 0; s < array_length(_assetsMap[$ "scenes"]); s++) {
          var sc = _assetsMap[$ "scenes"][s];
          self.assets[$ sc] = { uuid: sc, type: "scene" };
          array_push(self.scenes, sc);
        }
      }
      if (_assetsMap[$ "textures"] != undefined) {
        for (var t = 0; t < array_length(_assetsMap[$ "textures"]); t++) {
          var tx = _assetsMap[$ "textures"][t];
          self.assets[$ tx] = { uuid: tx, type: "texture" };
          array_push(self.textures, tx);
        }
      }
      if (_assetsMap[$ "materials"] != undefined) {
        for (var mt = 0; mt < array_length(_assetsMap[$ "materials"]); mt++) {
          var mm = _assetsMap[$ "materials"][mt];
          self.assets[$ mm] = { uuid: mm, type: "material" };
          array_push(self.materials, mm);
        }
      }
    }

    self.loaded = true;
  }

  /**
   * Internal: read and parse a JSON file
   */
  function __readJson(path) {
    var bf = buffer_load(path);
    var str = buffer_read(bf, buffer_text);
    buffer_delete(bf);
    return json_parse(str);
  }

	// Get an asset by name
  function getAsset(name) {
		return self.assets[$ name];
  }

  // Alias requested by API
  function getAssetByName(name) {
    return getAsset(name);
  }

	// Add the istances of a sceeSet the current scene by name
  function setScene(a, b) {
    var base_scene;
    var sceneName;
    if (b == undefined) {
      sceneName = a;
      base_scene = undefined;
    } else {
      base_scene = a;
      sceneName = b;
    }

    var _scene = self.assets[$ sceneName];
    if (_scene == undefined) {
      show_error("[Unique Engine] Scene not found: " + sceneName, true);
      return;
    }
  
    show_debug_message("UeProjectLoader: setting scene " + string(sceneName));
    // for (var i = 0; i < _scene.instances.length; i++) {
      //   var instanceData = _scene.instances[i];
      //   log(instanceData);
        
      //   var instanceModel = self.assets[$ instanceData.model];
      
      //   // var instance = new UeMesh(instanceModel);
      //   // instance.position = instanceData.position;
      //   // instance.rotation = instanceData.rotation;
      //   // instance.scale = instanceData.scale;
      //   // self.scene.add(instance);
      // }
      
    // If a base_scene with creation callback is provided, use it
    if (base_scene != undefined && base_scene[$ "create_from_scene_uuid"] != undefined) {
      base_scene[$ "create_from_scene_uuid"](_scene.uuid);
    } else {
      self.scene = _scene;
    }
  }

  if (self.autoLoad) self.load();

  return self;
}

