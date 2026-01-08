/// @desc 3D Line segment functions using arrays [start_vec3, end_vec3]
/// All functions modify the first line in-place when applicable for zero allocations.

// Global temp vectors for Line3 calculations
global.UE_LINE3_TEMP0 = vec3_create();
global.UE_LINE3_TEMP1 = vec3_create();

/// @func line3_create(start, end)
/// @desc Creates a new Line3 array [start_vec3, end_vec3].
/// @param {Array<Real>} [start] Start of the line segment (default [0,0,0])
/// @param {Array<Real>} [end] End of the line segment (default [0,0,0])
/// @returns {Array<Array<Real>>} New line3 array
function line3_create(start = undefined, _end = undefined) {
    gml_pragma("forceinline");
    return [
        start ?? vec3_create(),
        _end ?? vec3_create()
    ];
}

/// @func line3_set(line, start, end)
/// @desc Sets the start and end values by copying the given vectors.
/// @param {Array<Array<Real>>} line The line segment to modify
/// @param {Array<Real>} start The start point
/// @param {Array<Real>} _end The end point
/// @returns {Array<Array<Real>>} The modified line
function line3_set(line, start, _end) {
    gml_pragma("forceinline");
    vec3_copy(line[0], start);
    vec3_copy(line[1], _end);
    return line;
}

/// @func line3_copy(line, source)
/// @desc Copies the values of the given line segment to this instance.
/// @param {Array<Array<Real>>} line The line segment to modify
/// @param {Array<Array<Real>>} source The line segment to copy
/// @returns {Array<Array<Real>>} The modified line
function line3_copy(line, source) {
    gml_pragma("forceinline");
    vec3_copy(line[0], source[0]);
    vec3_copy(line[1], source[1]);
    return line;
}

/// @func line3_clone(line)
/// @desc Returns a new line segment with copied values from this instance.
/// @param {Array<Array<Real>>} line The line segment to clone
/// @returns {Array<Array<Real>>} A clone of the line
function line3_clone(line) {
    gml_pragma("forceinline");
    return [
        vec3_clone(line[0]),
        vec3_clone(line[1])
    ];
}

/// @func line3_delta(line, target)
/// @desc Returns the delta vector of the line segment's start and end point.
/// @param {Array<Array<Real>>} line The line segment
/// @param {Array<Real>} target The target vector to store result
/// @returns {Array<Real>} The target vector
function line3_delta(line, target) {
    gml_pragma("forceinline");
    return vec3_sub_vectors(target, line[1], line[0]);
}

/// @func line3_at(line, t, target)
/// @desc Returns a vector at a certain position along the line segment.
/// @param {Array<Array<Real>>} line The line segment
/// @param {Real} t A value between [0,1]
/// @param {Array<Real>} target The target vector to store result
/// @returns {Array<Real>} The target vector
function line3_at(line, t, target) {
    gml_pragma("forceinline");
    line3_delta(line, target);
    vec3_multiply_scalar(target, t);
    vec3_add(target, line[0]);
    return target;
}

/// @func line3_get_center(line, target)
/// @desc Returns the center of the line segment.
/// @param {Array<Array<Real>>} line The line segment
/// @param {Array<Real>} target The target vector to store result
/// @returns {Array<Real>} The target vector
function line3_get_center(line, target) {
    gml_pragma("forceinline");
    vec3_add_vectors(target, line[0], line[1]);
    vec3_multiply_scalar(target, 0.5);
    return target;
}

/// @func line3_apply_matrix4(line, matrix)
/// @desc Applies a 4x4 transformation matrix to this line segment.
/// @param {Array<Array<Real>>} line The line segment to transform
/// @param {Array<Real>} matrix The 4x4 matrix
/// @returns {Array<Array<Real>>} The modified line
function line3_apply_matrix4(line, matrix) {
    gml_pragma("forceinline");
    vec3_apply_matrix4(line[0], matrix);
    vec3_apply_matrix4(line[1], matrix);
    return line;
}

/// @func line3_distance_sq(line)
/// @desc Returns the squared Euclidean distance between the line's start and end point.
/// @param {Array<Array<Real>>} line The line segment
/// @returns {Real} The squared distance
function line3_distance_sq(line) {
    gml_pragma("forceinline");
    return vec3_distance_to_squared(line[0], line[1]);
}

/// @func line3_distance(line)
/// @desc Returns the Euclidean distance between the line's start and end point.
/// @param {Array<Array<Real>>} line The line segment
/// @returns {Real} The distance
function line3_distance(line) {
    gml_pragma("forceinline");
    return vec3_distance_to(line[0], line[1]);
}

