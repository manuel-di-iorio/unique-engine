function UeMesh(geometry = undefined, material = global.UE_DEFAULT_MATERIAL, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry;
    self.material = material;
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    
    // @todo @experimentalDeprecation. May be undeprecated if the render method will be used as abstract in UeObject3D
    // function render(_material) {
    //     gml_pragma("forceinline");
        
    //     // Set the world matrix
    //     matrix_set(matrix_world, matrixWorld.data);

    //     // Submit the vertex buffer
    //     vertex_submit(geometry.vb, _material.wireframe ? pr_linelist : primitive, -1); 
    // }
    
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            children: array_map(children, function(child) { return child.uuid }),
            visible,
            parent: parent && !parent[$ "isScene"] ? parent.uuid : undefined,
            renderOrder,
            geometry: geometry ? geometry.toJSON() : undefined,
            material: material ? material.uuid : undefined,
            layers: layers.mask,
            matrixAutoUpdate,
            frustumCulled,
            
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

    function fromJSON(data) {
        gml_pragma("forceinline");
        uuid = data[$ "uuid"];
        name = data[$ "name"];
        visible = data[$ "visible"];
        renderOrder = data[$ "renderOrder"];
        layers.mask = data[$ "layers"];
        
        position.set(data[$ "px"], data[$ "py"], data[$ "pz"]);
        rotation.set(data[$ "rx"], data[$ "ry"], data[$ "rz"], data[$ "rw"]);
        scale.set(data[$ "sx"], data[$ "sy"], data[$ "sz"]);
        up.set(data[$ "ux"], data[$ "uy"], data[$ "uz"]);
        
        if (geometry != undefined && data[$ "geometry"] != undefined) {
            geometry.fromJSON(data.geometry);
        }

        matrixAutoUpdate = data[$ "matrixAutoUpdate"];
        frustumCulled = data[$ "frustumCulled"];
        
        return self;
    }
    
    /// @description Performs a raycast intersection test against this mesh object
    /// @param {Struct} raycaster The raycaster object containing the ray to test against
    /// @param {Array} hits Array to store hit results when intersections are found
    /// @returns {Struct} Returns self for method chaining
    /// @remarks This function tests if a ray intersects with the mesh by first transforming 
    ///          the ray to local space, then performing bounding volume tests (sphere and box) 
    ///          for early rejection. If the ray passes the bounding tests, a hit result is 
    ///          added to the hits array containing the object reference and distance.
    function raycast(raycaster, hits) {
        gml_pragma("forceinline");
        var object = self;
        
        var matrixWorldInverse = global.UE_DUMMY_MATRIX4.copy(matrixWorld).invert();
        var localRay = global.UE_DUMMY_RAY.copy(raycaster.ray);
        localRay.origin.applyMatrix4(matrixWorldInverse);
        localRay.direction.transformDirection(matrixWorldInverse);
        
        var boundingBox = geometry[$ "boundingBox"];
        var boundingSphere = geometry[$ "boundingSphere"];
        
        if (boundingSphere != undefined) {
            if (!localRay.intersectSphere(boundingSphere, global.UE_DUMMY_VECTOR3)) return self; 
        }
        
        if (boundingBox != undefined) {
			if (!localRay.intersectBox(boundingBox, global.UE_DUMMY_VECTOR3)) return self;
		} 
        
        array_push(hits, {
            object,
            distance: position.distanceToSquared(raycaster.ray.origin)
        });
        
        return self;
    }
    
    /** Internal export methods */
    function _compileData(data) {
        gml_pragma("forceinline");
        var _self = self;
        return { obj: _self, payload: toJSON() };
    }

    /**
     * Creates an instance with proper master-instance relationship
     */
    function createInstance() {
        gml_pragma("forceinline");
        var _this = self;
        
        var instance = new UeMesh(self.geometry, self.material, {
            position: _this.position.clone(),
            rotation: _this.rotation.clone(),
            scale: _this.scale.clone(),
            up: _this.up.clone(),
            name: _this.name,
            visible: _this.visible,
            renderOrder: _this.renderOrder,
            layers: _this.layers.clone(),
            frustumCulled: _this.frustumCulled,
            matrixAutoUpdate: _this.matrixAutoUpdate,
        });
        instance.object = self; // Point to the master object
        instance.isInstance = true; // Mark as instance
                
        // Add to instances list
        self.instances.add(instance);

        for (var i=0, il = array_length(self.children); i < il; i++) {
            instance.add(self.children[i].createInstance());
        }
        
        return instance;
    }
}
