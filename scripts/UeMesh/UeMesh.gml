function UeMesh(geometry = undefined, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry ?? data[$ "geometry"];
    self.material = data[$ "material"] ?? new UeMeshStandardMaterial();
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    
    function render(renderState) {
        var scene = renderState.scene;
        var lightState = renderState.lightState;
        
        if (scene.matrixAutoUpdate && matrixAutoUpdate) {
            update();
        }
        
        if (visible && geometry) {
            matrix_set(matrix_world, matrixWorld.data);
            material.use(renderState, self);
            vertex_submit(geometry.vb, primitive, material.textures[$ "map"] ?? -1);
            shader_reset();
        }
    }
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        var payload = {
            children: array_map(children, function(child) { return child.uuid }),
            // Props:
            visible,
            parent: parent && !parent[$ "isScene"] ? parent.uuid : undefined,
            renderOrder,
            geometry: geometry ? geometry.uuid : undefined,
            material: material ? material.uuid : undefined,
            
            px: position.x,
            py: position.y,
            pz: position.z,
            
            rx: rotation.x,
            ry: rotation.y,
            rz: rotation.z, 
            rw: rotation.w,
            
            sx: scale.x,
            sy: scale.y,
            sz: scale.z,
            
            ux: up.x,
            uy: up.y,
            uz: up.z,
        };
        
        return { obj: _self, payload };
    }
    
    // @todo This is a very simplified version of the actual implementation
    // @MissingDoc
    function raycast(raycaster, intersects) {
        var object = self;
        var _ray = raycaster.ray;
        
        if (geometry.boundingBox != undefined) {
			if (!_ray.intersectsBox(geometry.boundingBox)) return;
                
            array_push(intersects, {
                object
            });
		} else if (geometry.boundingSphere != undefined) {
			if (!_ray.intersectsSphere(geometry.boundingSphere)) return;
                
            array_push(intersects, {
                object
            });
		}
    }
}