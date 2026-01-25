function UeMesh(geometry = undefined, material = global.UE_DEFAULT_MATERIAL, data = {}): UeObject3D(data) constructor {
  self.isMesh = true;
  self.type = "Mesh";
  self.geometry = geometry;
  self.material = material;
  self.primitive = data[$ "primitive"] ?? pr_trianglelist;
  self.isSprite = false;

  /** @type {UeSkeleton} The skeleton associated with this mesh for skinning */
  self.skeleton = data[$ "skeleton"];

  /**
   * @type {string} Bind mode: "attached" (whole mesh to one bone) or "skinned" (vertex weights)
   * Determines how the mesh is bound to the skeleton. "attached" means the entire mesh is
   * transformed by the bind pose of the single bone it is attached to. "skinned" means each
   * vertex is weighted to multiple bones, with the mesh's pose determined by a linear blend
   * of those bones' transforms.
   */
  self.bindMode = data[$ "bindMode"] ?? "attached";

  /**
   * @type {Array<real>} 4×4 transformation matrix that records the mesh's world pose at the instant
   * it was bound to a skeleton.  This "bind pose" is used during skinning so that vertex
   * positions can be transformed from the neutral bind-space into the animated skeleton-space.
   * When no bindMatrix is supplied, an identity matrix is used, meaning the mesh is already
   * authored in the coordinate system of its skeleton.
   */
  self.bindMatrix = data[$ "bindMatrix"] ?? matrix_build_identity();

  /**
   * @type {Array<real>} Inverse of the bind matrix
   * Used during skinning to transform vertex positions from the animated skeleton-space
   * back into the neutral bind-space.
   */
  self.bindMatrixInverse = data[$ "bindMatrixInverse"] ?? matrix_build_identity();

  
  // === Methods ===

  /**
   * @description Renders the mesh using the current world matrix.
   * @param {boolean} wireframe - Whether to render the mesh as wireframe.
   */
  function render(wireframe = false) {
    gml_pragma("forceinline");
    
    // Set the world matrix
    // If we are using skeletal animation, the bone matrices already include the world transform.
    // We set matrix_world to identity to avoid double-transforming.
    if (self.skeleton != undefined && self.bindMode == "skinned") {
      matrix_set(matrix_world, global.UE_MAT4_IDENTITY);
    } else {
      matrix_set(matrix_world, matrixWorld);
    }

    // Submit the vertex buffer
    var tex = -1;
    if (material != undefined) {
      var materialMap = material.textures[$ "map"];

      if (materialMap != undefined) {
          materialMap.__useGlobal();
          tex = materialMap.__cachedTexture ?? -1;
      }
    }

    vertex_submit(self.geometry.vb, wireframe ? pr_linelist : primitive, tex);
    return self;
  }

  function toJSON() {
    gml_pragma("forceinline");
    return {
      uuid,
      type,
      name,
      children: array_map(children, function (child) { return child.uuid }),
      visible,
      parent: parent && !parent[$ "isScene"] ?parent.uuid : undefined,
      renderOrder,
      geometry: self.geometry ? self.geometry.toJSON() : undefined,
      material: self.material ? self.material.uuid : undefined,
      layers: layers.mask,
      matrixAutoUpdate,
      frustumCulled,
      castShadow,
      receiveShadow,
      position,
      rotation,
      scale,
      up,
    };
  }

  function fromJSON(data) {
    gml_pragma("forceinline");
    uuid = data[$ "uuid"];
    name = data[$ "name"];
    visible = data[$ "visible"];
    renderOrder = data[$ "renderOrder"];
    layers.mask = data[$ "layers"];

    if (data[$ "position"] != undefined) vec3_copy(position, data.position);
    if (data[$ "rotation"] != undefined) quat_copy(rotation, data.rotation);
    if (data[$ "scale"] != undefined) vec3_copy(scale, data.scale);
    if (data[$ "up"] != undefined) vec3_copy(self.up, data.up);

    if (geometry != undefined && data[$ "geometry"] != undefined) {
      geometry.fromJSON(data.geometry);
    }
    self.materialUUID = data[$ "material"];
    matrixAutoUpdate = data[$ "matrixAutoUpdate"];
    frustumCulled = data[$ "frustumCulled"];
    castShadow = data[$ "castShadow"] ?? false;
    receiveShadow = data[$ "receiveShadow"] ?? false;

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

    var matrixWorldInverse = global.UE_MAT4_TEMP0;
    mat4_copy(matrixWorldInverse, matrixWorld);
    matrix_inverse(matrixWorldInverse, matrixWorldInverse);

    var localRay = ray_clone(raycaster.ray);
    ray_apply_matrix4(localRay, matrixWorldInverse);

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
        var i1 = hasIndices ? indices[i + 1] : i + 1;
        var i2 = hasIndices ? indices[i + 2] : i + 2;

        var i0_3 = i0 * 3, i1_3 = i1 * 3, i2_3 = i2 * 3;

        vec3_set(v0, verts[i0_3], verts[i0_3 + 1], verts[i0_3 + 2]);
        vec3_set(v1, verts[i1_3], verts[i1_3 + 1], verts[i1_3 + 2]);
        vec3_set(v2, verts[i2_3], verts[i2_3 + 1], verts[i2_3 + 2]);

        var p = ray_intersect_triangle(localRay, v0, v1, v2, false, localHit);
        if (p != undefined) {
          vec3_apply_matrix4(localHit, matrixWorld);
          var distance = vec3_distance_to(raycaster.ray, localHit);
          if (distance < MIN_DIST) {
            MIN_DIST = distance;
            hitPrecise = true;
            global.UE_VEC3_TEMP4[0] = localHit[0];
            global.UE_VEC3_TEMP4[1] = localHit[1];
            global.UE_VEC3_TEMP4[2] = localHit[2];
          }
        }
      }
    }

    if (hitPrecise) {
      if (MIN_DIST >= raycaster.near && MIN_DIST <= raycaster.far) {
        array_push(hits, {
          object,
          distance: MIN_DIST,
          point: [global.UE_VEC3_TEMP4[0], global.UE_VEC3_TEMP4[1], global.UE_VEC3_TEMP4[2]]
        });
      }
    } else {
      // --- 3. Approximate Intersection (Bounding box) ---
      var boundingBox = geometry[$ "boundingBox"];
      if (boundingBox != undefined) {
        var t = ray_intersect_box(localRay, boundingBox);
        if (t == -1) return self;
        var localPoint = ray_at(localRay, t);
        vec3_apply_matrix4(localPoint, matrixWorld);
        var dist = vec3_distance_to(raycaster.ray, localPoint);

        if (dist >= raycaster.near && dist <= raycaster.far) {
          array_push(hits, {
            object,
            distance: dist,
            point: [localPoint[0], localPoint[1], localPoint[2]]
          });
        }
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
   * Returns a clone of this mesh and optionally all descendants.
   */
  function clone(recursive = true) {
    var _newMesh = new UeMesh(self.geometry, self.material);
    _newMesh.copy(self, recursive);
    return _newMesh;
  }
}
