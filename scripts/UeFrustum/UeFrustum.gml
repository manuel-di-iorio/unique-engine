/// @description Frustum constructor - Creates a view frustum for culling calculations
function UeFrustum() constructor {
    
    // Array of 6 planes
    planes = array_create(6);
    for (var i=0; i<6; i++) {
        planes[i] = new UePlane();
    }
    
    /// @description Return a new Frustum with the same parameters as this one
    /// @return {Struct}
    function clone() {
        return variable_clone(self);
    }
    
    /// @description Checks to see if the frustum contains the point
    /// @param {Struct} _point Vector3 to test
    /// @return {bool}
    function containsPoint(_point) {
        for (var i = 0; i < 6; i++) {
            if (planes[i].distanceToPoint(_point) < 0) {
                return false;
            }
        }
        return true;
    }
    
    /// @description Copies the properties of the passed frustum into this one
    /// @param {Struct} _frustum The frustum to copy
    /// @return {Struct}
    function copy(_frustum) {
        for (var i = 0; i < 6; i++) {
            planes[i].copy(_frustum.planes[i]);
        }
        return self;
    }
    
    /// @description Return true if box intersects with this frustum
    /// @param {Struct} _box Box3 to check for intersection
    /// @return {bool}
    function intersectsBox(_box) {
        for (var i = 0; i < 6; i++) {
            var plane = planes[i];
            
            // Get positive vertex (farthest in direction of plane normal)
            var px = plane.normal.x > 0 ? _box.sizeMax.x : _box.sizeMin.x;
            var py = plane.normal.y > 0 ? _box.sizeMax.y : _box.sizeMin.y;
            var pz = plane.normal.z > 0 ? _box.sizeMax.z : _box.sizeMin.z;
            
            // If positive vertex is behind plane, box is outside frustum
            if (plane.distanceToPoint(new UeVector3(px, py, pz)) < 0) {
                return false;
            }
        }
        return true;
    }
    
    /// @description Checks whether the object's bounding sphere is intersecting the Frustum. 
    /// Note: if the object hasn't got the bounding sphere, it will be intersected anyway (safe approach) 
    /// @param {Struct} object Object with geometry for bounding sphere calculation
    /// @return {bool}
    function intersectsObject(object) {
        var frustumSphere = object.__frustumSphere;
        if (frustumSphere == undefined) return true;
        return intersectsSphere(frustumSphere);
    }
    
    /// @description Return true if sphere intersects with this frustum
    /// @param {Struct} sphere Sphere to check for intersection
    /// @return {bool}
    function intersectsSphere(sphere) {
        var negRadius = -sphere.radius; 
        var sphereCenter = sphere.center;
        
        for (var i = 0; i < 6; i++) { 
            var dist = planes[i].distanceToPoint(sphere.center);
    //show_debug_message("Piano " + string(i) + " distanza dal centro sfera: " + string(dist));
            if (planes[i].distanceToPoint(sphereCenter) < negRadius) {
                return false;
            }
        }
        return true;
    }
    
    /// @description Checks whether the sprite is intersecting the Frustum
    /// @param {Struct} _sprite Sprite to check for intersection
    /// @return {bool}
    function intersectsSprite(_sprite) {
        global.UE_DUMMY_SPHERE.center.set(0, 0, 0);
        var offset = global.UE_DUMMY_DEFAULT_SPRITE_CENTER.distanceTo(sprite.center);
        _sphere.radius = 0.7071067811865476 + offset; // 0.707etc.. is the approx result of sqrt(0.5)
		_sphere.applyMatrix4(sprite.matrixWorld);
		return this.intersectsSphere(_sphere);
    }
    
    /// @description Sets the frustum from the passed planes
    /// @param {Struct} _p0 
    /// @param {Struct} _p1 
    /// @param {Struct} _p2 
    /// @param {Struct} _p3 
    /// @param {Struct} _p4 
    /// @param {Struct} _p5 
    /// @return {Struct}
    function set(_p0, _p1, _p2, _p3, _p4, _p5) {
        planes[0].copy(_p0);
        planes[1].copy(_p1);
        planes[2].copy(_p2);
        planes[3].copy(_p3);
        planes[4].copy(_p4);
        planes[5].copy(_p5);
        return self;
    }
    
    /// @description Sets the frustum planes from the projection matrix
    /// @param {Struct} matrix Projection Matrix4 used to set the planes
    /// @return {Struct}
    function setFromProjectionMatrix(matrix) {
        var m = matrix.data;
    
        // righe della matrice
        var r0 = [m[0], m[4], m[8],  m[12]];
        var r1 = [m[1], m[5], m[9],  m[13]];
        var r2 = [m[2], m[6], m[10], m[14]];
        var r3 = [m[3], m[7], m[11], m[15]];
    
        planes[0] = new UePlane().setComponents(
            r3[0] + r0[0],
            r3[1] + r0[1],
            r3[2] + r0[2],
            r3[3] + r0[3]
        ).normalize(); // Left
    
        planes[1] = new UePlane().setComponents(
            r3[0] - r0[0],
            r3[1] - r0[1],
            r3[2] - r0[2],
            r3[3] - r0[3]
        ).normalize(); // Right
    
        planes[2] = new UePlane().setComponents(
            r3[0] + r1[0],
            r3[1] + r1[1],
            r3[2] + r1[2],
            r3[3] + r1[3]
        ).normalize(); // Bottom
    
        planes[3] = new UePlane().setComponents(
            r3[0] - r1[0],
            r3[1] - r1[1],
            r3[2] - r1[2],
            r3[3] - r1[3]
        ).normalize(); // Top
    
        planes[4] = new UePlane().setComponents(
            r3[0] + r2[0],
            r3[1] + r2[1],
            r3[2] + r2[2],
            r3[3] + r2[3]
        ).normalize(); // Near
    
        planes[5] = new UePlane().setComponents(
            r3[0] - r2[0],
            r3[1] - r2[1],
            r3[2] - r2[2],
            r3[3] - r2[3]
        ).normalize(); // Far
        
        return self;
    }
}