function UeAssimpLoader(data = {}) constructor {
    if (!GMA_IsWorking()) {
        throw "[Unique Engine] AssimpLoaderError: Assimp extension is not working";
    }
    
    importer = GMA_CreateImporter();
    GMA_BindImporter(importer);
    
    function load(fname) {
		var check = GMA_ReadFile(fname,
			GMA_PP.GEN_BOUNDING_BOXES |
			
			//GMA_PP.MAKE_LEFT_HANDED |
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
			//GMA_PP.FIND_INSTANCES | // @todo Random vertices count?? To test
			//GMA_PP.VALIDATE_DATA_STRUCTURE |
			//GMA_PP.OPTIMIZE_GRAPH | 
			//GMA_PP.OPTIMIZE_MESHES 
		);

		// Check if the file is correctly loaded
		if (!check) {	
			throw "[Unique Engine] AssimpLoaderError: " + GMA_GetImporterErrorString();
		}

		GMA_BindScene();
        var materials = _addMaterials(fname);
        var model = _addMeshes(materials);
        return model; 
    }
    
    function _addMaterials(fname) {
        var modelPath = filename_path(fname);
		
		// Get the materials
		var materialsCount = GMA_GetMaterialNum();
        var materials = array_create(materialsCount);
        
        for (var i=0; i<materialsCount; i++)	{
		    GMA_BindMaterial(i);
            materials[i] = new UeMeshStandardMaterial(_addTextures(modelPath));
		}
        
        return materials;
    }
    
    function _addTextures(modelPath) {
        var textures = {};
        
        var materialTypes = [
			{ name: "map", type: GMA_TEXTURE_TYPE_DIFFUSE },
			{ name: "normalMap", type: GMA_TEXTURE_TYPE_NORMALS },
            { name: "aoMap", type: GMA_TEXTURE_AMBIENT_OCCLUSION },
            { name: "emissiveMap", type: GMA_TEXTURE_TYPE_EMISSIVE },
			{ name: "reflectionMap", type: GMA_TEXTURE_TYPE_REFLECTION },
            { name: "ambientMap", type: GMA_TEXTURE_TYPE_AMBIENT },
			{ name: "shininessMap", type: GMA_TEXTURE_TYPE_SHININESS },
			{ name: "displacementMap", type: GMA_TEXTURE_TYPE_DISPLACEMENT },
			{ name: "lightmapMap", type: GMA_TEXTURE_TYPE_LIGHTMAP },
			{ name: "heightMap", type: GMA_TEXTURE_TYPE_HEIGHT },
			{ name: "opacityMap", type: GMA_TEXTURE_TYPE_OPACITY },
			{ name: "specularMap", type: GMA_TEXTURE_TYPE_SPECULAR },
			{ name: "unknownMap", type: GMA_TEXTURE_TYPE_UNKNOWN },
		];
		
		for (var i = 0, len = array_length(materialTypes); i < len; i++) {
			var materialType = materialTypes[i];
            var txtName = GMA_GetMaterialTextureName(materialType.type, 0);
            var txt = _addTexture(modelPath, filename_name(txtName));
            if (txt) textures[$ materialType.name] = txt;
        }

        return textures;
    }
    
    function _addTexture(modelPath, fname) {
        var fullPath = modelPath + "/" + fname;
			
        if (!file_exists(fullPath)) {
            fullPath = modelPath + "/" + filename_change_ext(fname, ".jpg");
            
            if (!file_exists(fullPath)) {
                fullPath = modelPath + "/" + filename_change_ext(fname, ".png");
            }
        }
			
        var image = sprite_add(fullPath, 1, false, false, 0, 0);
        if (image == -1) return undefined;
        
        return new UeTexture({ image });
    }
    
    function _addMeshes(materials) {
        var model = new UeMesh();
        
        for (var i = 0, n = GMA_GetMeshNum(); i < n; i++) {
		    GMA_BindMesh(i);
			var mesh = _buildMesh();
			mesh.material = materials[GMA_GetMeshMaterialIndex()];
			model.add(mesh);
		}
        
        // Rotate the model to match the engine camera directions
        model.rotateZ(180);
        
        return model;
    }
    
    function _buildMesh() {
        var mesh = new UeMesh();
        mesh.name = GMA_GetMeshName();
        var meshFacenum = GMA_GetMeshFacesNum();
        var meshChannelNumColor = GMA_GetMeshColorChannelsNum();
        var meshChannelNumTexcoord = GMA_GetMeshUVChannelsNum();
        var totalVertsEstimate = meshFacenum * 3;
        var vertices = array_create(totalVertsEstimate);
        var verticesCount = 0;
        
        for (var f = 0; f < meshFacenum; f++) {
            var fn = GMA_GetMeshFaceVerticesNum(f);
        
            for (var fi = 0; fi < fn; fi++) {
                var v = GMA_GetMeshFaceVertexIndex(f, fi);
        
                var vx = GMA_GetMeshVertexX(v);
                var vy = GMA_GetMeshVertexY(v);
                var vz = GMA_GetMeshVertexZ(v);
        
                var nx = GMA_GetMeshNormalX(v);
                var ny = GMA_GetMeshNormalY(v);
                var nz = GMA_GetMeshNormalZ(v);
        
                var uu = (meshChannelNumTexcoord > 0) ? GMA_GetMeshTexCoordU(v, 0) : 0;
                var vv = (meshChannelNumTexcoord > 0) ? GMA_GetMeshTexCoordV(v, 0) : 0;
        
                var col = c_white;
                var alpha = 1;
                if (meshChannelNumColor > 0) {
                    col = make_color_rgb(GMA_GetMeshVertexColorGM(v, 0), GMA_GetMeshVertexColorGM(v, 1), GMA_GetMeshVertexColorGM(v, 2));
                    alpha = GMA_GetMeshVertexAlpha(v, 0);
                }
        
                vertices[verticesCount++] = {
                    x: vx, y: vy, z: vz,
                    nx: nx, ny: ny, nz: nz,
                    u: uu, v: vv,
                    color: col,
                    alpha: alpha
                };
            }
        }
        
        array_resize(vertices, verticesCount);

		// Store the bounding box
		//var x1 = GMA_GetMeshAABBMinX();
		//var y1 = GMA_GetMeshAABBMinY();
		//var z1 = GMA_GetMeshAABBMinZ();
		//var x2 = GMA_GetMeshAABBMaxX();
		//var y2 = GMA_GetMeshAABBMaxY();
		//var z2 = GMA_GetMeshAABBMaxZ();
		//mesh.boundingBox = { x1, y1, z1, x2, y2, z2, x_size: x2 - x1, y_size: y2 - y1, z_size: z2 - z1 };
		//mesh.boundingBoxRelative = { x1, y1, z1, x2, y2, z2, x_size: x2 - x1, y_size: y2 - y1, z_size: z2 - z1 };
		
        mesh.geometry = new UeBufferGeometry({ vertices, canFreeze: false });
        return mesh;
    }
    
    function dispose() {
        GMA_DeleteImporter(importer);
        return self;
    }
}