/**
 * @description Helper object to assist with visualizing a SpotLight's effect on the scene.
 * This consists of a cone mesh for visualizing the spotlight's coverage.
 */
function UeSpotLightHelper(light, color = undefined, data = {}): UeObject3D(data) constructor {
    self.light = light;
    self.color = color;
    
    // Determine initial color
    var _col;
    if (color != undefined) {
        _col = [color_get_red(color) / 255, color_get_green(color) / 255, color_get_blue(color) / 255];
    } else {
        _col = light.color;
    }
    
    // Create the cone mesh
    // The cone in Unique Engine is oriented along X+, tip at (halfHeight, 0, 0), base at (-halfHeight, 0, 0)
    // We want the tip at (0,0,0) and pointing towards the target (+Z axis).
    // So we'll transform the geometry so the tip is at (0,0,0) and it expands along +Z.
    var _geom = new UeConeGeometry(1, 1, 8); // Increased segments for better visualization
    
    // Transform geometry: Tip (0.5, 0, 0) -> (0, 0, 0), Base (-0.5, 0, 0) -> (0, 0, 1)
    for (var i = 0; i < array_length(_geom.position); i += 3) {
        var _px = _geom.position[i];
        var _py = _geom.position[i+1];
        var _pz = _geom.position[i+2];
        
        _geom.position[i]   = _py;
        _geom.position[i+1] = _pz;
        _geom.position[i+2] = 0.5 - _px;
    }
    _geom.build();

    // Using a basic material for the helper
    var _mat = new UeMeshBasicMaterial();
    _mat.wireframe = true;
    _mat.uniforms.ueEmissive.value = _col;
    
    self.cone = new UeMesh(_geom, _mat);
    self.add(self.cone);

    // Inner cone for penumbra
    var _innerGeom = new UeConeGeometry(1, 1, 8);
    for (var i = 0; i < array_length(_innerGeom.position); i += 3) {
        var _px = _innerGeom.position[i];
        var _py = _innerGeom.position[i+1];
        var _pz = _innerGeom.position[i+2];
        
        _innerGeom.position[i]   = _py;
        _innerGeom.position[i+1] = _pz;
        _innerGeom.position[i+2] = 0.5 - _px;
    }
    _innerGeom.build();
    
    var _innerMat = new UeMeshBasicMaterial();
    _innerMat.wireframe = true;
    _innerMat.uniforms.ueEmissive.value = _col;
    _innerMat.opacity = 0.5;
    _innerMat.transparent = true;
    
    self.innerCone = new UeMesh(_innerGeom, _innerMat);
    self.add(self.innerCone);

    /**
     * Updates the helper position, rotation and scale to match the light.
     */
    function update() {
        gml_pragma("forceinline");
        
        // Synchronize position with light
        self.setPosition(light.position[0], light.position[1], light.position[2]);
        
        // Look at the target
        self.lookAt(light.target.position[0], light.target.position[1], light.target.position[2]);
        
        // Scale based on distance and angle
        var _dist = light.distance;
        if (_dist <= 0) _dist = 1000;
        
        var _radius = dtan(light.angle) * _dist;
        
        self.cone.scale[0] = _radius;
        self.cone.scale[1] = _radius;
        self.cone.scale[2] = _dist;
        
        // Update inner cone for penumbra
        if (light.penumbra > 0) {
            self.innerCone.visible = true;
            var _innerAngle = light.angle * (1.0 - light.penumbra);
            var _innerRadius = dtan(_innerAngle) * _dist;
            
            self.innerCone.scale[0] = _innerRadius;
            self.innerCone.scale[1] = _innerRadius;
            self.innerCone.scale[2] = _dist;
        } else {
            self.innerCone.visible = false;
        }
        
        // Synchronize color if not overridden
        if (self.color == undefined) {
            var _c = light.color;
            self.cone.material.uniforms.ueEmissive.value = _c;
            self.innerCone.material.uniforms.ueEmissive.value = _c;
        }
        
        return self;
    }
    
    /**
     * Dispose of GPU resources.
     */
    function dispose() {
        gml_pragma("forceinline");
        if (self.cone != undefined) {
            self.cone.geometry.dispose();
            self.cone.material.dispose();
        }
        if (self.innerCone != undefined) {
            self.innerCone.geometry.dispose();
            self.innerCone.material.dispose();
        }
        return self;
    }
}
