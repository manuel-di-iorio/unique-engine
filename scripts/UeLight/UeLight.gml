function UeLight(data = {}): UeObject3D(data) constructor {
    isLight = true;
    type = "Light";
    lightType = "Light"
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
            px: position.x,
            py: position.y,
            pz: position.z,
        };
        
        if (target != undefined) {
            payload.targetX = target.x;
            payload.targetY = target.y;
            payload.targetZ = target.z;
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
        position = new UeVector3(data[$ "px"] ?? 0, data[$ "py"] ?? 0, data[$ "pz"] ?? 0);
        
        if (data[$ "targetX"] != undefined && data[$ "targetY"] != undefined && data[$ "targetZ"] != undefined) {
            target = new UeVector3(data[$ "targetX"], data[$ "targetY"], data[$ "targetZ"]);
        }
    }
    
    function _compileData(data) {
        return { payload: toJSON() };
    }
    
    setColor(data[$ "color"] ?? c_white);
}