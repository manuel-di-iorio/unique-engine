/**
 * Create the gizmo model
 */
function scr_model_build_gizmo() {
	enum GizmoComponent { 
		translateX, translateY, translateZ, translatePlaneXZ, translatePlaneYZ, translatePlaneXY, 
		rotateX, rotateY, rotateZ, rotateXYZ
	};

	// Gizmo components struct
	gizmos = {
		translate: {},
		rotate: {},
		scale: {}
	};
	
	var vbuff;
	var alpha = .9;
	
	/** Translate mesh **/
	
	// Cylinders
	var cylinderLength = 25;
	var cylinderRadius = .3;
	vbuff = scr_model_build_cylinder(0, 0, 0, cylinderRadius, cylinderLength, Colors3D.x, alpha);
	gizmos.translate.x = { gizmo: GizmoComponent.translateX, prim: pr_trianglestrip, vbuff: vbuff };
	scr_obj_set_selection_id(gizmos.translate.x);
	
	vbuff = scr_model_build_cylinder(0, 0, 0, cylinderRadius, cylinderLength, Colors3D.y, alpha);
	gizmos.translate.y = { gizmo: GizmoComponent.translateY, prim: pr_trianglestrip, vbuff: vbuff  };
	scr_obj_set_selection_id(gizmos.translate.y);
	
	vbuff = scr_model_build_cylinder(0, 0, -0.4, cylinderRadius, cylinderLength, Colors3D.z, alpha);
	gizmos.translate.z = { gizmo: GizmoComponent.translateZ, prim: pr_trianglestrip, vbuff: vbuff  };
	scr_obj_set_selection_id(gizmos.translate.z);
	
	// Cones
	var coneLength = 6;
	var coneRadius = 1.5;
	
	vbuff = scr_model_create_mesh(true, true);
	scr_model_build_cone(vbuff, 0, 0, 0, coneLength, coneRadius, Colors3D.x, alpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.coneX =  { gizmo: GizmoComponent.translateX, prim: pr_trianglestrip, vbuff: vbuff  };
	scr_obj_copy_selection_id(gizmos.translate.x, gizmos.translate.coneX);
	
	vbuff = scr_model_create_mesh(true, true);
	scr_model_build_cone(vbuff, 0, 0, 0, coneLength, coneRadius, Colors3D.y, alpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.coneY =  { gizmo: GizmoComponent.translateY, prim: pr_trianglestrip, vbuff: vbuff  };
	scr_obj_copy_selection_id(gizmos.translate.y, gizmos.translate.coneY);
	
	vbuff = scr_model_create_mesh(true, true);
	scr_model_build_cone(vbuff, 0, 0, 0, coneLength, coneRadius, Colors3D.z, alpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.coneZ =  { gizmo: GizmoComponent.translateZ, prim: pr_trianglestrip, vbuff: vbuff  };
	scr_obj_copy_selection_id(gizmos.translate.z, gizmos.translate.coneZ);
	
	// Planes
	var planeOffset = 2;
	var planeAlpha = .5;
	
	// Plane: YZ
	vbuff = scr_model_create_mesh(true);
	scr_model_build_plane_yz(vbuff, -planeOffset, -planeOffset, -planeOffset, -planeOffset, planeOffset, planeOffset, Colors3D.x, planeAlpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.planeYZ = { gizmo: GizmoComponent.translatePlaneYZ, prim: pr_trianglelist, vbuff: vbuff };
	scr_obj_set_selection_id(gizmos.translate.planeYZ);
	
	// Plane: XZ
	vbuff = scr_model_create_mesh(true);
	scr_model_build_plane(vbuff, -planeOffset, -planeOffset, -planeOffset, planeOffset, -planeOffset, planeOffset, Colors3D.y, planeAlpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.planeXZ = { gizmo: GizmoComponent.translatePlaneXZ, prim: pr_trianglelist, vbuff: vbuff };
	scr_obj_set_selection_id(gizmos.translate.planeXZ);
	
	// Plane: XY
	vbuff = scr_model_create_mesh(true);
	scr_model_build_plane(vbuff, -planeOffset, -planeOffset, -planeOffset, planeOffset, planeOffset, -planeOffset, Colors3D.z, planeAlpha);
	scr_model_end_mesh(vbuff);
	gizmos.translate.planeXY = { gizmo: GizmoComponent.translatePlaneXY, prim: pr_trianglelist, vbuff: vbuff };
	scr_obj_set_selection_id(gizmos.translate.planeXY);
	
	// Planes border (@todo: split meshes)
	vbuff = scr_model_create_mesh();
	scr_model_build_square_yz(vbuff, -planeOffset, -planeOffset, -planeOffset, -planeOffset, planeOffset, planeOffset,  Colors3D.x, 1); // YZ
	scr_model_build_square(vbuff, -planeOffset, -planeOffset, -planeOffset, planeOffset, -planeOffset, planeOffset, Colors3D.y, 1); // XZ
	scr_model_build_square(vbuff, -planeOffset, -planeOffset,  -planeOffset, planeOffset, planeOffset, -planeOffset, Colors3D.z, 1); // XY
	scr_model_end_mesh(vbuff);
	gizmoMeshPlaneBorder = vbuff;
	
	
	/** Rotate meshes */
	
	// X
	/*gizmos.rotate.x = { gizmo: GizmoComponent.rotateX, prim: pr_trianglestrip  };
	scr_obj_set_selection_id(gizmos.rotate.x);
	
	var buildRotateX = function(length, color) {
		var mesh = scr_model_create_mesh(true);
		scr_model_build_circle(mesh, 0, 0, 0, length, color);
		scr_model_end_mesh(mesh);
		return mesh;
	}
	
	gizmos.rotate.x.mesh = buildRotateX(length, Colors3D.red);
	gizmos.rotate.x.meshHover = buildRotateX(length, Colors3D.hover);
	gizmos.rotate.x.meshSelected = buildRotateX(length, Colors3D.selection);
	gizmos.rotate.x.meshReplace = buildRotateX(length, gizmos.rotate.x.selectionId);

	/*var gizmoMeshCircleY = scr_model_create_mesh();
	scr_model_build_circle(gizmoMeshCircleY, 0, 0, 0, length, Colors3D.blue);
	scr_model_end_mesh(gizmoMeshCircleY);
	gizmos.rotate.y = { gizmo: GizmoComponent.rotateY, mesh: gizmoMeshCircleY, prim: pr_linestrip };
	scr_obj_set_selection_id(gizmos.rotate.y);
	
	gizmoMeshCircleZ = scr_model_create_mesh();
	scr_model_build_circle(gizmoMeshCircleZ, 0, 0, 0, length, Colors3D.green);
	scr_model_end_mesh(gizmoMeshCircleZ);
	gizmos.rotate.z = { gizmo: GizmoComponent.rotateZ, mesh: gizmoMeshCircleZ, prim: pr_linestrip };
	scr_obj_set_selection_id(gizmos.rotate.z);
	
	gizmoMeshCircleXYZ = scr_model_create_mesh();
	scr_model_build_circle(gizmoMeshCircleXYZ, 0, 0, 0, length+3, c_white);
	scr_model_end_mesh(gizmoMeshCircleXYZ);
	gizmos.rotate.xyz = { gizmo: GizmoComponent.rotateXYZ, mesh: gizmoMeshCircleXYZ, prim: pr_linestrip };
	scr_obj_set_selection_id(gizmos.rotate.xyz);*/
	
		
	/*vertex_format_begin();
	vertex_format_add_position_3d();
	vertex_format_add_normal();
	vertex_format_add_textcoord();
	vertex_format_add_colour();
	vertex_format = vertex_format_end();
	var temp_buffer = buffer_load("cube.buf");
	vertex_buffer = vertex_create_buffer_from_buffer(temp_buffer, vertex_format);
	buffer_delete(temp_buffer);
	vertex_freeze(vertex_buffer);*/

	// Torus @todo
	//torus = scr_model_create_mesh(true);
	//scr_model_build_torus(torus)
	//scr_model_end_mesh(torus);
}