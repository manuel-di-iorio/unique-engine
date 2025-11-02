function UeAssimpLoader(data = {}) constructor {
    if (!GMA_IsWorking()) ueError("Assimp extension is not working");
    
    importer = GMA_CreateImporter();
    GMA_BindImporter(importer);
    
    function load(fname) {
        gml_pragma("forceinline");
		var check = GMA_ReadFile(fname,
			GMA_PP.GEN_BOUNDING_BOXES |
			
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
			//GMA_PP.GEN_SMOOTH_NORMALS | // Not needed probably
			GMA_PP.JOIN_IDENTICAL_VERTICES |
			GMA_PP.IMPROVE_CACHE_LOCALITY | 
			//GMA_PP.LIMIT_BONE_WEIGHTS | // @todo: test
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
			ueError($"{GMA_GetImporterErrorString()}");
		}

		GMA_BindScene();
        var textures = [];
        var materials = _addMaterials(fname, textures);
        var model = _addMeshes(materials);
        return {
            textures,
            materials,
            model
        };
    }
    
    function _addMaterials(fname, textures) {
        gml_pragma("forceinline");
        var modelPath = filename_path(fname);
        var modelName = filename_change_ext(filename_name(fname), "");
		
		// Get the materials
		var materialsCount = GMA_GetMaterialNum();
        var materials = array_create(materialsCount);
        
        for (var i=0; i<materialsCount; i++) {
		    GMA_BindMaterial(i);
            var material = new UeMeshStandardMaterial(_addTextures(modelPath, textures));
            material.name = string_trim(GMA_GetMaterialName());
            if (material.name == "") material.name = modelName + "__Material" + string(i);
            material.opacity = GMA_GetMaterialOpacity();
            material.transparent = material.opacity < 1;
            materials[i] = material;
		}
        
        return materials;
    }

    function _addTextures(modelPath, globalTextures) {
        gml_pragma("forceinline");
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
            if (txt) {
                textures[$ materialType.name] = txt;
                array_push(globalTextures, txt);
            }
        }

        return textures;
    }
    
    function _addTexture(modelPath, fname) {
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        var model = new UeMesh();
        var meshes = [];
        
        for (var i = 0, n = GMA_GetMeshNum(); i < n; i++) {
		    GMA_BindMesh(i);
			var mesh = _buildMesh();
			mesh.material = materials[GMA_GetMeshMaterialIndex()];
			model.add(mesh);
			array_push(meshes, mesh);
		}
        
        // Calculate model's overall bounding box and sphere based on all meshes
        self._calculateModelBounds(model, meshes);
        
        // Rotate the model to match the engine camera directions
        // @todo This is temporary
        // model.rotateZ(180);
        // model.updateMatrix();
        // model.updateMatrixWorld(true);
        
        return model;
    }
    
    function _buildMesh() {
        gml_pragma("forceinline");
        var mesh = new UeMesh(new UeBufferGeometry());
        mesh.name = GMA_GetMeshName();
        var geometry = mesh.geometry;
        var vb = vertex_create_buffer();
        geometry.vb = vb;
        vertex_begin(vb, geometry.format.vf);
        
        var meshFacenum = GMA_GetMeshFacesNum();
        var meshChannelNumColor = GMA_GetMeshColorChannelsNum();
        var meshChannelNumTexcoord = GMA_GetMeshUVChannelsNum();
        
        for (var f = 0; f < meshFacenum; f++) {
            var fn = GMA_GetMeshFaceVerticesNum(f);
        
            for (var fi = 0; fi < fn; fi++) {
                var v = GMA_GetMeshFaceVertexIndex(f, fi);
        
                vertex_position_3d(vb, GMA_GetMeshVertexX(v), GMA_GetMeshVertexY(v), GMA_GetMeshVertexZ(v));
                
                vertex_normal(vb, GMA_GetMeshNormalX(v), GMA_GetMeshNormalY(v), GMA_GetMeshNormalZ(v));
                
                vertex_texcoord(vb, 
                    meshChannelNumTexcoord > 0 ? GMA_GetMeshTexCoordU(v, 0) : 0,
                    meshChannelNumTexcoord > 0 ? GMA_GetMeshTexCoordV(v, 0) : 0
                );
                
                vertex_color(vb, 
                    meshChannelNumColor > 0 ? make_color_rgb(GMA_GetMeshVertexColorGM(v, 0), GMA_GetMeshVertexColorGM(v, 1), GMA_GetMeshVertexColorGM(v, 2)) : c_white, 
                    meshChannelNumColor > 0 ? GMA_GetMeshVertexAlpha(v, 0) : 1);
            }
        }
        vertex_end(vb);
        
		// Store the bounding box
		var x1 = GMA_GetMeshAABBMinX();
		var y1 = GMA_GetMeshAABBMinY();
		var z1 = GMA_GetMeshAABBMinZ();
		var x2 = GMA_GetMeshAABBMaxX();
		var y2 = GMA_GetMeshAABBMaxY();
		var z2 = GMA_GetMeshAABBMaxZ();
        var minV = new UeVector3(x1, y1, z1);
        var maxV = new UeVector3(x2, y2, z2);
        
        geometry.boundingBox = new UeBox3(minV, maxV);
        
        var center = minV.clone().add(maxV).multiplyScalar(0.5);
        geometry.boundingSphere = new UeSphere(center, center.distanceTo(maxV));
        
        return mesh;
    }
    
    function _calculateModelBounds(model, meshes) {
        gml_pragma("forceinline");
        if (array_length(meshes) == 0) return;
        
        // Initialize with first mesh bounds
        var firstGeometry = meshes[0].geometry;
        if (!firstGeometry.boundingBox) return;
        
        var minX = firstGeometry.boundingBox.sizeMin.x;
        var minY = firstGeometry.boundingBox.sizeMin.y;
        var minZ = firstGeometry.boundingBox.sizeMin.z;
        var maxX = firstGeometry.boundingBox.sizeMax.x;
        var maxY = firstGeometry.boundingBox.sizeMax.y;
        var maxZ = firstGeometry.boundingBox.sizeMax.z;

        // Expand bounds for all other meshes
        for (var i = 1; i < array_length(meshes); i++) {
            var geometry = meshes[i].geometry;
            if (geometry.boundingBox == undefined) continue;
            
            minX = min(minX, geometry.boundingBox.sizeMin.x);
            minY = min(minY, geometry.boundingBox.sizeMin.y);
            minZ = min(minZ, geometry.boundingBox.sizeMin.z);
            maxX = max(maxX, geometry.boundingBox.sizeMax.x);
            maxY = max(maxY, geometry.boundingBox.sizeMax.y);
            maxZ = max(maxZ, geometry.boundingBox.sizeMax.z);
        }
        
        // Set model's overall bounding box
        var minV = new UeVector3(minX, minY, minZ);
        var maxV = new UeVector3(maxX, maxY, maxZ);
        
        // Create geometry for the model if it doesn't exist
        if (!model.geometry) {
            model.geometry = new UeBufferGeometry();
        }
        
        model.geometry.boundingBox = new UeBox3(minV, maxV);
        
        // Calculate bounding sphere from overall bounding box
        var center = minV.clone().add(maxV).multiplyScalar(0.5);
        var radius = center.distanceTo(maxV);
        model.geometry.boundingSphere = new UeSphere(center, radius);
    }
    
    function dispose() {
        gml_pragma("forceinline");
        GMA_DeleteImporter(importer);
        return self;
    }
}
