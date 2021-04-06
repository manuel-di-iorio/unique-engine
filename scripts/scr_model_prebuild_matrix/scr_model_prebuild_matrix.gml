/**
 * Set the transform matrix for the specified object
 */
function scr_model_prebuild_matrix(obj) {
	obj.matrix = matrix_build(obj.x, obj.y, obj.z, obj.xrot, obj.yrot, obj.zrot, obj.xscale, obj.yscale, obj.zscale);
}