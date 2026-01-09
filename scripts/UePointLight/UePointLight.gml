/**
 * @description A light that gets emitted from a single point in all directions.
 * @param {Real|Array} [_color=c_white] The light's color.
 * @param {Real} [_intensity=1] The light's strength/intensity.
 * @param {Real} [_distance=0] Maximum range of the light. 0 means no limit.
 * @param {Real} [_decay=2] The amount the light dims along the distance of the light.
 * @param {Struct} [data={}] Additional configuration data.
 */
function UePointLight(_color = c_white, _intensity = 1, _distance = 0, _decay = 2, data = {}): UeLight(data) constructor {
    isPointLight = true;
    lightType = "PointLight";
    
    self.setColor(_color);
    self.intensity = _intensity;
    self.distance = _distance;
    self.decay = _decay;

    /**
     * @property {Real} power The light's power measured in lumens.
     * Changing the power will also change the light's intensity.
     */
    static getPower = function() {
        return self.intensity * 4 * pi;
    };
    
    static setPower = function(_power) {
        self.intensity = _power / (4 * pi);
    };

    // Shadow support for point lights (omnidirectional shadows)
    shadow = new UePointLightShadow({
        near: data[$ "shadowNear"] ?? 1,
        far: data[$ "shadowFar"] ?? (self.distance == 0 ? 1000 : self.distance)
    });
}
