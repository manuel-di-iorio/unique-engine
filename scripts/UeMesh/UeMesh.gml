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
        var hitPrecise = false;
        var MIN_DIST = infinity;
        
        if (raycaster.params.Mesh[$ "precise"] && geometry && geometry.position != undefined) {
            
            var verts = geometry.position;
            var indices = geometry.index;
            var hasIndices = is_array(indices) && array_length(indices) > 0;
            var len = hasIndices ? array_length(indices) : (array_length(verts) / 3);
            var EPSILON = 0.000001;
            
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
            
            var rox = localRay.origin.x;
            var roy = localRay.origin.y;
            var roz = localRay.origin.z;
            var rdx = localRay.direction.x;
            var rdy = localRay.direction.y;
            var rdz = localRay.direction.z;

            // Loop through all triangles
            for (var i = 0; i < len; i += 3) {
                 var i0 = hasIndices ? indices[i] : i;
                 var i1 = hasIndices ? indices[i+1] : i+1;
                 var i2 = hasIndices ? indices[i+2] : i+2;
                 
                 var i0_3 = i0 * 3, i1_3 = i1 * 3, i2_3 = i2 * 3;
                 
                 var v0x = verts[i0_3], v0y = verts[i0_3+1], v0z = verts[i0_3+2];
                 var v1x = verts[i1_3], v1y = verts[i1_3+1], v1z = verts[i1_3+2];
                 var v2x = verts[i2_3], v2y = verts[i2_3+1], v2z = verts[i2_3+2];

                 // edge1 = v1 - v0
                 var e1x = v1x - v0x;
                 var e1y = v1y - v0y;
                 var e1z = v1z - v0z;

                 // edge2 = v2 - v0
                 var e2x = v2x - v0x;
                 var e2y = v2y - v0y;
                 var e2z = v2z - v0z;

                 // pvec = rayDir (cross) edge2
                 var pbx = rdy * e2z - rdz * e2y;
                 var pby = rdz * e2x - rdx * e2z;
                 var pbz = rdx * e2y - rdy * e2x;

                 // det = edge1 (dot) pvec
                 var det = e1x * pbx + e1y * pby + e1z * pbz;

                 if (abs(det) < EPSILON) continue;
                 
                 var invDet = 1 / det;

                 // tvec = rayOrigin - v0
                 var tx = rox - v0x;
                 var ty = roy - v0y;
                 var tz = roz - v0z;

                 // u = tvec (dot) pvec * invDet
                 var u = (tx * pbx + ty * pby + tz * pbz) * invDet;
                 if (u < -EPSILON || u > 1 + EPSILON) continue;

                 // qvec = tvec (cross) edge1
                 var qx = ty * e1z - tz * e1y;
                 var qy = tz * e1x - tx * e1z;
                 var qz = tx * e1y - ty * e1x;

                 // v = rayDir (dot) qvec * invDet
                 var v = (rdx * qx + rdy * qy + rdz * qz) * invDet;
                 if (v < -EPSILON || u + v > 1 + EPSILON) continue;

                 // t = edge2 (dot) qvec * invDet
                 var t = (e2x * qx + e2y * qy + e2z * qz) * invDet;

                 if (t > EPSILON) {
                      // Intersection Point: P = O + tD
                      var ipx = rdx * t + rox;
                      var ipy = rdy * t + roy;
                      var ipz = rdz * t + roz;
                      
                      // Transform point from Local -> World
                      intersectPoint.set(ipx, ipy, ipz).applyMatrix4(matrixWorld);
                      
                      var dSq = intersectPoint.distanceToSquared(raycaster.ray.origin);
                      
                      if (dSq < MIN_DIST) {
                          MIN_DIST = dSq;
                          hitPrecise = true;
                      }
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
                // If bounding box check fails, return early
                if (!localRay.intersectBox(boundingBox, global.UE_DUMMY_VECTOR3)) return self;
                
                // If bounding box hits, we use the intersection point distance for better sorting
                global.UE_DUMMY_VECTOR3.applyMatrix4(matrixWorld);
                var dist = global.UE_DUMMY_VECTOR3.distanceToSquared(raycaster.ray.origin);
                
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
