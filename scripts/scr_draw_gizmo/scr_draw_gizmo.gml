/**
 * Draw the gizmo
 */
function scr_draw_gizmo(replaceColors) {
	if (selectedObj == -1) return;
	var xx = selectedObj.x;
	var yy = selectedObj.y;
	var zz = selectedObj.z;
	
	draw_set_lighting(false);
	
	/** Traslate */
	// Lines
	var  mat = matrix_build(xx, yy, zz, 0, 0, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshCylinders, pr_linelist, -1);
	
	// Cones
	var length = 25;
	mat = matrix_build(xx+length, yy, zz, 0, 270, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshConeX, pr_trianglestrip, -1);
	
	mat = matrix_build(xx, yy+length, zz, 90, 0, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshConeY, pr_trianglestrip, -1);
	
	mat = matrix_build(xx, yy, length+zz, 0, 0, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshConeZ, pr_trianglestrip, -1);	
	
	// Planes
	mat = matrix_build(xx, yy, zz, 0, 0, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshPlane, pr_trianglelist, -1);
	vertex_submit(gizmoMeshPlaneBorder, pr_linelist, -1);
	
	/** Rotate */
	//TODO: scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.x, xx, yy, zz, 0, 90, 0, 1, 1, 1);
	//scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.y, xx, yy, zz, 0, 90, 90, 1, 1, 1);
	//scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.z, xx, yy, zz, 0, 0, 0, 1, 1, 1);
		
	var gizmoRotateXYZ_camDirX = point_direction(0, -o_ctrl.z, point_distance(o_ctrl.x, o_ctrl.y, xx, yy), -zz) ;
	var gizmoRotateXYZ_camDirZ = point_direction(o_ctrl.x, o_ctrl.y, xx, yy) - 90;
	//scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.xyz, xx, yy, zz, gizmoRotateXYZ_camDirX, 90, gizmoRotateXYZ_camDirZ+90, 1, 1, 1);
	
	/*mat = matrix_build(xx, yy, zz, 0, 90, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshCircleX, pr_linestrip, -1);

	mat = matrix_build(xx, yy, zz, 0, 90, 90, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshCircleY, pr_linestrip, -1);
	
	mat = matrix_build(xx, yy, zz, 0, 0, 0, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshCircleZ, pr_linestrip, -1);
	
	var camDirX = point_direction(0, -o_ctrl.z, point_distance(o_ctrl.x, o_ctrl.y, xx, yy), -zz) ;
	var camDirZ = point_direction(o_ctrl.x, o_ctrl.y, xx, yy) - 90;
	var mat = matrix_build(xx, yy, zz, camDirX, 90, camDirZ+90, 1, 1, 1);
	matrix_set(matrix_world, mat);
	vertex_submit(gizmoMeshCircleXYZ, pr_linestrip, -1);
	*/
	
	matrix_set(matrix_world, matrix_build_identity());
	draw_set_lighting(o_ctrl.lightEnabled);
}