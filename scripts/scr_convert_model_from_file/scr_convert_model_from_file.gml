///@author		Giacomo Marton
///@version		1.0.0
/**
 * Load a file and return a new model
 */
function scr_convert_model_from_file(input_file, output_file, mesh_id) {
	vertex_format_begin(); 
	vertex_format_add_position_3d();
	vertex_format_add_normal();
	vertex_format_add_texcoord();
	vertex_format_add_color();
	var vformat = vertex_format_end();

	var model_id, importer_id;
	//Load the file
	importer_id = GMA_CreateImporter();
	GMA_BindImporter(importer_id);
	
	var check = GMA_ReadFile(input_file,
		//GMA_PP.CONVERT_TO_LEFT_HANDED |
		GMA_PP.TARGET_REALTIME_MAX_QUALITY |
		GMA_PP.SPLIT_BONE_COUNT |
		GMA_PP.OPTIMIZE_MESHES |
		GMA_PP.OPTIMIZE_GRAPH |
		GMA_PP.DEBONE
	);

	//Check if the file is correctly loaded
	if (check)	{
	    GMA_BindScene();
	    //Check if the mesh exist
	    if (mesh_id >= 0 && mesh_id < GMA_GetMeshNum()) {
			o_ctrl.stats.meshes++;
	        GMA_BindMesh(mesh_id);  //Binds the mesh that will be used in the other mesh functions
	        
			//Create a 3d model
	        var model_id = vertex_create_buffer();
			vertex_begin(model_id, vformat);
			
	        // For each triangle
	        for (var i = 0; i < GMA_GetMeshFacesNum(); i++) {
				o_ctrl.stats.triangles++;
				
	            // For each vertex of the triangle
	            for (var j = 0; j < 3; j ++) {
	                // Read the index of first vertex of the triangle
	                var vertex_id = GMA_GetMeshFaceVertexIndex(i, j);
					
	                // Read the data and write it in the d3d model
	                var X = GMA_GetMeshVertexX(vertex_id);
	                var Y = GMA_GetMeshVertexY(vertex_id);
	                var Z = GMA_GetMeshVertexZ(vertex_id);
				
	                var U = GMA_GetMeshTexCoordU(vertex_id, 0);
	                var V = GMA_GetMeshTexCoordV(vertex_id, 0);
					
					var NX = GMA_GetMeshNormalX(vertex_id);
					var NY = GMA_GetMeshNormalY(vertex_id);
					var NZ = GMA_GetMeshNormalZ(vertex_id);
				
					vertex_position_3d(model_id, X, Y, Z);					
					vertex_texcoord(model_id, U, V);
					vertex_normal(model_id, NX, NY, NZ);
					vertex_color(model_id, c_white, 1.0);
	            }
	        }
	        // End the primitive
	        vertex_end(model_id);
			
	        // Destroy the scene
	        GMA_DeleteImporter(importer_id);
		
			// @todo: scene export
			//var buf = buffer_create_from_vertex_buffer(model_id, buffer_fixed, 1);
			//buffer_save(buf, output_file);
	        return model_id;
	    } else {
	        // Destroy the scene
	        GMA_DeleteImporter(importer_id);
	        return -2;
	    }
	} else {
	    return -1;
	}
}