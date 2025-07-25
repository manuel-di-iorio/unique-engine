// @MissingDoc @untested
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

        // Left, Right, Bottom, Top, Near, Far
        planes[0] = buildPlane(m, +1, +0, +0, +0); // Left
        planes[1] = buildPlane(m, -1, +0, +0, -0); // Right
        planes[2] = buildPlane(m, +0, +1, +0, +0); // Bottom
        planes[3] = buildPlane(m, +0, -1, +0, -0); // Top
        planes[4] = buildPlane(m, +0, +0, +1, +0); // Near
        planes[5] = buildPlane(m, +0, +0, -1, -0); // Far

        return self;
    }

    // @todo will be removed 
    function buildPlane(m, ix, iy, iz, iw) {
            var nx = m[3] + ix * m[0];
            var ny = m[7] + iy * m[4];
            var nz = m[11] + iz * m[8];
            var nw = m[15] + iw * m[12];
            return new UePlane().setComponents(nx, ny, nz, nw).normalize();
        }
}