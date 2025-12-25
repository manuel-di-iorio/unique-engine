function UeMesh(geometry = undefined, material = global.UE_DEFAULT_MATERIAL, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry;
    self.material = material;
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    self.isSprite = false;
    
    function render(wireframe = false) {
         gml_pragma("forceinline");
        
         // Set the world matrix
         matrix_set(matrix_world, matrixWorld);

         // Submit the vertex buffer
         vertex_submit(geometry.vb, wireframe ? pr_linelist : primitive, -1); 
     }
    
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
        
        // Transform the ray into the local space of the mesh (inverse world matrix), array-based
        mat4_copy(global.UE_MAT4_TEMP0, matrixWorld.data); mat4_invert(global.UE_MAT4_TEMP0);
        
        // Note: We copy the ray to a local ray
        var localRay = global.UE_RAY_TEMP0.copy(raycaster.ray);
        localRay.origin.applyMatrix4(global.UE_MAT4_TEMP0);
        localRay.direction.transformDirection(global.UE_MAT4_TEMP0);

        // --- 1. Bounding Volume Checks (Local Space) ---
        // If the geometry has bounding volumes, test them first for early rejection
        var boundingSphere = geometry[$ "boundingSphere"];
        if (boundingSphere != undefined) {
            if (ray_intersect_sphere(localRay, boundingSphere) == -1) return self;
        }
        
        // --- 2. Precise Intersection Test (Triangles) ---
        // If precise raycasting is enabled for Mesh, we test every triangle
        var hitPrecise = false;
        var MIN_DIST = infinity;
        
        if (raycaster.params.Mesh[$ "precise"] && geometry && geometry.position != undefined) {
            
            var verts = geometry.position;
            var indices = geometry.index;
            var hasIndices = is_array(indices) && array_length(indices) > 0;
            var len = hasIndices ? array_length(indices) : (array_length(verts) / 3);
            
            var v0 = global.UE_VEC3_TEMP0;
            var v1 = global.UE_VEC3_TEMP1;
            var v2 = global.UE_VEC3_TEMP2;
            var localHit = global.UE_VEC3_TEMP3;
            
            // Loop through all triangles
            for (var i = 0; i < len; i += 3) {
                 var i0 = hasIndices ? indices[i] : i;
                 var i1 = hasIndices ? indices[i+1] : i+1;
                 var i2 = hasIndices ? indices[i+2] : i+2;
                 
                 var i0_3 = i0 * 3, i1_3 = i1 * 3, i2_3 = i2 * 3;
                 
                 vec3_set(v0, verts[i0_3], verts[i0_3+1], verts[i0_3+2]);
                 vec3_set(v1, verts[i1_3], verts[i1_3+1], verts[i1_3+2]);
                 vec3_set(v2, verts[i2_3], verts[i2_3+1], verts[i2_3+2]);

                 var p = ray_intersect_triangle(localRay, v0, v1, v2, false, localHit);
                 if (p != undefined) {
                      vec3_apply_matrix4(localHit, matrixWorld);
                      var dSq = ray_distance_sq_to_point(raycaster.ray, localHit[0], localHit[1], localHit[2]);
                      if (dSq < MIN_DIST) { MIN_DIST = dSq; hitPrecise = true; }
                 }
            }
        }
        
        if (hitPrecise) {
            array_push(hits, {
                object,
                distance: MIN_DIST
            });
        } else {
            // --- 3. Approximate Intersection (Bounding box) ---
            var boundingBox = geometry[$ "boundingBox"];
            if (boundingBox != undefined) {
                var t = ray_intersect_box(localRay, boundingBox);
                if (t == -1) return self;
                var localPoint = ray_at(localRay, t);
                vec3_apply_matrix4(localPoint, matrixWorld);
                var dist = ray_distance_sq_to_point(raycaster.ray, localPoint[0], localPoint[1], localPoint[2]);
                
                array_push(hits, {
                    object,
                    distance: dist
                });
            }
        }
        
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
    
    /**
     * Returns a clone of this mesh and optionally all descendants.
     */
    function clone(recursive = true) {
         var _newMesh = new UeMesh(self.geometry, self.material);
         _newMesh.copy(self, recursive);
         
         if (self.isInstance) {
             _newMesh.isInstance = true;
             _newMesh.object = self.object;
         }
         
         return _newMesh;
    }
}
