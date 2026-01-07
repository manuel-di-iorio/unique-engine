/// @desc Capsule functions [startX, startY, startZ, finishX, finishY, finishZ, radius]

global.UE_CAPSULE_TEMP0 = capsule_create();
global.UE_CAPSULE_TEMP1 = capsule_create();
global.UE_CAPSULE_TEMP2 = capsule_create();

enum CAPSULE {
	startX, startY, startZ, finishX, finishY, finishZ, radius
}

/// @func capsule_create(start, finish, radius)
/// @desc Creates a new capsule.
/// @param {Array<Real>} [start] The start vector [x, y, z] (default: [0, 0, 0])
/// @param {Array<Real>} [finish] The finish vector [x, y, z] (default: [0, 1, 0])
/// @param {Real} [radius=1] The capsule's radius
/// @returns {Array<Real>} A new capsule [startX, startY, startZ, finishX, finishY, finishZ, radius]
function capsule_create(start = undefined, finish = undefined, radius = 1) {
	gml_pragma("forceinline");
	start ??= vec3_create(0, 0, 0);
	finish ??= vec3_create(0, 1, 0);
	return [start[0], start[1], start[2], finish[0], finish[1], finish[2], radius];
}

/// @func capsule_set(c, start, finish, radius)
/// @desc Sets the capsule components to the given values.
/// @param {Array<Real>} c The capsule to modify
/// @param {Array<Real>} start The start vector [x, y, z]
/// @param {Array<Real>} finish The finish vector [x, y, z]
/// @param {Real} radius The capsule's radius
/// @returns {Array<Real>} The modified capsule
function capsule_set(c, start, finish, radius) {
	gml_pragma("forceinline");
	c[0] = start[0]; c[1] = start[1]; c[2] = start[2];
	c[3] = finish[0]; c[4] = finish[1]; c[5] = finish[2];
	c[6] = radius;
	return c;
}

/// @func capsule_copy(c, src)
/// @desc Copies the values of the given capsule to this instance.
/// @param {Array<Real>} c The target capsule (will be modified)
/// @param {Array<Real>} src The source capsule to copy from
/// @returns {Array<Real>} The modified capsule
function capsule_copy(c, src) {
	gml_pragma("forceinline");
	array_copy(c, 0, src, 0, 7);
	return c;
}

/// @func capsule_clone(c)
/// @desc Returns a new capsule with copied values from this instance.
/// @param {Array<Real>} c The capsule to clone
/// @returns {Array<Real>} A new capsule with the same values
function capsule_clone(c) {
	gml_pragma("forceinline");
	return [c[0], c[1], c[2], c[3], c[4], c[5], c[6]];
}

/// @func capsule_get_center(c, out)
/// @desc Returns the center point of this capsule.
/// @param {Array<Real>} c The capsule
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The center point [x, y, z]
function capsule_get_center(c, out = undefined) {
	gml_pragma("forceinline");
	out ??= array_create(3);
	out[0] = (c[0] + c[3]) * 0.5;
	out[1] = (c[1] + c[4]) * 0.5;
	out[2] = (c[2] + c[5]) * 0.5;
	return out;
}

/// @func capsule_translate(c, v)
/// @desc Adds the given offset to this capsule, effectively moving it in 3D space.
/// @param {Array<Real>} c The capsule to modify
/// @param {Array<Real>} v The offset vector [x, y, z]
/// @returns {Array<Real>} The modified capsule
function capsule_translate(c, v) {
	gml_pragma("forceinline");
	c[0] += v[0]; c[1] += v[1]; c[2] += v[2];
	c[3] += v[0]; c[4] += v[1]; c[5] += v[2];
	return c;
}

/// @func capsule_intersects_box(c, box)
/// @desc Returns true if the given bounding box intersects with this capsule.
/// @param {Array<Real>} c The capsule
/// @param {Array<Real>} box The bounding box to test
/// @returns {Bool} Whether the given bounding box intersects with this capsule
function capsule_intersects_box(c, box) {
	gml_pragma("forceinline");
	
	// Get the closest point on the line segment (capsule axis) to the box
	var point = array_create(3);
	
	// Clamp the line segment finishpoints to the box
	box3_clamp_point(box, [c[0], c[1], c[2]], point);
	var distToStart = vec3_distance_to_squared(point, [c[0], c[1], c[2]]);
	
	box3_clamp_point(box, [c[3], c[4], c[5]], point);
	var distTofinish = vec3_distance_to_squared(point, [c[3], c[4], c[5]]);
	
	// If either finishpoint is within radius distance of the box, they intersect
	var radiusSq = c[6] * c[6];
	if (distToStart <= radiusSq || distTofinish <= radiusSq) {
		return true;
	}
	
	// Check if the line segment passes close enough to the box
	// Get the capsule's direction vector
	var dx = c[3] - c[0];
	var dy = c[4] - c[1];
	var dz = c[5] - c[2];
	var lengthSq = dx*dx + dy*dy + dz*dz;
	
	if (lengthSq == 0) {
		// Degenerate capsule (start == finish), treat as sphere
		var boxCenter = box3_get_center(box);
		var dist = box3_distance_to_point(box, boxCenter);
		return dist <= c[6];
	}
	
	// Get box center
	var boxCenter = box3_get_center(box);
	
	// Project box center onto the line segment
	var t = ((boxCenter[0] - c[0]) * dx + 
	         (boxCenter[1] - c[1]) * dy + 
	         (boxCenter[2] - c[2]) * dz) / lengthSq;
	t = clamp(t, 0, 1);
	
	// Get the closest point on the segment to the box center
	var closestX = c[0] + t * dx;
	var closestY = c[1] + t * dy;
	var closestZ = c[2] + t * dz;
	var closest = [closestX, closestY, closestZ];
	
	// Distance from this point to the box
	var dist = box3_distance_to_point(box, closest);
	
	return dist <= c[6];
}

/// @func capsule_equals(c, c2)
/// @desc Checks if two capsules are equal.
/// @param {Array<Real>} c The first capsule
/// @param {Array<Real>} c2 The second capsule
/// @returns {Bool} Whether the capsules are equal
function capsule_equals(c, c2) {
	gml_pragma("forceinline");
	return c[0]==c2[0] && c[1]==c2[1] && c[2]==c2[2] && 
	       c[3]==c2[3] && c[4]==c2[4] && c[5]==c2[5] && 
	       c[6]==c2[6];
}

/// @func capsule_get_start(c, out)
/// @desc Gets the start vector of the capsule.
/// @param {Array<Real>} c The capsule
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The start vector [x, y, z]
function capsule_get_start(c, out = undefined) {
	gml_pragma("forceinline");
	out ??= array_create(3);
	out[0] = c[0];
	out[1] = c[1];
	out[2] = c[2];
	return out;
}

/// @func capsule_get_finish(c, out)
/// @desc Gets the finish vector of the capsule.
/// @param {Array<Real>} c The capsule
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The finish vector [x, y, z]
function capsule_get_finish(c, out = undefined) {
	gml_pragma("forceinline");
	out ??= array_create(3);
	out[0] = c[3];
	out[1] = c[4];
	out[2] = c[5];
	return out;
}
