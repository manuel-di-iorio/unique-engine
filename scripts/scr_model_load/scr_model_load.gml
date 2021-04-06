/**
 * Load a file and return an array of meshes and materials
 */
function scr_model_load(input_file) {
	var meshes = [];
	var importer_id;
	
	// Load the file
	importer_id = GMA_CreateImporter();
	GMA_BindImporter(importer_id);
	
	var check = GMA_ReadFile(input_file,
		GMA_PP.TARGET_REALTIME_MAX_QUALITY |
		GMA_PP.SPLIT_BONE_COUNT |
		GMA_PP.OPTIMIZE_MESHES |
		GMA_PP.OPTIMIZE_GRAPH |
		GMA_PP.DEBONE |
		GMA_PP.JOIN_IDENTICAL_VERTICES |
		GMA_PP.EMBED_TEXTURES
	);

	//Check if the file is correctly loaded
	if (!check) {
		show_message("Error while trying to load the model '" + input_file + "'");
		return -1;
	}
	
	GMA_BindScene();
	var materialsCount = GMA_GetMaterialNum();
	
	// Loop over the meshes
	for (var a=0, al=GMA_GetMeshNum(); a<al; a++) {
		GMA_BindMesh(a);
		
		// Load the mesh material (if any)
		var material = -1;
		if (a < materialsCount) {
			GMA_BindMaterial(a);
			
			var textures = [];
			
			log(GMA_GetMeshUVChannelsNum())
			log(GMA_GetMaterialTextureName(GMA_TEXTURE_TYPE_UNKNOWN, 0))
			log(GMA_GetMaterialTextureName(GMA_TEXTURE_TYPE_UNKNOWN, 1))
			log(GMA_MeshHasTexCoords(GMA_TEXTURE_TYPE_UNKNOWN))
			
			material = {
				ambient: make_color_rgb(GMA_GetMaterialAmbientColorR(), GMA_GetMaterialAmbientColorG(), GMA_GetMaterialAmbientColorB()),
				diffuse: make_color_rgb(GMA_GetMaterialDiffuseColorR(), GMA_GetMaterialDiffuseColorG(), GMA_GetMaterialDiffuseColorB()),
				emissive: make_color_rgb(GMA_GetMaterialEmissiveColorR(), GMA_GetMaterialEmissiveColorG(), GMA_GetMaterialEmissiveColorB()),
				specularColor:  make_color_rgb(GMA_GetMaterialSpecularColorR(), GMA_GetMaterialSpecularColorG(), GMA_GetMaterialSpecularColorB()),
				transparentColor:  make_color_rgb(GMA_GetMaterialTransparentColorR(), GMA_GetMaterialTransparentColorG(), GMA_GetMaterialTransparentColorB()),
				opacity: GMA_GetMaterialOpacity(),
				refraction: GMA_GetMaterialRefracti(),
				shadingModel: GMA_GetMaterialShadingModel(),
				blendFunc: GMA_GetMaterialBlendFunc(),
				shininess: GMA_GetMaterialShininess(),
				shininessStrength: GMA_GetMaterialShininessStrength(),
				textures: textures
			};
		}
	        
		// Create a mesh
		var vbuff = vertex_create_buffer();
		vertex_begin(vbuff, uniqueEngine_vformat);
		
		// For each triangle
		for (var i = 0; i < GMA_GetMeshFacesNum(); i++) {
		    // For each vertex of the triangle
		    for (var j = 0; j < 3; j ++) {
		        // Read the index of first vertex of the triangle
		        var vertex_id = GMA_GetMeshFaceVertexIndex(i, j);
					
		        // Read the data and write it in the vertex buffer
		        var X = GMA_GetMeshVertexX(vertex_id);
		        var Y = GMA_GetMeshVertexY(vertex_id);
		        var Z = GMA_GetMeshVertexZ(vertex_id);
				
		        var U = GMA_GetMeshTexCoordU(vertex_id, 0);
		        var V = GMA_GetMeshTexCoordV(vertex_id, 0);
					
				var NX = GMA_GetMeshNormalX(vertex_id);
				var NY = GMA_GetMeshNormalY(vertex_id);
				var NZ = GMA_GetMeshNormalZ(vertex_id);
				
				vertex_position_3d(vbuff, X, Y, Z);					
				vertex_texcoord(vbuff, U, V);
				vertex_normal(vbuff, NX, NY, NZ);
				
				vertex_color(vbuff, 
				    c_white, 1
					//make_color_rgb(GMA_GetMeshVertexColorR(), GMA_GetMeshVertexColorG(), GMA_GetMeshVertexColorB()), 
					//GMA_GetMeshVertexAlpha(vertex_id, 0)
				);
		    }
		}
	
		// End the model building
		vertex_end(vbuff);
		
		// Compile the buffer into the project included file
		var buf = buffer_create_from_vertex_buffer(vbuff, buffer_fixed, 1);
		buffer_save(buf, input_file + ".buff" + string(a));
	
		vertex_freeze(vbuff);
		array_push(meshes, { 
			name: GMA_GetMeshName(), vbuff: vbuff, 
			sprite: -1,
			texture: -1, 
			material: material
		});
	}
	
	// Destroy the scene
	GMA_DeleteImporter(importer_id);
	
	return meshes;
}