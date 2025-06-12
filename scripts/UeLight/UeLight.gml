function UeLight(data = {}): UeObject3D(data) constructor {
    isLight = true;
    type = "Light";
    lightType = "Light"
    intensity = data[$ "intensity"] ?? 1;
    enabled = data[$ "enabled"] ?? true;
    range = undefined;
    
    function setColor(_color) {
        color = [color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255];
    }
    
    setColor(data[$ "color"] ?? c_dkgray);
}

function UeAmbientLight(data = {}): UeLight(data) constructor {
    lightType = "AmbientLight"
}

function UeDirectionalLight(xt = 0, yt = 0, zt = 0, data = {}): UeLight(data) constructor {
    lightType = "DirectionalLight";
    target = new UeVector3(xt, yt, zt);
}

function UePointLight(range = 1000, data = {}): UeLight(data) constructor {
    lightType = "PointLight";
    self.range = range;
}

/** @todo: unsupported for now */
//function SpotLight(data = {}): Light(data) constructor {
    //lightType = "SpotLight";
    //range = data[$ "range"] ?? 100;
    //angle = data[$ "angle"] ?? 100;
//}