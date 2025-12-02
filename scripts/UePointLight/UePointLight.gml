function UePointLight(range = 1000, data = {}): UeLight(data) constructor {
    lightType = "PointLight";
    self.range = range;
    
    // Shadow support for point lights (omnidirectional shadows)
    shadow = new UePointLightShadow({
        near: data[$ "shadowNear"] ?? 0.5,
        far: data[$ "shadowFar"] ?? range
    });
}