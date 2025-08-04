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
    
    function _compileData(data) {
        return { payload: toJSON() };
    }
    
    setColor(data[$ "color"] ?? c_white);
}

function UeAmbientLight(_color = c_white, data = {}): UeLight(data) constructor {
    lightType = "AmbientLight";
    setColor(_color);
}

// yaw = horizontal degrees
// pitch = vertical degrees
// 0,0 = forward direction by default (0,1,0)
function UeDirectionalLight(horizontal = 0, vertical = 0, data = {}): UeLight(data) constructor {
    lightType = "DirectionalLight";
    target = new UeVector3();
    
    function setDirection(horizontal = 0, vertical = 0) {
        // Base forward vector
        var xx = 0;
        var yy = 1;
        var zz = 0;
    
        // First: rotate around X (pitch)
        var y1 = yy * dcos(vertical) - zz * dsin(vertical);
        var z1 = yy * dsin(vertical) + zz * dcos(vertical);
        var x1 = xx;
    
        // Second: rotate around Z (yaw)
        var x2 = x1 * dcos(horizontal) - y1 * dsin(horizontal);
        var y2 = x1 * dsin(horizontal) + y1 * dcos(horizontal);
        var z2 = z1;
    
        target.set(x2, z2, y2);
        
        
        // Base forward vector
        //var dir = new UeVector3(0, 1, 0);
    //
        //// First: rotate around X (pitch)
        //dir.applyAxisAngle(new UeVector3(1, 0, 0), vertical);
    //
        //// Second: rotate around Z (yaw)  
        //dir.applyAxisAngle(new UeVector3(0, 0, 1), horizontal);
    //
        //target.copy(new UeVector3(0, 1, 0)
            //.applyAxisAngle(new UeVector3(1, 0, 0), vertical)
            //.applyAxisAngle(new UeVector3(0, 0, 1), horizontal)
        //);
    }
    
    setDirection(horizontal, vertical)
}

function UePointLight(range = 1000, data = {}): UeLight(data) constructor {
    lightType = "PointLight";
    self.range = range;
}
