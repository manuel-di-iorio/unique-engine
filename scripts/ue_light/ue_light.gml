function Light(data = {}): Object3D(data) constructor {
    type = "Light";
    lightType = "Light"
    intensity = data[$ "intensity"] ?? 1;
    enabled = data[$ "enabled"] ?? true;
    range = undefined;
    
    function setColor(_color) {
        color = [color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255];
    }
    
    function render() {  
        
    }
    
    setColor(data[$ "color"] ?? c_dkgray);
}

function AmbientLight(data = {}): Light(data) constructor {
    lightType = "AmbientLight"
}

function DirectionalLight(data = {}): Light(data) constructor {
    lightType = "DirectionalLight";
    target = new Vec3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
}

function PointLight(data = {}): Light(data) constructor {
    lightType = "PointLight";
    range = data[$ "range"] ?? 2000;
}

/** @todo: unsupported for now */
//function SpotLight(data = {}): Light(data) constructor {
    //lightType = "SpotLight";
    //range = data[$ "range"] ?? 100;
    //angle = data[$ "angle"] ?? 100;
//}