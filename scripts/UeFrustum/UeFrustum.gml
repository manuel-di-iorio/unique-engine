/// @description Frustum constructor - Creates a view frustum for culling calculations
function UeFrustum() constructor {
    
    // Array of 6 planes
    planes = array_create(6);
    for (var i=0; i<6; i++) {
        planes[i] = new UePlane();
    }
    
    /// @description Return a new Frustum with the same parameters as this one
    /// @return {Struct}
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }
    
    /// @description Checks to see if the frustum contains the point
    /// @param {Struct} _point Vector3 to test
    /// @return {bool}
    static containsPoint = function(_point) {
        gml_pragma("forceinline");
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
    static copy = function(_frustum) {
        gml_pragma("forceinline");
        for (var i = 0; i < 6; i++) {
            planes[i].copy(_frustum.planes[i]);
        }
        return self;
    }
    
    /// @description Return true if box intersects with this frustum
    /// @param {Struct} _box Box3 to check for intersection
    /// @return {bool}
    static intersectsBox = function(_box) {
        gml_pragma("forceinline");
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
    static intersectsObject = function(object) {
        gml_pragma("forceinline");
        var intersectionSphere = object.__intersectionSphere;
        if (intersectionSphere == undefined) return true;
        return intersectsSphere(intersectionSphere);
    }
    
    /// @description Return true if sphere intersects with this frustum
    /// @param {Struct} sphere Sphere to check for intersection
    /// @return {bool}
    static intersectsSphere = function(sphere) {
        gml_pragma("forceinline");
        var negRadius = -sphere.radius; 
        var sphereCenter = sphere.center;
        
        for (var i = 0; i < 6; i++) { 
            var dist = planes[i].distanceToPoint(sphere.center);
            if (planes[i].distanceToPoint(sphereCenter) < negRadius) {
                return false;
            }
        }
        return true;
    }
    
    /// @description Checks whether the sprite is intersecting the Frustum
    /// @param {Struct} _sprite Sprite to check for intersection
    /// @return {bool}
    static intersectsSprite = function(_sprite) {
        gml_pragma("forceinline");
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
    static set = function(_p0, _p1, _p2, _p3, _p4, _p5) {
        gml_pragma("forceinline");
        planes[0].copy(_p0);
        planes[1].copy(_p1);
        planes[2].copy(_p2);
        planes[3].copy(_p3);
        planes[4].copy(_p4);
        planes[5].copy(_p5);
        return self;
    }
    
    /// @description Sets the frustum planes from the projection matrix
    /// @param {Struct} m Projection Matrix 16x16 Array used to set the planes
    /// @return {Struct}
    static setFromProjectionMatrix = function(m) {
        gml_pragma("forceinline");
        var m3  = m[3],  m7  = m[7],  m11 = m[11], m15 = m[15];
        var m0  = m[0],  m4  = m[4],  m8  = m[8],  m12 = m[12];
        var m1  = m[1],  m5  = m[5],  m9  = m[9],  m13 = m[13];
        var m2  = m[2],  m6  = m[6],  m10 = m[10], m14 = m[14];
    
        var p, nx, ny, nz, d, invLen;
    
        // Left
        nx = m3 + m0;
        ny = m7 + m4;
        nz = m11 + m8;
        d  = m15 + m12;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[0];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;
    
        // Right
        nx = m3 - m0;
        ny = m7 - m4;
        nz = m11 - m8;
        d  = m15 - m12;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[1];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;
    
        // Far
        nx = m3 - m2;
        ny = m7 - m6;
        nz = m11 - m10;
        d  = m15 - m14;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[4];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;

        // Near
        nx = m3 + m2;
        ny = m7 + m6;
        nz = m11 + m10;
        d  = m15 + m14;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[5];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;
    
        // Bottom
        nx = m3 + m1;
        ny = m7 + m5;
        nz = m11 + m9;
        d  = m15 + m13;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[2];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;
    
        // Top
        nx = m3 - m1;
        ny = m7 - m5;
        nz = m11 - m9;
        d  = m15 - m13;
        invLen = 1 / sqrt(nx * nx + ny * ny + nz * nz);
        p = planes[3];
        p.normal.x = nx * invLen;
        p.normal.y = ny * invLen;
        p.normal.z = nz * invLen;
        p.constant = d * invLen;
    
        return self;
    }
}
