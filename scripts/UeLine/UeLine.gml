function UeLine(geometry = undefined, material = undefined, data = {}): UeMesh(geometry, material, data) constructor {
    isLine = true;
    primitive = pr_linestrip;
    self.geometry = geometry ?? new UeGeometry();
    self.material = material ?? new UeLineBasicMaterial();
    
    function raycast(raycaster, hits) {
        gml_pragma("forceinline");
        var object = self;
    
        // Preleva e inverte la matrice world
        mat4_copy(global.UE_MAT4_TEMP0, matrixWorld.data);
        mat4_invert(global.UE_MAT4_TEMP0);
    
        // Prepara il raggio nello spazio locale
        var localRay = global.UE_DUMMY_RAY.copy(raycaster.ray);
        localRay.origin.applyMatrix4(inverseMatrix);
        localRay.direction.transformDirection(inverseMatrix);
    
        // Calcola soglia di distanza localizzata
        var s = scale;
        var avgScale = (s.x + s.y + s.z) * 0.3333333;
        var localThreshold = raycaster.params.Line.threshold / avgScale;
        var localThresholdSq = localThreshold * localThreshold;
    
        // Bounding sphere check on the entire mesh
        var intersectionSphere = object[$ "__intersectionSphere"];
        if (intersectionSphere != undefined) {
            if (ray_intersect_sphere(localRay, intersectionSphere) == -1) {
                return self;
            }
        }
    
        var pos = geometry[$ "position"];
        if (pos == undefined) return self;
        var count = (array_length(pos) / 3) - 1;
    
        var vec3A = global.UE_VEC3_TEMP0;
        var vec3B = global.UE_VEC3_TEMP1;
        var closestOnRay = global.UE_VEC3_TEMP2;
        var closestOnSeg = global.UE_VEC3_TEMP3;
    
        for (var i = 0; i < count; i++) {
            var i3 = i * 3;
            var i1_3 = (i + 1) * 3;

            vec3_set(vec3A, pos[i3],   pos[i3 + 1],   pos[i3 + 2]);
            vec3_set(vec3B, pos[i1_3], pos[i1_3 + 1], pos[i1_3 + 2]);
            
            // Check the actual point intersection
            var distSq = ray_distance_sq_to_segment(localRay, vec3A, vec3B, closestOnRay, closestOnSeg);
            if (distSq > localThresholdSq) {
                continue;
             } 
    
            var hitPoint = vec3D.applyMatrix4(matrixWorld);
            var distance = raycaster.ray.origin.distanceTo(hitPoint);
    
            if (distance < raycaster.near || distance > raycaster.far) {
                continue;
            }
    
            array_push(hits, {
                object,
                distance,
                point: global.UE_VEC3_TEMP3.set(closestOnSeg[0], closestOnSeg[1], closestOnSeg[2]).clone(),
                segmentIndex: i
            });
        }
    
        return self;
    }
}