/// @func line3_closest_point_to_point_parameter(line, point, clampToLine)
/// @desc Returns a point parameter based on the closest point as projected on the line segment.
/// @param {Array<Array<Real>>} line The line segment
/// @param {Array<Real>} point The point
/// @param {Bool} clampToLine Whether to clamp the result to the range [0,1]
/// @returns {Real} The point parameter
function line3_closest_point_to_point_parameter(line, point, clampToLine) {
    gml_pragma("forceinline");
    var start = line[0];
    var _end = line[1];
    
    vec3_sub_vectors(global.UE_LINE3_TEMP0, point, start);
    vec3_sub_vectors(global.UE_LINE3_TEMP1, _end, start);
    
    var dot1 = vec3_dot(global.UE_LINE3_TEMP1, global.UE_LINE3_TEMP0);
    var dot2 = vec3_dot(global.UE_LINE3_TEMP1, global.UE_LINE3_TEMP1);
    
    if (dot2 == 0) return 0;
    
    var t = dot1 / dot2;
    if (clampToLine) t = clamp(t, 0, 1);
    
    return t;
}

/// @func line3_closest_point_to_point(line, point, clampToLine, target)
/// @desc Returns the closest point on the line for a given point.
/// @param {Array<Array<Real>>} line The line segment
/// @param {Array<Real>} point The point
/// @param {Bool} clampToLine Whether to clamp the result to the range [0,1]
/// @param {Array<Real>} target The target vector
/// @returns {Array<Real>} The target vector
function line3_closest_point_to_point(line, point, clampToLine, target) {
    gml_pragma("forceinline");
    var t = line3_closest_point_to_point_parameter(line, point, clampToLine);
    return line3_at(line, t, target);
}

/// @func line3_equals(line, source)
/// @desc Returns true if this line segment is equal with the given one.
/// @param {Array<Array<Real>>} line First line segment
/// @param {Array<Array<Real>>} source Second line segment
/// @returns {Bool}
function line3_equals(line, source) {
    gml_pragma("forceinline");
    return vec3_equals(line[0], source[0]) && vec3_equals(line[1], source[1]);
}

/// @func line3_distance_sq_to_line3(line, line2, c1, c2)
/// @desc Returns the closest squared distance between this line segment and the given one.
/// @param {Array<Array<Real>>} line This line segment
/// @param {Array<Array<Real>>} line2 The other line segment
/// @param {Array<Real>} c1 Output closest point on this line
/// @param {Array<Real>} c2 Output closest point on other line
/// @returns {Real} The squared distance
function line3_distance_sq_to_line3(line, line2, c1, c2) {
    gml_pragma("forceinline");
    var p1 = line[0], p2 = line[1];
    var p3 = line2[0], p4 = line2[1];
    
    var rx = p2[0] - p1[0], ry = p2[1] - p1[1], rz = p2[2] - p1[2]; // d1
    var sx = p4[0] - p3[0], sy = p4[1] - p3[1], sz = p4[2] - p3[2]; // d2
    var r13x = p1[0] - p3[0], r13y = p1[1] - p3[1], r13z = p1[2] - p3[2]; // r
    
    var a = rx * rx + ry * ry + rz * rz; // squared length of d1
    var e = sx * sx + sy * sy + sz * sz; // squared length of d2
    var f = sx * r13x + sy * r13y + sz * r13z;
    
    var eps = 0.000001;
    var t1, t2;
    
    if (a <= eps && e <= eps) {
        t1 = 0;
        t2 = 0;
    } else if (a <= eps) {
        t1 = 0;
        t2 = clamp(f / e, 0, 1);
    } else {
        var c = rx * r13x + ry * r13y + rz * r13z;
        if (e <= eps) {
            t2 = 0;
            t1 = clamp(-c / a, 0, 1);
        } else {
            var b = rx * sx + ry * sy + rz * sz;
            var denom = a * e - b * b;
            
            if (denom != 0) {
                t1 = clamp((b * f - c * e) / denom, 0, 1);
            } else {
                t1 = 0;
            }
            
            t2 = (b * t1 + f) / e;
            
            if (t2 < 0) {
                t2 = 0;
                t1 = clamp(-c / a, 0, 1);
            } else if (t2 > 1) {
                t2 = 1;
                t1 = clamp((b - c) / a, 0, 1);
            }
        }
    }
    
    c1[0] = p1[0] + t1 * rx;
    c1[1] = p1[1] + t1 * ry;
    c1[2] = p1[2] + t1 * rz;
    
    c2[0] = p3[0] + t2 * sx;
    c2[1] = p3[1] + t2 * sy;
    c2[2] = p3[2] + t2 * sz;
    
    return vec3_distance_to_squared(c1, c2);
}
