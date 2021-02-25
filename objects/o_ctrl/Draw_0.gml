// Draw the grid
vertex_submit(gridVbuff, pr_linelist, -1);

// Draw the scene
scr_draw_scene(false);

/*var mesh = scr_model_create_mesh()
vertex_position_3d(mesh, winMouse3DX, winMouse3DY, winMouse3DZ)
vertex_color(mesh, c_orange, 1)

vertex_position_3d(mesh, winMouse3DX, winMouse3DY, winMouse3DZ+200)
vertex_color(mesh, c_orange, 1)

scr_model_end_mesh(mesh)
vertex_submit(mesh, pr_linelist, -1)