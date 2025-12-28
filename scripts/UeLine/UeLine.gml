function UeLine(geometry = undefined, material = undefined, data = {}): UeMesh(geometry, material, data) constructor {
    isLine = true;
    primitive = pr_linestrip;
    self.geometry = geometry ?? new UeGeometry();
    self.material = material ?? new UeLineBasicMaterial();
    
    function raycast(raycaster, hits) {
        gml_pragma("forceinline");
        var object = self;
    
        var invWorld = mat4_clone(matrixWorld);
        mat4_invert(invWorld);
    
        var localRay = ray_clone(raycaster.ray);
        ray_apply_matrix4(localRay, invWorld);
    
        var s = scale;
        var avgScale = (s[0] + s[1] + s[2]) * 0.3333333;
        var localThreshold = raycaster.params.Line.threshold / avgScale;
        var localThresholdSq = localThreshold * localThreshold;
    
        var intersectionSphere = object[$ "__intersectionSphere"];
        if (intersectionSphere != undefined && is_array(intersectionSphere)) {
            var localSphere = sphere_clone(intersectionSphere);
            sphere_apply_matrix4(localSphere, invWorld);
            if (ray_intersect_sphere(localRay, localSphere) == -1) return self;
        }
    
        var pos = geometry[$ "position"];
        if (pos == undefined) return self;
        var count = (array_length(pos) / 3);
        var step = (primitive == pr_linelist) ? 2 : 1;
    
        var vec3A = global.UE_VEC3_TEMP0;
        var vec3B = global.UE_VEC3_TEMP1;
        var closestOnRay = global.UE_VEC3_TEMP2;
        var closestOnSeg = global.UE_VEC3_TEMP3;
    
        for (var i = 0; i < count - 1; i += step) {
            var i3 = i * 3;
            var i1_3 = (i + 1) * 3;

            vec3_set(vec3A, pos[i3],   pos[i3 + 1],   pos[i3 + 2]);
            vec3_set(vec3B, pos[i1_3], pos[i1_3 + 1], pos[i1_3 + 2]);
            
            var distSq = ray_distance_sq_to_segment(localRay, vec3A, vec3B, closestOnRay, closestOnSeg);
            if (distSq > localThresholdSq) {
                continue;
             } 
    
            var worldPoint = [closestOnSeg[0], closestOnSeg[1], closestOnSeg[2]];
            vec3_apply_matrix4(worldPoint, matrixWorld);
            var distance = vec3_distance_to(raycaster.ray, worldPoint);
    
            if (distance < raycaster.near || distance > raycaster.far) {
                continue;
            }
    
            array_push(hits, {
                object,
                distance,
                point: [worldPoint[0], worldPoint[1], worldPoint[2]],
                segmentIndex: i
            });
        }
    
        return self;
    }
}
