function UeLight(data = {}): UeObject3D(data) constructor {
  isLight = true;
  type = "Light";
  lightType = "Light";
  intensity = data[$ "intensity"] ?? 1;
  enabled = data[$ "enabled"] ?? true;
  paramsVersion = 0;
  range = undefined;
  target = undefined;
  
  function setColor(_color) {
    gml_pragma("forceinline");
    color = [color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255];
    paramsVersion++;
  }

  function setIntensity(_intensity) {
    gml_pragma("forceinline");
    intensity = _intensity;
    paramsVersion++;
  }

  function setEnabled(_enabled) {
    gml_pragma("forceinline");
    enabled = _enabled;
    paramsVersion++;
  }
  
  function toJSON() {
    gml_pragma("forceinline");
    
    // If this is a prefab instance, use differential serialization
    if (self[$ "prefab"] != undefined && self.prefab != undefined) {
        var _result = { 
            uuid,
            type,
            name,
            lightType,
            parent: parent ? parent.uuid : undefined,
            children: array_map(children, function (child) { return child.uuid }),
            prefab: self.prefab.uuid,
            __localOverrides,
            px: position[0],
            py: position[1],
            pz: position[2],
        };
        // Only serialize overridden light properties
        if (__localOverrides[$ "intensity"] == true) _result.intensity = intensity;
        if (__localOverrides[$ "enabled"] == true)   _result.enabled = enabled;
        if (__localOverrides[$ "range"] == true)     _result.range = range;
        if (__localOverrides[$ "color"] == true)     _result.color = color;
        if (__localOverrides[$ "gmObject"] == true)  _result.gmObject = gmObject;
        if (__localOverrides[$ "gmLayer"] == true)   _result.gmLayer = gmLayer;
        if (target != undefined) {
            _result.targetX = target[0];
            _result.targetY = target[1];
            _result.targetZ = target[2];
        }
        return _result;
    }
    
    // Standard full serialization
    var payload = { 
      uuid,
      type,
      name,
      lightType, 
      intensity, 
      enabled,
      range,
      color,
      gmObject,
      gmLayer,
      px: position[0],
      py: position[1],
      pz: position[2],
      parent: parent ? parent.uuid : undefined,
      children: array_map(children, function (child) { return child.uuid }),
      prefab: undefined,
      __localOverrides,
      sourcePath: self[$ "sourcePath"],
    };
    
    if (target != undefined) {
      payload.targetX = target[0];
      payload.targetY = target[1];
      payload.targetZ = target[2];
    }
    
    return payload;
  }

  
  function _compileData(data) {
    return { payload: toJSON() };
  }
  
  setColor(data[$ "color"] ?? c_white);
}
