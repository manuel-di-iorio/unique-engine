/// @desc Helper object to assist with visualizing a UeHemisphereLight.
/// @param {UeHemisphereLight} _light
/// @param {number} _size
/// @param {struct} data
function UeHemisphereLightHelper(_light, _size = 1, data = {}): UeObject3D(data) constructor {
    light = _light;
    size = _size;
    
    // Create a sphere or diamond-like mesh to represent the light
    // For simplicity, we use a sphere with two colors if possible, 
    // but here we'll use a basic sphere and update its colors in the shader or just use a simple wireframe.
    var geo = new UeSphereGeometry(size, 8, 8);
    var mat = new UeMeshBasicMaterial({ wireframe: true });
    mesh = new UeMesh(geo, mat);
    self.add(mesh);
    
    static update = function() {
        // Sync position and rotation with the light
        vec3_copy(self.position, light.position);
        vec3_copy(self.rotation, light.rotation);
        
        // Update color based on sky color
        mesh.material.color = [light.skyColor[0], light.skyColor[1], light.skyColor[2]];
        return self;
    }
}
