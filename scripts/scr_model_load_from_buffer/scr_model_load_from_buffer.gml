/** Load a model from cached datafiles */
function scr_model_load_from_buffer(partialPath) {
	var meshes = [];
	var index = 0;
	var path = partialPath + ".buff0";
	
	while (file_exists(path)) {
		// Load the buffer
		var buffer = buffer_load(path);
		var vbuff = vertex_create_buffer_from_buffer(buffer, uniqueEngine_vformat);
		vertex_freeze(vbuff);
		array_push(meshes, { vbuff: vbuff, sprite: -1, texture: -1 });
	
		path =  partialPath + ".buff" + string(index++);
	}
	
	return { meshes: meshes };
}
