/**
 * @description Octahedron geometry.
 * @param {Real} radius Radius of the octahedron.
 * @param {Real} detail Level of detail (subdivision).
 * @param {Struct} data Additional data.
 */
function UeOctahedronGeometry(radius = 1, detail = 0, data = {}): UeGeometry(data) constructor {
    var _radius = radius ?? 1;
    var _detail = detail ?? 0;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    self.position = [];
    self.normal = [];
    self.uv = [];
    self.color = [];
    self.tangent = [];
    self.bone_indices = [];
    self.bone_weights = [];
    
    // Internal temp objects
    self.__tempTri = tri_create();
    self.__tempNorm = vec3_create();

    /**
     * @private
     * Internal helper to add a triangle and subdivide if needed.
     */
    self.__addTriangle = function(a, b, c, level, rad, col, alp) {
        if (level > 0) {
            // Subdivide
            var ab = [ (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5, (a[2] + b[2]) * 0.5 ];
            var bc = [ (b[0] + c[0]) * 0.5, (b[1] + c[1]) * 0.5, (b[2] + c[2]) * 0.5 ];
            var ca = [ (c[0] + a[0]) * 0.5, (c[1] + a[1]) * 0.5, (c[2] + a[2]) * 0.5 ];

            // Project to sphere
            var _norm_scale = function(v, r) {
                var d = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
                if (d > 0) {
                    v[0] = (v[0] / d) * r;
                    v[1] = (v[1] / d) * r;
                    v[2] = (v[2] / d) * r;
                }
            };
            
            _norm_scale(ab, rad);
            _norm_scale(bc, rad);
            _norm_scale(ca, rad);

            self.__addTriangle(a, ab, ca, level - 1, rad, col, alp);
            self.__addTriangle(ab, b, bc, level - 1, rad, col, alp);
            self.__addTriangle(ca, bc, c, level - 1, rad, col, alp);
            self.__addTriangle(ab, bc, ca, level - 1, rad, col, alp);
        } else {
            tri_set(self.__tempTri, a, b, c);
            tri_get_normal(self.__tempTri, self.__tempNorm);
            
            var nx = self.__tempNorm[0];
            var ny = self.__tempNorm[1];
            var nz = self.__tempNorm[2];

            // Simplistic tangent (along the first edge)
            var tx = b[0] - a[0];
            var ty = b[1] - a[1];
            var tz = b[2] - a[2];
            var td = sqrt(tx*tx + ty*ty + tz*tz);
            if (td > 0) { tx /= td; ty /= td; tz /= td; }
            
            var v_list = [a, b, c];
            for (var j = 0; j < 3; j++) {
                var v = v_list[j];
                array_push(self.position, v[0], v[1], v[2]);
                array_push(self.normal, nx, ny, nz);
                array_push(self.tangent, tx, ty, tz, 1.0);
                array_push(self.color, col, alp);
                array_push(self.bone_indices, 0, 0, 0, 0);
                array_push(self.bone_weights, 0, 0, 0, 0);
                
                // Simple UV projection
                var u = 0.5 + (arctan2(v[2], v[0]) / (2 * pi));
                var vv = 0.5 - (arcsin(v[1] / rad) / pi);
                array_push(self.uv, u, vv);
            }
        }
    };

    // Vertices of a unit octahedron
    var vertices = [
        [ 1, 0, 0 ],   // 0
        [ -1, 0, 0 ],  // 1
        [ 0, 1, 0 ],   // 2
        [ 0, -1, 0 ],  // 3
        [ 0, 0, 1 ],   // 4
        [ 0, 0, -1 ]   // 5
    ];

    // Faces (indices into vertices)
    var indices = [
        0, 2, 4,    0, 4, 3,    0, 3, 5,    0, 5, 2,
        1, 2, 5,    1, 5, 3,    1, 3, 4,    1, 4, 2
    ];

    // Build the octahedron
    for (var i = 0, il = array_length(indices); i < il; i += 3) {
        var v1 = [vertices[indices[i]][0] * _radius, vertices[indices[i]][1] * _radius, vertices[indices[i]][2] * _radius];
        var v2 = [vertices[indices[i+1]][0] * _radius, vertices[indices[i+1]][1] * _radius, vertices[indices[i+1]][2] * _radius];
        var v3 = [vertices[indices[i+2]][0] * _radius, vertices[indices[i+2]][1] * _radius, vertices[indices[i+2]][2] * _radius];
        
        self.__addTriangle(v1, v2, v3, _detail, _radius, _color, _alpha);
    }

    build();
}
