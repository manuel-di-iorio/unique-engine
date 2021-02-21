/**
 * Create the gizmo model
 */
function scr_model_build_gizmo() {
	enum GizmoComponent { 
		translateX, translateY, translateZ, translateXYPlane, translateXZPlane, translateYZPlane, 
		rotateX, rotateY, rotateZ, rotateXYZ
	};
	
	// Gizmo components struct
	gizmos = {
		translate: {},
		rotate: {},
		scale: {}
	};
	var length = 25;
	var mesh;
	
	/** Translate mesh **/
	/*gizmos.translate.x = { gizmo: GizmoComponent.translateX, prim: pr_trianglestrip  };
	scr_obj_set_selection_id(gizmos.translate.x);
	
	mesh = scr_model_create_mesh(true);
	scr_model_build_circle(mesh, 0, 0, 0, length, color);
	scr_model_end_mesh(mesh);
	
	var buildRotateX = function(length, color) {
		var mesh = scr_model_create_mesh(true);
		scr_model_build_circle(mesh, 0, 0, 0, length, color);
		scr_model_end_mesh(mesh);
		return mesh;
	}*/
	
	// Create the lines meshes
	
	var alpha = .8;
	var coneLength = 8;
	var coneRadius = 2;
	
	// Split lines into separate meshes
	gizmoMeshCylinders = scr_model_create_mesh();
	scr_model_build_line(gizmoMeshCylinders, 0, 0, 0, length, 0, 0, Colors3D.red, alpha);
	scr_model_build_line(gizmoMeshCylinders, 0, 0, 0, 0, length, 0, Colors3D.blue, alpha);
	scr_model_build_line(gizmoMeshCylinders, 0, 0, 0, 0, 0, length, Colors3D.green, alpha);
	scr_model_end_mesh(gizmoMeshCylinders);
	
	gizmoMeshConeX = scr_model_create_mesh(true, true);
	scr_model_build_cone(gizmoMeshConeX, 0, 0, 0, coneLength, coneRadius, Colors3D.red, alpha);
	scr_model_end_mesh(gizmoMeshConeX);
	
	gizmoMeshConeY = scr_model_create_mesh(true, true);
	scr_model_build_cone(gizmoMeshConeY, 0, 0, 0, coneLength, coneRadius, Colors3D.blue, alpha);
	scr_model_end_mesh(gizmoMeshConeY);
	
	gizmoMeshConeZ = scr_model_create_mesh(true, true);
	scr_model_build_cone(gizmoMeshConeZ, 0, 0, 0, coneLength, coneRadius, Colors3D.green, alpha);
	scr_model_end_mesh(gizmoMeshConeZ);
	
	// Split planes into separate meshes
	var planeOffset = 3;
	var planeAlpha = .3;
	gizmoMeshPlane = scr_model_create_mesh(true);
	scr_model_build_plane(gizmoMeshPlane, -planeOffset, -planeOffset,  -planeOffset, planeOffset, planeOffset, -planeOffset, Colors3D.green, planeAlpha); // XY
	scr_model_build_plane_xz(gizmoMeshPlane, -planeOffset, -planeOffset, -planeOffset, -planeOffset, planeOffset, planeOffset,  Colors3D.red, planeAlpha); // XZ
	scr_model_build_plane(gizmoMeshPlane, -planeOffset, -planeOffset, -planeOffset, planeOffset, -planeOffset, planeOffset, Colors3D.blue, planeAlpha); // YZ
	scr_model_end_mesh(gizmoMeshPlane);
	
	gizmoMeshPlaneBorder = scr_model_create_mesh();
	scr_model_build_square(gizmoMeshPlaneBorder, -planeOffset, -planeOffset,  -planeOffset, planeOffset, planeOffset, -planeOffset, Colors3D.green, 1); // XY
	scr_model_build_square_xz(gizmoMeshPlaneBorder, -planeOffset, -planeOffset, -planeOffset, -planeOffset, planeOffset, planeOffset,  Colors3D.red, 1); // XZ
	scr_model_build_square(gizmoMeshPlaneBorder, -planeOffset, -planeOffset, -planeOffset, planeOffset, -planeOffset, planeOffset, Colors3D.blue, 1); // YZ
	scr_model_end_mesh(gizmoMeshPlaneBorder);
	
	
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
}