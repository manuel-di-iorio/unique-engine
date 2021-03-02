// Draw the grid
vertex_submit(gridVbuff, pr_linelist, -1);

// Draw the scene
scr_draw_scene(false);

// Mouse 3d position mesh
if (mouse_check_button_pressed(mb_left)) {
	//models[0].x = winMouse3DX
	//models[0].y = winMouse3DY
	//models[0].z = winMouse3DZ + 10
}

var mesh = scr_model_create_mesh()
vertex_position_3d(mesh, winMouse3DX, winMouse3DY, winMouse3DZ)
vertex_color(mesh, c_orange, 1)

vertex_position_3d(mesh, winMouse3DX, winMouse3DY, winMouse3DZ+200)
vertex_color(mesh, c_orange, 1)

scr_model_end_mesh(mesh)
vertex_submit(mesh, pr_linelist, -1)