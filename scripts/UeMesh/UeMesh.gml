function UeMesh(geometry = undefined, material = global.UE_DEFAULT_MATERIAL, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry;
    self.material = material;
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    
    function render(wireframe = false) {
         gml_pragma("forceinline");
        
         // Set the world matrix
         matrix_set(matrix_world, matrixWorld.data);

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
        
        // Transform the ray into the local space of the mesh (inverse world matrix)
        // We use dummy/cache objects to avoid GC allocation during raycasting
        var matrixWorldInverse = global.UE_DUMMY_MATRIX4.copy(matrixWorld).invert();
        
        // Note: We copy the ray to a local ray
        var localRay = global.UE_DUMMY_RAY.copy(raycaster.ray);
        localRay.origin.applyMatrix4(matrixWorldInverse);
        localRay.direction.transformDirection(matrixWorldInverse);

        // --- 1. Bounding Volume Checks (Local Space) ---
        // If the geometry has bounding volumes, test them first for early rejection
        var boundingSphere = geometry[$ "boundingSphere"];
        if (boundingSphere != undefined) {
             if (!localRay.intersectSphere(boundingSphere, global.UE_DUMMY_VECTOR3)) return self; 
        }       
        
        // --- 2. Precise Intersection Test (Triangles) ---
        // If precise raycasting is enabled for Mesh, we test every triangle
        // @todo: not actually working
        if (raycaster.params.Mesh[$ "precise"] && geometry && array_length(geometry.vertices) > 0) {
            
            var verts = geometry.vertices;
            var indices = geometry.index;
            var hasIndices = is_array(indices);
            var len = hasIndices ? array_length(indices) : array_length(verts);
            
            var minDistSq = infinity;
            
            // Intersection calculation variables (reused globals)
            var edge1 = global.UE_DUMMY_VECTOR3_E;
            var edge2 = global.UE_DUMMY_VECTOR3_F;
            var pvec = global.UE_DUMMY_VECTOR3_G;
            var tvec = global.UE_DUMMY_VECTOR3_H;
            var qvec = global.UE_DUMMY_VECTOR3_J; 
            var intersectPoint = global.UE_DUMMY_VECTOR3;
            var v0 = global.UE_DUMMY_VECTOR3_B;
            var v1 = global.UE_DUMMY_VECTOR3_C;
            var v2 = global.UE_DUMMY_VECTOR3_D;
            
            var rayOrigin = localRay.origin;
            var rayDir = localRay.direction;
            
            // Loop through all triangles
            for (var i = 0; i < len; i += 3) {
                 var i0 = hasIndices ? indices[i] : i;
                 var i1 = hasIndices ? indices[i+1] : i+1;
                 var i2 = hasIndices ? indices[i+2] : i+2;
                 
                 var v0d = verts[i0];
                 var v1d = verts[i1];
                 var v2d = verts[i2];
                 
                 v0.set(v0d.x, v0d.y, v0d.z);
                 v1.set(v1d.x, v1d.y, v1d.z);
                 v2.set(v2d.x, v2d.y, v2d.z);
                 
                 // Möller–Trumbore intersection algorithm
                 edge1.copy(v1).sub(v0);
                 edge2.copy(v2).sub(v0);
                 
                 pvec.copy(rayDir).cross(edge2);
                 
                 var det = edge1.dot(pvec);
                 
                 // Ray is parallel to triangle (allowing for double-sided matching)
                 if (abs(det) < UE_EPSILON) continue;
                 
                 var invDet = 1 / det;
                 
                 tvec.copy(rayOrigin).sub(v0);
                 
                 var u = tvec.dot(pvec) * invDet;
                 // Add small epsilon tolerance for edge cases
                 if (u < -UE_EPSILON || u > 1 + UE_EPSILON) continue;
                 
                 qvec.copy(tvec).cross(edge1);
                 
                 var v = rayDir.dot(qvec) * invDet;
                 if (v < -UE_EPSILON || u + v > 1 + UE_EPSILON) continue;
                 
                 var t = edge2.dot(qvec) * invDet;
                 
                 if (t > UE_EPSILON) {
                      // Calculate Intersection Point in World Space
                      // P = O + tD
                      // We use a clean vector compute to ensure no side effects
                      intersectPoint.copy(rayDir).scale(t).add(rayOrigin);
                      
                      // Transform point from Local -> World
                      intersectPoint.applyMatrix4(matrixWorld);
                      
                      var dSq = intersectPoint.distanceToSquared(raycaster.ray.origin);
                      
                      if (dSq >= minDistSq) {
                          minDistSq = dSq;
                          return self;
                      }
                 }
            }
            
            array_push(hits, {
                object,
                distance: minDistSq
            });

        } else {
            // --- 3. Approximate Intersection (Bounding box) ---
            // If strictly precise is not required, we assume the bounding volume hit is sufficient
            // We use the object's origin distance as the sorting metric
            var boundingBox = geometry[$ "boundingBox"];
            if (boundingBox != undefined) {
                if (!localRay.intersectBox(boundingBox, global.UE_DUMMY_VECTOR3)) return self;
            } 
            
            array_push(hits, {
                object,
                distance: position.distanceToSquared(raycaster.ray.origin)
            });
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
}
