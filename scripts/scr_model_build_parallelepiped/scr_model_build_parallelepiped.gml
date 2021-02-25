/**
 * Create a parallelepiped mesh
 */
function scr_model_build_parallelepiped(vbuff, x1, y1, z1, x2, y2, z2, col, alpha) {
	// Base
	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

	// Front
	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

	// Back 
	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

	// Right
	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

	// Left
	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

	// Top
	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);
}