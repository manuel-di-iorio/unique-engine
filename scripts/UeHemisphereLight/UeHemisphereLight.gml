/// @desc A light source positioned directly above the scene, with color fading from the sky color to the ground color.
/// @param {any} _skyColor
/// @param {any} _groundColor
/// @param {number} _intensity
/// @param {struct} data
function UeHemisphereLight(_skyColor = c_white, _groundColor = c_white, _intensity = 1, data = {}): UeLight(data) constructor {
    isHemisphereLight = true;
    lightType = "HemisphereLight";
    
    self.skyColor = [1, 1, 1];
    self.groundColor = [1, 1, 1];
    
    self.setSkyColor = function(_color) {
        if (is_array(_color)) {
            self.skyColor = _color;
        } else {
            self.skyColor = [
                color_get_red(_color) / 255,
                color_get_green(_color) / 255,
                color_get_blue(_color) / 255
            ];
        }
        return self;
    };
    
    self.setGroundColor = function(_color) {
        if (is_array(_color)) {
            self.groundColor = _color;
        } else {
            self.groundColor = [
                color_get_red(_color) / 255,
                color_get_green(_color) / 255,
                color_get_blue(_color) / 255
            ];
        }
        return self;
    };
    
    self.setSkyColor(_skyColor);
    self.setGroundColor(_groundColor);
    self.intensity = _intensity;
    
    // Position defaults to UP (0, 1, 0) in world space if not specified, 
    // Users should position it to define the axis.
    vec3_set(self.position, 0, 0, 100); 
}
