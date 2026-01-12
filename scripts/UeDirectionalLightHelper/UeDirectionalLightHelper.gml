/**
 * @description Helper object to assist with visualizing a DirectionalLight's effect on the scene.
 * This consists of plane and a line representing the light's position and direction.
 */
function UeDirectionalLightHelper(light, size = 1, color = undefined, data = {}): UeObject3D(data) constructor {
    self.light = light;
    self.color = color;
    self.size = size;
    
    // Create the light plane (square representing the light source)
    var _halfSize = size * 0.5;
    var _planeGeometry = new UeLineGeometry();
    _planeGeometry.setPositions([
        -_halfSize,  _halfSize, 0,
         _halfSize,  _halfSize, 0,
         _halfSize, -_halfSize, 0,
        -_halfSize, -_halfSize, 0,
        -_halfSize,  _halfSize, 0
    ]);
    
    var _materialColor = self.color ?? light.color;
    var _planeMaterial = new UeLineBasicMaterial({ color: _materialColor });
    self.lightPlane = new UeLine(_planeGeometry, _planeMaterial);
    self.add(self.lightPlane);
    
    // Create the target line (representing the direction)
    var _targetGeometry = new UeLineGeometry();
    _targetGeometry.setPositions([
        0, 0, 0,
        0, 0, 1 // Will be scaled/rotated in update
    ]);
    
    var _targetMaterial = new UeLineBasicMaterial({ color: _materialColor });
    self.targetLine = new UeLine(_targetGeometry, _targetMaterial);
    self.add(self.targetLine);

    /**
     * Updates the helper to match the position and direction of the light.
     */
    function update() {
        gml_pragma("forceinline");
        
        // Use temporary vectors to avoid allocations and collisions with lookAt
        var _lightPos = global.UE_VEC3_TEMP1;
        var _targetPos = global.UE_VEC3_TEMP2;
        
        // Get world positions for accurate visualization
        light.getWorldPosition(_lightPos);
        light.target.updateWorldMatrix(false, false);
        light.target.getWorldPosition(_targetPos);
        
        // Update helper position to match light position
        vec3_copy(self.position, _lightPos);
      
        // Update helper rotation to face the target
        self.lookAtVec(_targetPos);
        
        // Update color if it changed (and no fixed color was provided)
        if (self.color == undefined) {
            self.lightPlane.material.setColor(light.color);
            self.targetLine.material.setColor(light.color);
        }
        
        // Calculate the distance to target to scale the target line
        var dist = vec3_distance_to(_lightPos, _targetPos);
        self.targetLine.scale[VEC3.z] = dist;
        
        // Mark for matrix update
        self.updateMatrix();
        self.updateMatrixWorld();
        
        return self;
    }
    
    /**
     * Dispose of GPU resources.
     */
    function dispose() {
        gml_pragma("forceinline");
        self.lightPlane.geometry.dispose();
        self.lightPlane.material.dispose();
        self.targetLine.geometry.dispose();
        self.targetLine.material.dispose();
        return self;
    }
}
