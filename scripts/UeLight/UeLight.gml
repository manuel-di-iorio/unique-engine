function UeLight(data = {}): UeObject3D(data) constructor {
  isLight = true;
  type = "Light";
  lightType = "Light";
  intensity = data[$ "intensity"] ?? 1;
  enabled = data[$ "enabled"] ?? true;
  range = undefined;
  target = undefined;
  
  function setColor(_color) {
    gml_pragma("forceinline");
    color = [color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255];
  }
  
  function toJSON() {
    gml_pragma("forceinline");
    var payload = { 
      uuid,
      type,
      name,
      lightType, 
      intensity, 
      enabled,
      range,
      color,
      px: position[0],
      py: position[1],
      pz: position[2],
    };
    
    if (target != undefined) {
      payload.targetX = target[0];
      payload.targetY = target[1];
      payload.targetZ = target[2];
    }
    
    return payload;
  }

  function fromJSON(data) {
    gml_pragma("forceinline");
    uuid = data[$ "uuid"];
    name = data[$ "name"];
    lightType = data[$ "lightType"];
    intensity = data[$ "intensity"];
    enabled = data[$ "enabled"];
    range = data[$ "range"];
    color = data[$ "color"];
    vec3_set(position, data[$ "px"] ?? 0, data[$ "py"] ?? 0, data[$ "pz"] ?? 0);
    
    if (data[$ "targetX"] != undefined && data[$ "targetY"] != undefined && data[$ "targetZ"] != undefined) {
      target = vec3_create(data[$ "targetX"], data[$ "targetY"], data[$ "targetZ"]);
    }
  }
  
  function _compileData(data) {
    return { payload: toJSON() };
  }
  
  setColor(data[$ "color"] ?? c_white);
}
