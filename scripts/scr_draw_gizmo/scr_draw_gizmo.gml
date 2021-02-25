/**
 * Draw the gizmo
 */
function scr_draw_gizmo(replaceColors) {
	if (selectedObj == -1) return;
	var xx = selectedObj.x;
	var yy = selectedObj.y;
	var zz = selectedObj.z;
	
	draw_set_lighting(false);
	
	var length = 25;
	var halfLength = length/2;
	
	/** Traslate */
	var translateAxisDist = 6;
	
	// Planes
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.planeYZ, xx, yy, zz, 0, 0, 0, 1, 1, 1);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.planeXZ, xx, yy, zz, 0, 0, 0, 1, 1, 1);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.planeXY, xx, yy, zz, 0, 0, 0, 1, 1, 1);
	
	// Cylinders
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.x, xx+halfLength+translateAxisDist, yy, zz, 0, 90, 0, 1, 1, 1, 15);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.y, xx, yy+halfLength+translateAxisDist, zz, 90, 0, 0, 1, 1, 1, 15);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.z, xx, yy, zz+halfLength+translateAxisDist, 0, 0, 0, 1, 1, 1, 15);
	
	// Cones	
	var translateConeDist = translateAxisDist - 2;
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.coneX, xx+length+translateConeDist, yy, zz, 0, 270, 0, 1, 1, 1, 5);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.coneY, xx, yy+length+translateConeDist, zz, 90, 0, 0, 1, 1, 1, 5);
	scr_model_draw_gizmo_component(replaceColors, gizmos.translate.coneZ, xx, yy, length+zz+translateConeDist, 0, 0, 0, 1, 1, 1, 5);
	
	matrix_set(matrix_world, matrix_build(xx, yy, zz, 0, 0, 0, 1, 1, 1));
	vertex_submit(gizmoMeshPlaneBorder, pr_linelist, -1); // Plane borders
	
	
	/** Rotate */
	//TODO: scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.x, xx, yy, zz, 0, 90, 0, 1, 1, 1);
	//scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.y, xx, yy, zz, 0, 90, 90, 1, 1, 1);
	//scr_model_draw_gizmo_component(replaceColors, gizmos.rotate.z, xx, yy, zz, 0, 0, 0, 1, 1, 1);
		
	//var gizmoRotateXYZ_camDirX = point_direction(0, -o_ctrl.z, point_distance(o_ctrl.x, o_ctrl.y, xx, yy), -zz) ;
	//var gizmoRotateXYZ_camDirZ = point_direction(o_ctrl.x, o_ctrl.y, xx, yy) - 90;
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
	
	//vertex_submit(torus, pr_trianglelist, -1)
	
	//vertex_submit(vertex_buffer, pr_trianglelist, -1)
	
	matrix_set(matrix_world, matrix_build_identity());
	draw_set_lighting(o_ctrl.lightEnabled);
}