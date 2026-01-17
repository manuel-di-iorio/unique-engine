function UeAssimpLoader(data = {}) constructor {
  if (!ASSIMP_IsWorking()) ueError("Assimp extension is not working");

  importer = ASSIMP_CreateImporter();
  ASSIMP_BindImporter(importer);

  nodeMap = {};
  boneMap = {};

  function load(fname) {
    gml_pragma("forceinline");
    var check = ASSIMP_ReadFile(fname,
      ASSIMP_PP.GEN_BOUNDING_BOXES |
      ASSIMP_PP.FLIP_UVS |
      ASSIMP_PP.FLIP_WINDING_ORDER |
      ASSIMP_PP.CALC_TANGENT_SPACE |
      ASSIMP_PP.GEN_SMOOTH_NORMALS |
      ASSIMP_PP.JOIN_IDENTICAL_VERTICES |
      ASSIMP_PP.IMPROVE_CACHE_LOCALITY |
      ASSIMP_PP.TRIANGULATE |
      ASSIMP_PP.GEN_UV_COORDS |
      ASSIMP_PP.SORT_BY_PTYPE |
      ASSIMP_PP.FIND_DEGENERATES |
      ASSIMP_PP.FIND_INVALID_DATA
    );

    if (!check) {
      ueError($"{ASSIMP_GetImporterErrorString()}");
    }

    ASSIMP_BindScene();

    // 1. Materials & Textures
    var textures = [];
    var textureCache = {};
    var materials = _addMaterials(fname, textures, textureCache);

    // 2. Scene Graph & Node Map
    nodeMap = {};
    var root = _buildSceneGraph();

    // 3. Meshes & Bone Data
    boneMap = {};
    var meshesResult = _addMeshes(materials.list);
    var boneData = meshesResult.boneData;

    // 4. Skeleton construction
    var skeleton = undefined;
    if (array_length(boneData) > 0) {
      skeleton = _buildSkeleton(boneData, root);
      _assignSkeletonToMeshes(meshesResult.meshes, skeleton);
    }

    // 5. Link meshes to scene graph nodes
    _linkMeshesToGraph(root, meshesResult.meshes);

    // 6. Calculate total bounds for the model (the root Object3D)
    root.updateMatrixWorld(true);
    self._calculateModelBounds(root, meshesResult.meshes);

    // 7. Animations
    var animations = _addAnimations();

    return {
      textures,
      materials: materials.map,
      root,
      skeleton,
      animations: animations.map
    };
  }

  function _assignSkeletonToMeshes(meshes, skeleton) {
    for (var i = 0, il = array_length(meshes); i < il; i++) {
      var mesh = meshes[i];
      if (mesh.bindMode == "skinned") {
        mesh.skeleton = skeleton;
      }
    }
  }

  function _getMatrix() {
    gml_pragma("forceinline");
    return [
      ASSIMP_GetMatrixA1(), ASSIMP_GetMatrixB1(), ASSIMP_GetMatrixC1(), ASSIMP_GetMatrixD1(),
      ASSIMP_GetMatrixA2(), ASSIMP_GetMatrixB2(), ASSIMP_GetMatrixC2(), ASSIMP_GetMatrixD2(),
      ASSIMP_GetMatrixA3(), ASSIMP_GetMatrixB3(), ASSIMP_GetMatrixC3(), ASSIMP_GetMatrixD3(),
      ASSIMP_GetMatrixA4(), ASSIMP_GetMatrixB4(), ASSIMP_GetMatrixC4(), ASSIMP_GetMatrixD4()
    ];
  }

  function _buildSceneGraph(nodeId = -1) {
    gml_pragma("forceinline");
    if (nodeId == -1) {
      ASSIMP_BindSceneNode();
    } else {
      ASSIMP_BindNodeChild(nodeId);
    }

    var name = ASSIMP_GetNodeName();
    ASSIMP_BindNodeMatrix();
    var matrix = _getMatrix();

    var object = new UeObject3D();
    object.name = name;
    nodeMap[$ name] = object;

    mat4_copy(object.matrix, matrix);
    mat4_decompose(object.matrix, object.position, object.rotation, object.scale);

    var childCount = ASSIMP_GetNodeChildrenNum();
    for (var i = 0; i < childCount; i++) {
      object.add(_buildSceneGraph(i));
      ASSIMP_BindNodeParent();
    }

    return object;
  }

  function _addMaterials(fname, textures, textureCache) {
    gml_pragma("forceinline");
    var modelPath = filename_path(fname);
    var modelName = filename_change_ext(filename_name(fname), "");

    // Get the materials
    var materialsCount = ASSIMP_GetMaterialNum();
    var materials = array_create(materialsCount);
    var materialsMap = {};

    for (var i = 0; i < materialsCount; i++) {
      ASSIMP_BindMaterial(i);
      var material = new UeMeshStandardMaterial(_addTextures(modelPath, textures, textureCache));
      material.name = string_trim(ASSIMP_GetMaterialName());
      if (material.name == "") material.name = modelName + "__Material" + string(i);
      material.opacity = ASSIMP_GetMaterialOpacity();
      material.transparent = material.opacity < 1;
      materials[i] = material;
      materialsMap[$ material.name] = material;
    }

    return {
      list: materials,
      map: materialsMap
    };
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
      { name: "baseColorMap", type: ASSIMP_TEXTURE_TYPE.BASE_COLOR },
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

    var meshesCount = ASSIMP_GetMeshNum();
    var meshes = array_create(meshesCount);
    var boneData = [];
    boneMap = {}; // Reset bone map for this model

    for (var i = 0; i < meshesCount; i++) {
      ASSIMP_BindMesh(i);
      var meshResult = _buildMesh(boneData);
      var mesh = meshResult.mesh;
      mesh.material = materials[ASSIMP_GetMeshMaterialIndex()];
      meshes[i] = mesh;
    }

    return {
      meshes,
      boneData
    };
  }

  function _buildMesh(globalBoneData) {
    gml_pragma("forceinline");
    var hasBones = ASSIMP_MeshHasBones();
    var geometry = new UeGeometry({ canFreeze: false });

    // Set up vertex format
    var mesh = new UeMesh(geometry);
    mesh.name = ASSIMP_GetMeshName();
    mesh.bindMode = hasBones ? "skinned" : "attached";

    var vb = vertex_create_buffer();
    geometry.vb = vb;
    vertex_begin(vb, global.UE_VFORMAT_PNUTCB.vf);

    var meshFacenum = ASSIMP_GetMeshFacesNum();
    var meshChannelNumColor = ASSIMP_GetMeshColorChannelsNum();
    var meshChannelNumTexcoord = ASSIMP_GetMeshUVChannelsNum();
    var vertexCount = ASSIMP_GetMeshVerticesNum();

    // Collect bone weights for each vertex if mesh has bones
    var vertBones = undefined;
    if (hasBones) {
      vertBones = array_create(vertexCount);
      for (var v = 0; v < vertexCount; v++) {
        vertBones[v] = { indices: [0, 0, 0, 0], weights: [0, 0, 0, 0], count: 0 };
      }

      var boneCount = ASSIMP_GetMeshBonesNum();
      for (var b = 0; b < boneCount; b++) {
        ASSIMP_BindMeshBone(b);
        var boneName = ASSIMP_GetBoneName();

        // Register bone in global list if not already there (using boneMap for O(1) lookup)
        var boneIdx = boneMap[$ boneName];
        if (boneIdx == undefined) {
          ASSIMP_BindBoneOffsetMatrix();
          var offsetMatrix = _getMatrix();
          boneIdx = array_length(globalBoneData);
          boneMap[$ boneName] = boneIdx;
          array_push(globalBoneData, { name: boneName, offsetMatrix: offsetMatrix });
        }

        var weightsCount = ASSIMP_GetBoneNumWeights();
        for (var w = 0; w < weightsCount; w++) {
          var vIdx = ASSIMP_GetBoneVertexIndex(w);
          var weight = ASSIMP_GetBoneVertexWeight(w);

          var vbData = vertBones[vIdx];
          if (vbData.count < 4) {
            vbData.indices[vbData.count] = boneIdx;
            vbData.weights[vbData.count] = weight;
            vbData.count++;
          }
        }
      }
    }

    for (var f = 0; f < meshFacenum; f++) {
      var fn = ASSIMP_GetMeshFaceVerticesNum(f);

      for (var fi = 0; fi < fn; fi++) {
        var v = ASSIMP_GetMeshFaceVertexIndex(f, fi);

        var vx = ASSIMP_GetMeshVertexX(v);
        var vy = ASSIMP_GetMeshVertexY(v);
        var vz = ASSIMP_GetMeshVertexZ(v);
        vertex_position_3d(vb, vx, vy, vz);

        var nx = ASSIMP_GetMeshNormalX(v);
        var ny = ASSIMP_GetMeshNormalY(v);
        var nz = ASSIMP_GetMeshNormalZ(v);
        vertex_normal(vb, nx, ny, nz);

        var tx = 0, ty = 0, tz = 0;
        if (meshChannelNumTexcoord > 0) {
          tx = ASSIMP_GetMeshTexCoordU(v, 0);
          ty = ASSIMP_GetMeshTexCoordV(v, 0);
        }
        vertex_texcoord(vb, tx, ty);

        // Tangent & Handedness (W)
        var tanX = ASSIMP_GetMeshTangentX(v);
        var tanY = ASSIMP_GetMeshTangentY(v);
        var tanZ = ASSIMP_GetMeshTangentZ(v);

        var bitanX = ASSIMP_GetMeshBitangentX(v);
        var bitanY = ASSIMP_GetMeshBitangentY(v);
        var bitanZ = ASSIMP_GetMeshBitangentZ(v);

        // Handedness: dot(cross(N, T), B) < 0 ? -1 : 1
        var cx = ny * tanZ - nz * tanY;
        var cy = nz * tanX - nx * tanZ;
        var cz = nx * tanY - ny * tanX;
        var dot = cx * bitanX + cy * bitanY + cz * bitanZ;
        var w = (dot < 0) ? -1.0 : 1.0;
        vertex_float4(vb, tanX, tanY, tanZ, w);

        if (meshChannelNumColor > 0) {
          vertex_color(vb,
            make_color_rgb(ASSIMP_GetMeshVertexColorGM(v, 0), ASSIMP_GetMeshVertexColorGM(v, 1), ASSIMP_GetMeshVertexColorGM(v, 2)),
            ASSIMP_GetMeshVertexAlpha(v, 0)
          );
        } else {
          vertex_color(vb, c_white, 1.0);
        }

        if (hasBones) {
          var vbData = vertBones[v];
          vertex_ubyte4(vb, vbData.indices[0], vbData.indices[1], vbData.indices[2], vbData.indices[3]);
          vertex_float4(vb, vbData.weights[0], vbData.weights[1], vbData.weights[2], vbData.weights[3]);
        } else {
          vertex_ubyte4(vb, 0, 0, 0, 0);
          vertex_float4(vb, 0, 0, 0, 0);
        }
      }
    }

    vertex_end(vb);

    // Store the bounding box
    geometry.boundingBox = box3_create(
      vec3_create(ASSIMP_GetMeshAABBMinX(), ASSIMP_GetMeshAABBMinY(), ASSIMP_GetMeshAABBMinZ()),
      vec3_create(ASSIMP_GetMeshAABBMaxX(), ASSIMP_GetMeshAABBMaxY(), ASSIMP_GetMeshAABBMaxZ())
    );
    geometry.computeBoundingSphere();

    return { mesh, boneData: globalBoneData };
  }

  function _linkMeshesToGraph(root, meshes) {
    gml_pragma("forceinline");

    // Instead of searching for each node by name, we traverse the Assimp scene 
    // and use our nodeMap to find the corresponding UeObject3D.
    ASSIMP_BindSceneNode();
    _traverseAndLink(meshes);
  }

  function _traverseAndLink(meshes) {
    var name = ASSIMP_GetNodeName();
    var node = nodeMap[$ name];

    if (node != undefined) {
      var meshCount = ASSIMP_GetNodeMeshNum();
      for (var i = 0; i < meshCount; i++) {
        var meshIdx = ASSIMP_GetNodeMeshIndex(i);
        if (meshIdx < array_length(meshes)) {
          node.add(meshes[meshIdx]);
        }
      }
    }

    var childCount = ASSIMP_GetNodeChildrenNum();
    for (var i = 0; i < childCount; i++) {
      ASSIMP_BindNodeChild(i);
      _traverseAndLink(meshes);
      ASSIMP_BindNodeParent();
    }
  }

  function _buildSkeleton(boneData, root) {
    gml_pragma("forceinline");
    var bones = [];

    for (var i = 0, il = array_length(boneData); i < il; i++) {
      var data = boneData[i];
      var boneNode = nodeMap[$ data.name]; // Fast lookup using nodeMap

      if (boneNode == undefined) {
        ueWarning($"Bone node not found in hierarchy: {data.name}");
        continue;
      }

      // Convert UeObject3D to UeBone
      var bone = new UeBone({
        name: data.name,
        offsetMatrix: data.offsetMatrix,
        index: i
      });

      // Copy transform
      vec3_copy(bone.position, boneNode.position);
      quat_copy(bone.rotation, boneNode.rotation);
      vec3_copy(bone.scale, boneNode.scale);
      mat4_copy(bone.matrix, boneNode.matrix);

      // Replace node in hierarchy and in nodeMap
      var parent = boneNode.parent;
      if (parent != undefined) {
        parent.remove(boneNode);
        parent.add(bone);
      }

      nodeMap[$ data.name] = bone;

      // Move children
      var children = boneNode.children;
      var jl = array_length(children) - 1;
      for (var j = jl; j >= 0; j--) {
        bone.add(children[j]);
      }

      bones[i] = bone;
    }

    return new UeSkeleton(bones);
  }

  function _addAnimations() {
    gml_pragma("forceinline");
    var animCount = ASSIMP_GetAnimationNum();
    var animations = [];
    var animationsMap = {};

    for (var i = 0; i < animCount; i++) {
      ASSIMP_BindAnimation(i);
      var animName = ASSIMP_GetAnimationName();
      if (animName == "") animName = $"Animation{i}";
      var duration = ASSIMP_GetAnimationDuration();
      var tps = ASSIMP_GetAnimationTicksPerSecond() ?? 24;

      var anim = new UeAnimation(animName, duration, tps);

      var channelCount = ASSIMP_GetAnimationNodeChannelsNum();
      for (var c = 0; c < channelCount; c++) {
        ASSIMP_BindNodeAnimation(c);
        var nodeName = ASSIMP_GetNodeAnimNodeName();
        var track = new UeAnimationTrack(nodeName);

        // Position keys
        var posCount = ASSIMP_GetNodeAnimPositionKeysNum();
        for (var k = 0; k < posCount; k++) {
          var time = ASSIMP_GetNodeAnimPositionKeyTime(k);
          var val = vec3_create(
            ASSIMP_GetNodeAnimPositionKeyValueX(k),
            ASSIMP_GetNodeAnimPositionKeyValueY(k),
            ASSIMP_GetNodeAnimPositionKeyValueZ(k)
          );
          array_push(track.positionKeys, [time, val]);
        }

        // Rotation keys
        var rotCount = ASSIMP_GetNodeAnimRotationKeysNum();
        for (var k = 0; k < rotCount; k++) {
          var time = ASSIMP_GetNodeAnimRotationKeyTime(k);
          var val = quat_create(
            ASSIMP_GetNodeAnimRotationKeyQuaternionX(k),
            ASSIMP_GetNodeAnimRotationKeyQuaternionY(k),
            ASSIMP_GetNodeAnimRotationKeyQuaternionZ(k),
            ASSIMP_GetNodeAnimRotationKeyQuaternionW(k)
          );
          array_push(track.rotationKeys, [time, val]);
        }

        // Scale keys
        var scaleCount = ASSIMP_GetNodeAnimScalingKeysNum();
        for (var k = 0; k < scaleCount; k++) {
          var time = ASSIMP_GetNodeAnimScalingKeyTime(k);
          var val = vec3_create(
            ASSIMP_GetNodeAnimScalingKeyValueX(k),
            ASSIMP_GetNodeAnimScalingKeyValueY(k),
            ASSIMP_GetNodeAnimScalingKeyValueZ(k)
          );
          array_push(track.scaleKeys, [time, val]);
        }

        anim.addTrack(track);
      }

      animations[i] = anim;
      animationsMap[$ animName] = anim;
    }

    return {
      list: animations,
      map: animationsMap
    };
  }

  function _calculateModelBounds(model, meshes) {
    gml_pragma("forceinline");

    // Ensure the model has bounding properties
    model.boundingBox = box3_create();
    model.boundingSphere = sphere_create([0, 0, 0], -1);

    // Use the math helper to calculate total bounds from the hierarchy
    box3_set_from_object(model.boundingBox, model);

    // Calculate bounding sphere from the box
    var minX = model.boundingBox[BOX3.minX];
    var minY = model.boundingBox[BOX3.minY];
    var minZ = model.boundingBox[BOX3.minZ];
    var maxX = model.boundingBox[BOX3.maxX];
    var maxY = model.boundingBox[BOX3.maxY];
    var maxZ = model.boundingBox[BOX3.maxZ];

    var minV = [minX, minY, minZ];
    var maxV = [maxX, maxY, maxZ];

    var center = vec3_clone(minV);
    vec3_add(center, maxV);
    vec3_multiply_scalar(center, 0.5);

    // Update the sphere
    sphere_set(model.boundingSphere, center, vec3_distance_to(center, maxV));
  }

  function dispose() {
    gml_pragma("forceinline");
    ASSIMP_DeleteImporter(importer);
    return self;
  }
}
