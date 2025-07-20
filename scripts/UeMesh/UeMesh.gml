function UeMesh(geometry = undefined, material = undefined, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry;
    self.material = material ?? new UeMeshStandardMaterial();
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    
    function render(renderState) {
        matrix_set(matrix_world, matrixWorld.data);
        material.use(renderState, self);
        vertex_submit(geometry.vb, material.wireframe ? pr_linelist : primitive, -1);
        shader_reset();
    }
    
    // @MissingDoc
    function toJSON() {
        return {
            children: array_map(children, function(child) { return child.uuid }),
            visible,
            parent: parent && !parent[$ "isScene"] ? parent.uuid : undefined,
            renderOrder,
            geometry: geometry ? geometry.uuid : undefined,
            material: material ? material.uuid : undefined,
            layers: layers.mask,
            
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
    }
    
    // This is a very simplified version of the actual ThreeJS implementation
    function raycast(raycaster, hits) {
        var object = self;
        
        var matrixWorldInverse = matrixWorld.clone().invert();
        var localRay = raycaster.ray.clone();
        var localOrigin = localRay.origin.applyMatrix4(matrixWorldInverse);
        var localDirection = localRay.direction.transformDirection(matrixWorldInverse);
        
        var boundingBox = geometry[$ "boundingBox"];
        var boundingSphere = geometry[$ "boundingSphere"];
        
        if (boundingBox != undefined) {
			if (!localRay.intersectsBox(boundingBox)) return self;
		} else if (boundingSphere != undefined) {
			if (!localRay.intersectsSphere(boundingSphere)) return self;
		}
        
        array_push(hits, {
            object,
            distance: position.distanceToSquared(raycaster.ray.origin)
        });
        
        return self;
    }
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        return { obj: _self, payload: toJSON() };
    }
}