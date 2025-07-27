function UeLine(geometry = undefined, material = undefined, data = {}): UeMesh(geometry, material, data) constructor {
    isLine = true;
    primitive = pr_linestrip;
    self.geometry = geometry ?? new UeBufferGeometry();
    self.material = material ?? new UeLineBasicMaterial();
    
    //function raycast(raycaster, hits) {
        //var object = self;
    //
        //// Trasforma il raggio nello spazio locale dell'oggetto
        //var inverseMatrix = global.UE_DUMMY_MATRIX4.copy(matrixWorld).invert();
        //var localRay = global.UE_DUMMY_RAY.copy(raycaster.ray);
        //localRay.origin.applyMatrix4(inverseMatrix);
        //localRay.direction.transformDirection(inverseMatrix);
    //
        //var threshold = raycaster.params.Line.threshold; // Distanza massima accettata (in unità locali)
        //var localThreshold = threshold / ( ( scale.x + scale.y + scale.z ) / 3 );
        //var localThresholdSq = localThreshold * localThreshold;
        //
        //// --- Bounding sphere check ---
        //var intersectionSphere = object[$ "__intersectionSphere"];
        //if (intersectionSphere != undefined) {
            //if (!localRay.intersectSphere(intersectionSphere, global.UE_DUMMY_VECTOR3)) return self;
        //}
        //
        //// Check 
        //var vertices = geometry[$ "vertices"];
        //var count = array_length(vertices) - 1;
        //
        //var pointOnRay = global.UE_DUMMY_VECTOR3;
        //var pointOnSegment = global.UE_DUMMY_VECTOR3_B;
  //
        //for (var i = 0; i < count; i++) {
            //var a = vertices[i];
            //var b = vertices[i + 1];
    //
            //var distSq = localRay.distanceSqToSegment(
                //new UeVector3(a.x, a.y, a.z), 
                //new UeVector3(b.x, b.y, b.z), 
                //pointOnRay, 
                //pointOnSegment
            //);
    //
            //if (distSq > localThresholdSq) continue;
    //
            //// Trasforma punto di intersezione dallo spazio oggetto a world space
            //var hitPoint = pointOnSegment.applyMatrix4(matrixWorld);
            //var distance = raycaster.ray.origin.distanceTo(hitPoint);
    //
            //if (distance < raycaster.near || distance > raycaster.far) continue;
    //
            //array_push(hits, {
                //object,
                //distance,
                //point: hitPoint.clone(),
                //segmentIndex: i
            //});
        //}
    //
        //return self;
    //}
    //
    function raycast(raycaster, hits) {
        var object = self;
    
        // Preleva e inverte la matrice world una sola volta
        var inverseMatrix = global.UE_DUMMY_MATRIX4.copy(matrixWorld).invert();
    
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
            if (!localRay.intersectSphere(intersectionSphere, global.UE_DUMMY_VECTOR3)) {
                return self;
            }
        }
    
        var vertices = geometry[$ "vertices"];
        var count = array_length(vertices) - 1;
    
        var vec3A = global.UE_DUMMY_VECTOR3;
        var vec3B = global.UE_DUMMY_VECTOR3_B;
        var vec3C = global.UE_DUMMY_VECTOR3_C;
        var vec3D = global.UE_DUMMY_VECTOR3_D;
        var vec3E = global.UE_DUMMY_VECTOR3_E;
        var box = global.UE_DUMMY_BOX;
    
        for (var i = 0; i < count; i++) {
            var va = vertices[i];
            var vb = vertices[i + 1];
    
            vec3A.set(va.x, va.y, va.z);
            vec3B.set(vb.x, vb.y, vb.z);
    
            
            // Bounding box test on the specific segment (not useful for now)
            //var minVec = vec3C.copy(vec3A).minVec(vec3B).subScalar(localThreshold);
            //var maxVec = vec3D.copy(vec3A).maxVec(vec3B).addScalar(localThreshold);
            //box.set(minVec, maxVec);
            //if (!localRay.intersectBox(box, vec3E)) {
                //log("box not intersected")
                //continue;
            //}
            
            // Check the actual point intersection
            var distSq = localRay.distanceSqToSegment(vec3A, vec3B, vec3C, vec3D);
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
                point: hitPoint.clone(),
                segmentIndex: i
            });
        }
    
        return self;
    }
}