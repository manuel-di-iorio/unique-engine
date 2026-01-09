/**
 * @description Helper object to assist with visualizing a PointLight's effect on the scene.
 * This consists of an octahedron mesh for visualizing an instance of PointLight.
 */
function UePointLightHelper(light, sphereSize = 1, color = undefined, data = {}): UeObject3D(data) constructor {
    self.light = light;
    self.color = color;
    self.sphereSize = sphereSize;
    
    // Determine initial color
    var _col;
    if (color != undefined) {
        _col = [color_get_red(color) / 255, color_get_green(color) / 255, color_get_blue(color) / 255];
    } else {
        _col = light.color;
    }
    
    // Create the octahedron mesh (two opposite pyramids)
    // We use a UeOctahedronGeometry as requested
    var _geom = new UeOctahedronGeometry(sphereSize, 0);
    
    // Using a basic material for the helper (self-illuminated, no light interaction)
    var _mat = new UeMeshBasicMaterial();
    _mat.wireframe = true;
    _mat.uniforms.ueEmissive.value = _col;
    
    self.mesh = new UeMesh(_geom, _mat);
    self.add(self.mesh);

    /**
     * Updates the helper position and color to match the light.
     */
    function update() {
        gml_pragma("forceinline");
        
        // Synchronize position with light
        self.setPosition(light.position[0], light.position[1], light.position[2]);
        
        // Synchronize color if not overridden by the helper itself
        if (self.color == undefined) {
            self.mesh.material.uniforms.ueEmissive.value = light.color;
        }
        
        return self;
    }
    
    /**
     * Dispose of GPU resources.
     */
    function dispose() {
        gml_pragma("forceinline");
        if (self.mesh != undefined) {
            self.mesh.geometry.dispose();
            self.mesh.material.dispose();
        }
        return self;
    }
}
