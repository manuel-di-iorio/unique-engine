function scr_model_build_hud_axis() {
	mesh_hud_axis_icon = scr_model_create_mesh();
	var size = 50;
	
	// X
	vertex_position_3d(mesh_hud_axis_icon, 0, 0, 0);
	vertex_color(mesh_hud_axis_icon, Colors3D.x, 1);
	vertex_position_3d(mesh_hud_axis_icon, size, 0, 0);
	vertex_color(mesh_hud_axis_icon, Colors3D.x, 1);	
	
	// Y
	vertex_position_3d(mesh_hud_axis_icon, 0, 0, 0);
	vertex_color(mesh_hud_axis_icon, Colors3D.y, 1);
	vertex_position_3d(mesh_hud_axis_icon, 0, size, 0);
	vertex_color(mesh_hud_axis_icon, Colors3D.y, 1);	
	
	// Z
	vertex_position_3d(mesh_hud_axis_icon, 0, 0, 0);
	vertex_color(mesh_hud_axis_icon, Colors3D.z, 1);
	vertex_position_3d(mesh_hud_axis_icon, 0, 0, size);
	vertex_color(mesh_hud_axis_icon, Colors3D.z, 1);	
	
	scr_model_end_mesh(mesh_hud_axis_icon);
}