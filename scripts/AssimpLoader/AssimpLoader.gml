function AssimpLoader(data = {}) constructor // Feather disable GM2023
{
	// Store a texture inside the shared store
	/// @ignore
	store_material_texture = function(model_path, material_type, texture_path) {
        var fullPath = model_path + "/" + texture_path;
			
        if (!file_exists(fullPath)) {
            fullPath = model_path + "/" + filename_change_ext(texture_path, ".jpg");
            
            if (!file_exists(fullPath)) {
                fullPath = model_path + "/" + filename_change_ext(texture_path, ".png");
            }
        }
			
        var image = sprite_add(fullPath, 1, false, false, 0, 0);
        if (image == -1) return undefined;
            
        return new Texture({ image });
	}

	/// @ignore
	static read_binded_material = function(material, model_path) {
		//material.colorDiffuse = [GMA_GetMaterialDiffuseColorR(),
													//GMA_GetMaterialDiffuseColorG(),
													//GMA_GetMaterialDiffuseColorB(),
													//GMA_GetMaterialOpacity()];
			//
		//material.colorAmbient = [GMA_GetMaterialAmbientColorR(),
													//GMA_GetMaterialAmbientColorG(),
													//GMA_GetMaterialAmbientColorB(),
													//1.0];
			//
		//material.colorSpecular = [GMA_GetMaterialSpecularColorR(),
													//GMA_GetMaterialSpecularColorG(),
													//GMA_GetMaterialSpecularColorB(),
													//1.0];
			//
		//material.colorEmissive = [GMA_GetMaterialEmissiveColorR(),
													//GMA_GetMaterialEmissiveColorG(),
													//GMA_GetMaterialEmissiveColorB(),
													//1.0];
        
		var textures = material.textures;
		var material_types = [
			[ "diffuse", GMA_TEXTURE_TYPE_DIFFUSE ],
			[ "normals", GMA_TEXTURE_TYPE_NORMALS ],
			[ "reflection", GMA_TEXTURE_TYPE_REFLECTION ],
			[ "shininess", GMA_TEXTURE_TYPE_SHININESS ],
			[ "ambient", GMA_TEXTURE_TYPE_AMBIENT ],
			[ "displacement", GMA_TEXTURE_TYPE_DISPLACEMENT ],
			[ "emissive", GMA_TEXTURE_TYPE_EMISSIVE ],
			[ "lightmap", GMA_TEXTURE_TYPE_LIGHTMAP ],
			[ "height", GMA_TEXTURE_TYPE_HEIGHT ],
			[ "opacity", GMA_TEXTURE_TYPE_OPACITY ],
			[ "specular", GMA_TEXTURE_TYPE_SPECULAR ],
			[ "unknown", GMA_TEXTURE_TYPE_UNKNOWN ],
		];
		
		for (var i = 0, len = array_length(material_types); i < len; i++) {
			var material_type = material_types[i];
			var material_type_str = material_type[0];
            var txt_name = GMA_GetMaterialTextureName(material_type[1], 0);
			var fname = filename_name(txt_name);
            log(material_type, material_type_str, txt_name)
		
			if (fname != "") {
				textures[$ material_type_str] = store_material_texture(model_path, material_type_str, fname);
			}
		}
	}
	
	/// @ignore
	static read_binded_mesh = function(mesh) {
        var mesh_facenum = GMA_GetMeshFacesNum();
        var mesh_channel_num_color = GMA_GetMeshColorChannelsNum();
        var mesh_channel_num_texcoord = GMA_GetMeshUVChannelsNum();
        
        var total_verts_estimate = mesh_facenum * 3;
        
        var vertices = array_create(total_verts_estimate);
        
        var vert_count = 0;
        
        for (var f = 0; f < mesh_facenum; f++) {
            var fn = GMA_GetMeshFaceVerticesNum(f);
        
            for (var fi = 0; fi < fn; fi++) {
                var v = GMA_GetMeshFaceVertexIndex(f, fi);
        
                var vx = GMA_GetMeshVertexX(v);
                var vy = GMA_GetMeshVertexY(v);
                var vz = GMA_GetMeshVertexZ(v);
        
                var nx = GMA_GetMeshNormalX(v);
                var ny = GMA_GetMeshNormalY(v);
                var nz = GMA_GetMeshNormalZ(v);
        
                var uu = (mesh_channel_num_texcoord > 0) ? GMA_GetMeshTexCoordU(v, 0) : 0;
                var vv = (mesh_channel_num_texcoord > 0) ? GMA_GetMeshTexCoordV(v, 0) : 0;
        
                var col = c_white;
                var alpha = 1;
                if (mesh_channel_num_color > 0) {
                    col = make_color_rgb(GMA_GetMeshVertexColorGM(v, 0), GMA_GetMeshVertexColorGM(v, 1), GMA_GetMeshVertexColorGM(v, 2));
                    alpha = GMA_GetMeshVertexAlpha(v, 0);
                }
        
                vertices[vert_count++] = {
                    x: vx, y: vy, z: vz,
                    nx: nx, ny: ny, nz: nz,
                    u: uu, v: vv,
                    color: col,
                    alpha: alpha
                };
            }
        }
        
        array_resize(vertices, vert_count);

		// Store the bounding box
		//var x1 = GMA_GetMeshAABBMinX();
		//var y1 = GMA_GetMeshAABBMinY();
		//var z1 = GMA_GetMeshAABBMinZ();
		//var x2 = GMA_GetMeshAABBMaxX();
		//var y2 = GMA_GetMeshAABBMaxY();
		//var z2 = GMA_GetMeshAABBMaxZ();
		//mesh.boundingBox = { x1, y1, z1, x2, y2, z2, x_size: x2 - x1, y_size: y2 - y1, z_size: z2 - z1 };
		//mesh.boundingBoxRelative = { x1, y1, z1, x2, y2, z2, x_size: x2 - x1, y_size: y2 - y1, z_size: z2 - z1 };
		
		// Update the mesh stats
		//mesh.faces_count = mesh_facenum;
		//mesh.vertices_count = mesh_vnum;
        
        //vertex_end(vb);
        //vertex_freeze(vb);
        mesh.geometry = new BufferGeometry({ vertices });
        //mesh.geometry.vb = vb;
	}
	
	/**
	 * Import a model and extract its material and meshes
	 */
	static load = function(filename) {
		if (!GMA_IsWorking()) {
			return show_error("Assimp extension is not working", true);
		}
		
		var assimp_importer = GMA_CreateImporter();
		GMA_BindImporter(assimp_importer);
		
		var check = GMA_ReadFile(filename,
			GMA_PP.GEN_BOUNDING_BOXES |
			
			GMA_PP.MAKE_LEFT_HANDED |
			GMA_PP.FLIP_UVS |
			GMA_PP.FLIP_WINDING_ORDER |
			
			// Fast
			GMA_PP.CALC_TANGENT_SPACE |
			GMA_PP.GEN_NORMALS |
			GMA_PP.JOIN_IDENTICAL_VERTICES |
			GMA_PP.GEN_UV_COORDS |
			GMA_PP.SORT_BY_PTYPE |
			
			// Quality
			GMA_PP.CALC_TANGENT_SPACE |
			//GMA_PP.GEN_SMOOTH_NORMALS | // Not needed
			GMA_PP.JOIN_IDENTICAL_VERTICES |
			GMA_PP.IMPROVE_CACHE_LOCALITY | 
			//GMA_PP.LIMIT_BONE_WEIGHTS | // @todo: test
			//GMA_PP.REMOVE_REDUNDANT_MATERIALS | // Let the user handle all materials
			//GMA_PP.SPLIT_LARGE_MESHES | // @todo: test, is it needed?
			GMA_PP.TRIANGULATE |
			GMA_PP.GEN_UV_COORDS |
			GMA_PP.SORT_BY_PTYPE |
			GMA_PP.FIND_DEGENERATES |
			GMA_PP.FIND_INVALID_DATA
			
			// Max quality
			//GMA_PP.FIND_INSTANCES | // random vertices count??
			//GMA_PP.VALIDATE_DATA_STRUCTURE |
			//GMA_PP.OPTIMIZE_GRAPH | 
			//GMA_PP.OPTIMIZE_MESHES 
		);

		// Check if the file is correctly loaded
		if (!check) {	
			show_message_async("[Assimp Importer] Error: " + GMA_GetImporterErrorString());
			return;
		}

		GMA_BindScene();
        var model_path = filename_path(filename);
		
		// Get the materials
		var materials = [];		
		var materials_count = GMA_GetMaterialNum();
		for (var i=0; i<materials_count; i++)	{
		    GMA_BindMaterial(i);
			var material = new MeshStandardMaterial();
            material.side = cull_clockwise
			read_binded_material(material, model_path);
            var spr = sprite_add("11804_Airplane_diff.jpg", 1, false, false, 0, 0);
            //var spr = sprite_add("Cat_diffuse.jpg", 1, false, false, 0, 0);
            var txt = new Texture({ image: spr })
            material.textures.map = txt;
            material.build();
			materials[i] = material;
		}
				
		// Add the meshes data
        var model = new Mesh();
        
		for (var i = 0; i < GMA_GetMeshNum(); i++)	{
		    GMA_BindMesh(i);
			var mesh = new Mesh();
			mesh.name = GMA_GetMeshName();
			read_binded_mesh(mesh);
			mesh.material = materials[GMA_GetMeshMaterialIndex()];
			model.add(mesh);
		}
		
		//var animations_count = GMA_GetAnimationNum();
		//for (var i = 0; i < animations_count; i++) {
		//	GMA_BindAnimation(i);
			
		//	GMA_GetAnimationMeshChannelsNum()
		//	GMA_GetAnimationTicksPerSecond()
		//	//GMA_GetMeshAnimKeyTime()
		//	//GMA_GetMeshAnimKeyValue()
		//	//GMA_GetMeshAnimKeysNum()
		//	//GMA_GetMeshAnimNodeName()
		//	//GMA_GetAnimationName()
		//	//GMA_BindMeshAnimation()
		//	//GMA_BindNodeAnimation()
		//	//GMA_BindNodeChild()
		//	//GMA_BindNodeChildFromName()
		//	//GMA_BindNodeMatrix()
		//	//GMA_BindNodeParent()
		//	//GMA_BindBoneOffsetMatrix()
		//	//GMA_GetBoneName()
		//	//GMA_GetBoneNumWeights()
		//	//GMA_GetBoneVertexIndex()
		//	//GMA_GetBoneVertexWeight()			
		//	//GMA_BindSceneNode()
		//	//GMA_GetNodeName()
		//	//etc.
		//}
			
		GMA_DeleteImporter(assimp_importer);
		
		// Start with a default Y/Z rotation of the model
        model.rotateX(180);
        model.rotateZ(180);
		
		//model.materials_count = materials_count;
		//model.animations_num = animations_count;
		//model.calculate_relative_bbox();
		return model;
	}
}
