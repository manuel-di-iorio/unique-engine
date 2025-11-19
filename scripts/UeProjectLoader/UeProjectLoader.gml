
function UeProjectLoader(data = {}) constructor {
    self.autoLoad = data[$ "autoLoad"] ?? true;
    self.uuids = [];
    self.assetsByUUID = {};
    self.scene = new UeScene();
    self.__projectDir = "datafiles/Unique Project/";

    self.load = function() {
        var assetsPath = self.__projectDir + "assets.json";
        if (!file_exists(assetsPath)) {
            show_debug_message("[UeProjectLoader] assets.json non trovato");
            return;
        }
        
        var assetList = self.__readJson(assetsPath);
       
        // Reset
        self.assetsByUUID = {};
        self.uuids = [];
        for (var i = 0; i < array_length(assetList); i++) {
            var entry = assetList[i];
            var uuid = undefined;
            if (is_struct(entry) && entry[$ "uuid"] != undefined) uuid = entry[$ "uuid"];
            else uuid = entry;
            var metaPath = self.__projectDir + "assets/" + uuid + "/metadata.json";
            if (file_exists(metaPath)) {
                var meta = self.__readJson(metaPath);
                if (meta != undefined) {
                    // Ensure uuid is present in metadata
                    meta[$ "uuid"] = meta[$ "uuid"] ?? uuid;
                    self.assetsByUUID[$ uuid] = meta;
                    array_push(self.uuids, uuid);
                }
            } else {
                show_debug_message("[UeProjectLoader] UUID senza metadata: " + string(uuid));
            }
        }
    };

    self.__readJson = function(path) {
        if (!file_exists(path)) return undefined;
        var bf = buffer_load(path);
        var str = buffer_read(bf, buffer_text);
        buffer_delete(bf);
        return json_parse(str);
    };

    self.getAssetByUUID = function(uuid) {
        return self.assetsByUUID[$ uuid];
    };

    self.getAllAssetUUIDs = function() {
        return self.uuids;
    };

    self.setScene = function(sceneUUID) {
        var _scene = self.assetsByUUID[$ sceneUUID];
        if (_scene == undefined || _scene[$ "type"] != "scene") {
            show_error("[Unique Engine] Scene not found: " + string(sceneUUID), true);
            return;
        }
        show_debug_message("[UeProjectLoader] Scene caricata: " + string(sceneUUID));
        self.scene = _scene;
    };

    if (self.autoLoad) self.load();
}

