function UeAssimpLoader(data = {}) constructor {
  if (!ASSIMP_IsWorking()) ueError("Assimp extension is not working");

  importer = ASSIMP_CreateImporter();
  ASSIMP_BindImporter(importer);

  function load(fname) {
    gml_pragma("forceinline");
    var check = ASSIMP_ReadFile(fname,
      ASSIMP_PP.GEN_BOUNDING_BOXES |

      ASSIMP_PP.FLIP_UVS |
      ASSIMP_PP.FLIP_WINDING_ORDER |

      // Fast
      // ASSIMP_PP.CALC_TANGENT_SPACE |
      ASSIMP_PP.GEN_NORMALS |
      // ASSIMP_PP.JOIN_IDENTICAL_VERTICES |
      // ASSIMP_PP.GEN_UV_COORDS |
      // ASSIMP_PP.SORT_BY_PTYPE |

      // Quality
      ASSIMP_PP.CALC_TANGENT_SPACE |
      //ASSIMP_PP.GEN_SMOOTH_NORMALS | // Not needed probably
      ASSIMP_PP.JOIN_IDENTICAL_VERTICES |
      ASSIMP_PP.IMPROVE_CACHE_LOCALITY |
      //ASSIMP_PP.LIMIT_BONE_WEIGHTS | // @todo: test
      ASSIMP_PP.TRIANGULATE |
      ASSIMP_PP.GEN_UV_COORDS |
      ASSIMP_PP.SORT_BY_PTYPE |
      ASSIMP_PP.FIND_DEGENERATES |
      ASSIMP_PP.FIND_INVALID_DATA

      // Max quality
      //ASSIMP_PP.FIND_INSTANCES | // @todo Random vertices count?? To test
      //ASSIMP_PP.VALIDATE_DATA_STRUCTURE |
      //ASSIMP_PP.OPTIMIZE_GRAPH | 
      //ASSIMP_PP.OPTIMIZE_MESHES 
    );

    // Check if the file is correctly loaded
    if (!check) {
      ueError($"{ASSIMP_GetImporterErrorString()}");
    }

    ASSIMP_BindScene();
    var textures = [];
    var textureCache = {};
    var materials = _addMaterials(fname, textures, textureCache);
    var model = _addMeshes(materials);
    return {
      textures,
      materials,
      model
    };
  }

  function _addMaterials(fname, textures, textureCache) {
    gml_pragma("forceinline");
    var modelPath = filename_path(fname);
    var modelName = filename_change_ext(filename_name(fname), "");

    // Get the materials
    var materialsCount = ASSIMP_GetMaterialNum();
    var materials = array_create(materialsCount);

    for (var i = 0; i < materialsCount; i++) {
      ASSIMP_BindMaterial(i);
      var material = new UeMeshStandardMaterial(_addTextures(modelPath, textures, textureCache));
      material.name = string_trim(ASSIMP_GetMaterialName());
      if (material.name == "") material.name = modelName + "__Material" + string(i);
      material.opacity = ASSIMP_GetMaterialOpacity();
      material.transparent = material.opacity < 1;
      materials[i] = material;
    }

    return materials;
  }

  function _addTextures(modelPath, globalTextures, textureCache) {
    gml_pragma("forceinline");
    var textures = {};

    var materialTypes = [
      { name: "map", type: ASSIMP_TEXTURE_TYPE.DIFFUSE },
      { name: "normalsMap", type: ASSIMP_TEXTURE_TYPE.NORMALS },
      { name: "ambientOcclusionMap", type: ASSIMP_TEXTURE_TYPE.AMBIENT_OCCLUSION },
      { name: "emissiveMap", type: ASSIMP_TEXTURE_TYPE.EMISSIVE },
      { name: "reflectionMap", type: ASSIMP_TEXTURE_TYPE.REFLECTION },
      { name: "ambientMap", type: ASSIMP_TEXTURE_TYPE.AMBIENT },
      { name: "shininessMap", type: ASSIMP_TEXTURE_TYPE.SHININESS },
      { name: "displacementMap", type: ASSIMP_TEXTURE_TYPE.DISPLACEMENT },
      { name: "lightmapMap", type: ASSIMP_TEXTURE_TYPE.LIGHTMAP },
      { name: "heightMap", type: ASSIMP_TEXTURE_TYPE.HEIGHT },
      { name: "opacityMap", type: ASSIMP_TEXTURE_TYPE.OPACITY },
      { name: "specularMap", type: ASSIMP_TEXTURE_TYPE.SPECULAR },
      { name: "baseColor", type: ASSIMP_TEXTURE_TYPE.BASE_COLOR },
      { name: "clearCotMap", type: ASSIMP_TEXTURE_TYPE.CLEARCOAT },
      { name: "diffuseRoughnessMap", type: ASSIMP_TEXTURE_TYPE.DIFFUSE_ROUGHNESS },
      { name: "emissionColorMap", type: ASSIMP_TEXTURE_TYPE.EMISSION_COLOR },
      { name: "metalnessMap", type: ASSIMP_TEXTURE_TYPE.METALNESS },
      { name: "normalsCameraMap", type: ASSIMP_TEXTURE_TYPE.NORMAL_CAMERA },
      { name: "sheenMap", type: ASSIMP_TEXTURE_TYPE.SHEEN },
      { name: "transmissionMap", type: ASSIMP_TEXTURE_TYPE.TRANSMISSION },
      { name: "unknownMap", type: ASSIMP_TEXTURE_TYPE.UNKNOWN },
    ];

    for (var i = 0, len = array_length(materialTypes); i < len; i++) {
      var materialType = materialTypes[i];

      var txtName = ASSIMP_GetMaterialTextureName(materialType.type, 0);
      if (txtName == "") continue;

      var fileName = filename_name(txtName);
      var txt = undefined;

      // Check cache first
      if (textureCache[$ fileName] != undefined) {
        txt = textureCache[$ fileName];
      } else {
        // Load new texture
        txt = _addTexture(modelPath, fileName);
        if (txt) {
          textureCache[$ fileName] = txt;
          array_push(globalTextures, txt);
        }
      }

      if (txt) {
        textures[$ materialType.name] = txt;
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

    return new UeTexture(image);
  }

  function _addMeshes(materials) {
    gml_pragma("forceinline");
    var model = new UeMesh(new UeGeometry({ canFreeze: false }));

    var meshesCount = ASSIMP_GetMeshNum();
    var meshes = array_create(meshesCount);

    for (var i = 0; i < meshesCount; i++) {
      ASSIMP_BindMesh(i);
      var mesh = _buildMesh();
      mesh.material = materials[ASSIMP_GetMeshMaterialIndex()];
      model.add(mesh);
      meshes[i] = mesh;
    }

    // Calculate model's overall bounding box and sphere based on all meshes
    self._calculateModelBounds(model, meshes);

    return model;
  }

  function _buildMesh() {
    gml_pragma("forceinline");
    var mesh = new UeMesh(new UeGeometry({ canFreeze: false }));
    mesh.name = ASSIMP_GetMeshName();
    var geometry = mesh.geometry;
    var vb = vertex_create_buffer();
    geometry.vb = vb;
    vertex_begin(vb, geometry.format.vf);

    var meshFacenum = ASSIMP_GetMeshFacesNum();
    var meshChannelNumColor = ASSIMP_GetMeshColorChannelsNum();
    var meshChannelNumTexcoord = ASSIMP_GetMeshUVChannelsNum();

    for (var f = 0; f < meshFacenum; f++) {
      var fn = ASSIMP_GetMeshFaceVerticesNum(f);

      for (var fi = 0; fi < fn; fi++) {
        var v = ASSIMP_GetMeshFaceVertexIndex(f, fi);

        vertex_position_3d(vb, ASSIMP_GetMeshVertexX(v), ASSIMP_GetMeshVertexY(v), ASSIMP_GetMeshVertexZ(v));

        vertex_normal(vb, ASSIMP_GetMeshNormalX(v), ASSIMP_GetMeshNormalY(v), ASSIMP_GetMeshNormalZ(v));

        vertex_texcoord(vb,
          meshChannelNumTexcoord > 0 ? ASSIMP_GetMeshTexCoordU(v, 0) : 0,
          meshChannelNumTexcoord > 0 ? ASSIMP_GetMeshTexCoordV(v, 0) : 0
        );

        vertex_color(vb,
          meshChannelNumColor > 0 ? make_color_rgb(ASSIMP_GetMeshVertexColorGM(v, 0), ASSIMP_GetMeshVertexColorGM(v, 1), ASSIMP_GetMeshVertexColorGM(v, 2)) : c_white,
          meshChannelNumColor > 0 ? ASSIMP_GetMeshVertexAlpha(v, 0) : 1);
      }
    }
    vertex_end(vb);

    // Store the bounding box
    var x1 = ASSIMP_GetMeshAABBMinX();
    var y1 = ASSIMP_GetMeshAABBMinY();
    var z1 = ASSIMP_GetMeshAABBMinZ();
    var x2 = ASSIMP_GetMeshAABBMaxX();
    var y2 = ASSIMP_GetMeshAABBMaxY();
    var z2 = ASSIMP_GetMeshAABBMaxZ();

    var minV = vec3_create(x1, y1, z1);
    var maxV = vec3_create(x2, y2, z2);

    geometry.boundingBox = box3_create(minV, maxV);

    var center = vec3_clone(minV); vec3_add(center, maxV); vec3_multiply_scalar(center, 0.5);
    geometry.boundingSphere = sphere_create(center, vec3_distance_to(center, maxV));

    return mesh;
  }

  function _calculateModelBounds(model, meshes) {
    gml_pragma("forceinline");
    if (array_length(meshes) == 0) return;

    // Initialize with first mesh bounds
    var firstGeometry = meshes[0].geometry;
    if (firstGeometry.boundingBox == undefined) return;

    var minX = firstGeometry.boundingBox[BOX3.minX];
    var minY = firstGeometry.boundingBox[BOX3.minY];
    var minZ = firstGeometry.boundingBox[BOX3.minZ];
    var maxX = firstGeometry.boundingBox[BOX3.maxX];
    var maxY = firstGeometry.boundingBox[BOX3.maxY];
    var maxZ = firstGeometry.boundingBox[BOX3.maxZ];

    // Expand bounds for all other meshes
    for (var i = 1, il = array_length(meshes); i < il; i++) {
      var geometry = meshes[i].geometry;
      if (geometry.boundingBox == undefined) continue;

      minX = min(minX, geometry.boundingBox[BOX3.minX]);
      minY = min(minY, geometry.boundingBox[BOX3.minY]);
      minZ = min(minZ, geometry.boundingBox[BOX3.minZ]);
      maxX = max(maxX, geometry.boundingBox[BOX3.maxX]);
      maxY = max(maxY, geometry.boundingBox[BOX3.maxY]);
      maxZ = max(maxZ, geometry.boundingBox[BOX3.maxZ]);
    }

    // Set model's overall bounding box
    var minV = vec3_create(minX, minY, minZ);
    var maxV = vec3_create(maxX, maxY, maxZ);

    firstGeometry.boundingBox = box3_create(minV, maxV);

    var center = vec3_clone(minV); vec3_add(center, maxV); vec3_multiply_scalar(center, 0.5);
    firstGeometry.boundingSphere = sphere_create(center, vec3_distance_to(center, maxV));
  }

  function dispose() {
    gml_pragma("forceinline");
    ASSIMP_DeleteImporter(importer);
    return self;
  }
}
