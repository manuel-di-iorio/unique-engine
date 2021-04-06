/**
 * Draw a model
 */
function scr_draw_model(model) {
	// Transform the model
	matrix_set(matrix_world, model.matrix);
		
	// Submit the meshes
	var meshes = model.meshes;		
	for (var j=0, k=model.meshesCount; j<k; j++) {
		var mesh = meshes[j];
		vertex_submit(mesh.vbuff, pr_trianglelist, mesh.texture);
	}
}