// @MissingDoc @untested
/// @description Frustum constructor - Creates a view frustum for culling calculations
/// @param {Struct} _p0 (optional) defaults to a new Plane
/// @param {Struct} _p1 (optional) defaults to a new Plane  
/// @param {Struct} _p2 (optional) defaults to a new Plane
/// @param {Struct} _p3 (optional) defaults to a new Plane
/// @param {Struct} _p4 (optional) defaults to a new Plane
/// @param {Struct} _p5 (optional) defaults to a new Plane
function UeFrustum(_p0, _p1, _p2, _p3, _p4, _p5) constructor {
    
    // Array of 6 planes
    planes = array_create(6);
    planes[0] = argument_count > 0 && _p0 != undefined ? _p0 : new UePlane();
    planes[1] = argument_count > 1 && _p1 != undefined ? _p1 : new UePlane();
    planes[2] = argument_count > 2 && _p2 != undefined ? _p2 : new UePlane();
    planes[3] = argument_count > 3 && _p3 != undefined ? _p3 : new UePlane();
    planes[4] = argument_count > 4 && _p4 != undefined ? _p4 : new UePlane();
    planes[5] = argument_count > 5 && _p5 != undefined ? _p5 : new UePlane();
    
    /// @description Return a new Frustum with the same parameters as this one
    /// @return {Struct}
    function clone() {
        return new UeFrustum().copy(self);
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
            var px = plane.normal.x > 0 ? _box.max.x : _box.min.x;
            var py = plane.normal.y > 0 ? _box.max.y : _box.min.y;
            var pz = plane.normal.z > 0 ? _box.max.z : _box.min.z;
            
            // If positive vertex is behind plane, box is outside frustum
            if (plane.distanceToPoint(px, py, pz) < 0) {
                return false;
            }
        }
        return true;
    }
    
    /// @description Checks whether the object's bounding sphere is intersecting the Frustum. 
    /// Note: if the object hasn't got the bounding sphere, it will be intersected anway (safe approach) 
    /// @param {Struct} object Object with geometry for bounding sphere calculation
    /// @return {bool}
    function intersectsObject(object) { 
        return object.__frustumSphere != undefined ? intersectsSphere(object.__frustumSphere) : true;
    }
    
    /// @description Return true if sphere intersects with this frustum
    /// @param {Struct} _sphere Sphere to check for intersection
    /// @return {bool}
    function intersectsSphere(_sphere) {
        var center = _sphere.center;
        var negRadius = -_sphere.radius; 
        
        for (var i = 0; i < 6; i++) {
            if (planes[i].distanceToPoint(center) < negRadius) {
                return false;
            }
        }
        return true;
        
        //var cx = _sphere.center.x;
        //var cy = _sphere.center.y; 
        //var cz = _sphere.center.z;
        //var negRadius = -_sphere.radius;
        //
        //// Cache dei piani come variabili locali
        //var p0 = planes[0]; var p1 = planes[1]; var p2 = planes[2];
        //var p3 = planes[3]; var p4 = planes[4]; var p5 = planes[5];
        //
        //// Test inlineati con early return
        //if (p0.normal.x * cx + p0.normal.y * cy + p0.normal.z * cz + p0.d < negRadius) return false;
        //if (p1.normal.x * cx + p1.normal.y * cy + p1.normal.z * cz + p1.d < negRadius) return false;
        //if (p2.normal.x * cx + p2.normal.y * cy + p2.normal.z * cz + p2.d < negRadius) return false;
        //if (p3.normal.x * cx + p3.normal.y * cy + p3.normal.z * cz + p3.d < negRadius) return false;
        //if (p4.normal.x * cx + p4.normal.y * cy + p4.normal.z * cz + p4.d < negRadius) return false;
        //if (p5.normal.x * cx + p5.normal.y * cy + p5.normal.z * cz + p5.d < negRadius) return false;
            //
        //return true;
    }
    
    /// @description Checks whether the sprite is intersecting the Frustum
    /// @param {Struct} _sprite Sprite to check for intersection
    /// @return {bool}
    function intersectsSprite(_sprite) {
        global.UE_DUMMY_SPHERE.center.set(0, 0, 0);
        var offset = global.UE_DUMMY_DEFAULT_SPRITE_CENTER.distanceTo(sprite.center);
        _sphere.radius = 0.7071067811865476 + offset; // the constant 0.707etc.. is the result of sqrt(0.5)
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
    /// @param {Struct} _matrix Projection Matrix4 used to set the planes
    /// @return {Struct}
    function setFromProjectionMatrix(_matrix) {
        var m = _matrix.data;
        
        var m11 = m[0], m12 = m[4], m13 = m[8], m14 = m[12];
        var m21 = m[1], m22 = m[5], m23 = m[9], m24 = m[13];
        var m31 = m[2], m32 = m[6], m33 = m[10], m34 = m[14];
        var m41 = m[3], m42 = m[7], m43 = m[11], m44 = m[15];
        
        // Right plane
        planes[0].setComponents(m41 - m11, m42 - m12, m43 - m13, m44 - m14).normalize();
        
        // Left plane
        planes[1].setComponents(m41 + m11, m42 + m12, m43 + m13, m44 + m14).normalize();
        
        // Bottom plane
        planes[2].setComponents(m41 + m21, m42 + m22, m43 + m23, m44 + m24).normalize();
        
        // Top plane
        planes[3].setComponents(m41 - m21, m42 - m22, m43 - m23, m44 - m24).normalize();
        
        // Near plane
        planes[4].setComponents(m41 + m31, m42 + m32, m43 + m33, m44 + m34).normalize();
        
        // Far plane
        planes[5].setComponents(m41 - m31, m42 - m32, m43 - m33, m44 - m34).normalize();
        
        return self;
    }
}