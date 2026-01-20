/**
 * UeAssimpLoader
 * Loader for 3D models using the Assimp extension.
 * @param {struct} [data] Configuration data
  * @param {bool} [data.canFreeze=true] Whether to freeze the vertex buffers after loading for performance.
  * @param {bool} [data.matrixAutoUpdate=true] Whether to automatically update matrices for loaded objects.
  */
function UeAssimpLoader(data = {}) constructor {
  if (!ASSIMP_IsWorking()) ueError("Assimp extension is not working");

  self.canFreeze = data[$ "canFreeze"] ?? true;
  self.matrixAutoUpdate = data[$ "matrixAutoUpdate"] ?? true;

  importer = ASSIMP_CreateImporter();
  ASSIMP_BindImporter(importer);
  nodeMap = {};
  boneMap = {};

  materialTypes = [
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
      ASSIMP_PP.LIMIT_BONE_WEIGHTS |
      ASSIMP_PP.REMOVE_REDUNDANT_MATERIALS |
      ASSIMP_PP.FIX_INFACING_NORMALS |
      ASSIMP_PP.POPULATE_ARMATURE_DATA |
      ASSIMP_PP.REMOVE_COMPONENT |
      ASSIMP_PP.GLOBAL_SCALE |
      ASSIMP_PP.OPTIMIZE_MESHES |
      ASSIMP_PP.OPTIMIZE_GRAPH
    );

    if (!check) {
      ueError($"{ASSIMP_GetImporterErrorString()}");
    }

    ASSIMP_BindScene();

    // 1. Materials & Textures
    var textures = [];
    var textureCache = {};
    var materials = _addMaterials(fname, textures, textureCache);

    // 2. Meshes & Bone Data
    boneMap = {};
    var meshesResult = _addMeshes(materials.list);
    var boneData = meshesResult.boneData;

    // 3. Scene Graph & Node Map
    nodeMap = {};
    var root = _buildSceneGraph(meshesResult.meshes);

    // 4. Skeleton construction
    var skeleton = undefined;
    if (array_length(boneData) > 0) {
      skeleton = _buildSkeleton(boneData, root);
      _assignSkeletonToMeshes(root, skeleton);
    }

    // 5. Calculate total bounds for the model (the root Object3D)
    root.updateMatrixWorld(true);
    self._calculateModelBounds(root, meshesResult.meshes);

    // 6. Animations
    var animations = _addAnimations();

    return {
      textures,
      materials: materials.map,
      root,
      skeleton,
      animations: animations.map
    };
  }

  function _assignSkeletonToMeshes(root, _skeleton) {
    var context = { skeleton: _skeleton };
    root.traverse(method(context, function (node) {
      if (node[$ "isMesh"] && node.bindMode == "skinned") {
      node.skeleton = self.skeleton;
    }
    }));
  }

  function _getMatrix(target = undefined) {
    gml_pragma("forceinline");
    target ??= mat4_create();
    target[0] = ASSIMP_GetMatrixA1(); target[1] = ASSIMP_GetMatrixB1(); target[2] = ASSIMP_GetMatrixC1(); target[3] = ASSIMP_GetMatrixD1();
    target[4] = ASSIMP_GetMatrixA2(); target[5] = ASSIMP_GetMatrixB2(); target[6] = ASSIMP_GetMatrixC2(); target[7] = ASSIMP_GetMatrixD2();
    target[8] = ASSIMP_GetMatrixA3(); target[9] = ASSIMP_GetMatrixB3(); target[10] = ASSIMP_GetMatrixC3(); target[11] = ASSIMP_GetMatrixD3();
    target[12] = ASSIMP_GetMatrixA4(); target[13] = ASSIMP_GetMatrixB4(); target[14] = ASSIMP_GetMatrixC4(); target[15] = ASSIMP_GetMatrixD4();
    return target;
  }

  function _buildSceneGraph(meshes, nodeId = -1) {
    gml_pragma("forceinline");
    if (nodeId == -1) {
      ASSIMP_BindSceneNode();
    } else {
      ASSIMP_BindNodeChild(nodeId);
    }

    var name = ASSIMP_GetNodeName();

    var object = new UeObject3D({ matrixAutoUpdate: self.matrixAutoUpdate });
    object.name = name;

    // Store in nodeMap for fast lookup (e.g. for bones)
    // If multiple nodes have the same name, we append a suffix
    var uniqueName = name;
    var counter = 1;
    while (struct_exists(nodeMap, uniqueName)) {
      uniqueName = $"{name}_{counter++}";
    }
    nodeMap[$ uniqueName] = object;
    object.name = uniqueName; // Keep the actual name unique too

    ASSIMP_BindNodeMatrix();
    _getMatrix(object.matrix);
    mat4_decompose(object.matrix, object.position, object.rotation, object.scale);

    // Store initial transform as "rest pose" for animations that don't have all keyframe types
    object.initialPosition = vec3_clone(object.position);
    object.initialRotation = quat_clone(object.rotation);
    object.initialScale = vec3_clone(object.scale);

    // Link meshes to this node
    var meshCount = ASSIMP_GetNodeMeshNum();

    for (var i = 0; i < meshCount; i++) {
      var meshIdx = ASSIMP_GetNodeMeshIndex(i);
      if (meshIdx < array_length(meshes)) {
        var proto = meshes[meshIdx];

        // Always create a new UeMesh instance that shares geometry and material.
        // This handles mesh sharing (instancing) between nodes.
        var mesh = new UeMesh(proto.geometry, proto.material, {
          matrixAutoUpdate: proto.matrixAutoUpdate,
          castShadow: proto.castShadow,
          receiveShadow: proto.receiveShadow
        });
        mesh.name = proto.name;
        mesh.bindMode = proto.bindMode;
        object.add(mesh);
      }
    }

    var childCount = ASSIMP_GetNodeChildrenNum();
    for (var i = 0; i < childCount; i++) {
      object.add(_buildSceneGraph(meshes, i));
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
      var meshName = ASSIMP_GetMeshName();
      var meshResult = _buildMesh(boneData);
      var mesh = meshResult.mesh;
      mesh.name = meshName != "" ? meshName : $"Mesh{i}";
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
    var geometry = new UeGeometry({ canFreeze: self.canFreeze });

    // Set up vertex format
    var mesh = new UeMesh(geometry, { matrixAutoUpdate: self.matrixAutoUpdate });
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
    var vertIndices = undefined;
    var vertWeights = undefined;
    var vertCounts = undefined;
    if (hasBones) {
      vertIndices = array_create(vertexCount * 4, 0);
      vertWeights = array_create(vertexCount * 4, 0);
      vertCounts = array_create(vertexCount, 0);

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
          array_push(globalBoneData, { name: boneName, offsetMatrix });
        }

        var weightsCount = ASSIMP_GetBoneNumWeights();
        for (var w = 0; w < weightsCount; w++) {
          var vIdx = ASSIMP_GetBoneVertexIndex(w);
          var weight = ASSIMP_GetBoneVertexWeight(w);

          var count = vertCounts[vIdx];
          if (count < 4) {
            var offset = (vIdx << 2) + count;
            vertIndices[offset] = boneIdx;
            vertWeights[offset] = weight;
            vertCounts[vIdx]++;
          }
        }
      }
    }

    // Find the first available UV channel
    var uvChannel = -1;
    if (meshChannelNumTexcoord > 0) {
      for (var i = 0; i < meshChannelNumTexcoord; i++) {
        if (ASSIMP_MeshHasTexCoords(i)) {
          uvChannel = i;
          break;
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

        var tx = 0, ty = 0;
        if (uvChannel != -1) {
          tx = ASSIMP_GetMeshTexCoordU(v, uvChannel);
          ty = ASSIMP_GetMeshTexCoordV(v, uvChannel);
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
          var offset = v << 2;
          var w0 = vertWeights[offset];
          var w1 = vertWeights[offset + 1];
          var w2 = vertWeights[offset + 2];
          var w3 = vertWeights[offset + 3];

          // Normalize weights to ensure they sum to 1.0
          var totalWeight = w0 + w1 + w2 + w3;
          if (totalWeight > 0.0) {
            var invWeight = 1.0 / totalWeight;
            w0 *= invWeight;
            w1 *= invWeight;
            w2 *= invWeight;
            w3 *= invWeight;
          } else {
            // If no weights, assign to root bone (index 0) with full weight
            vertIndices[offset] = 0;
            vertIndices[offset + 1] = 0;
            vertIndices[offset + 2] = 0;
            vertIndices[offset + 3] = 0;
            w0 = 1.0;
            w1 = 0.0;
            w2 = 0.0;
            w3 = 0.0;
          }

          vertex_float4(vb, vertIndices[offset], vertIndices[offset + 1], vertIndices[offset + 2], vertIndices[offset + 3]);
          vertex_float4(vb, w0, w1, w2, w3);
        } else {
          vertex_float4(vb, 0, 0, 0, 0);
          vertex_float4(vb, 0, 0, 0, 0);
        }
      }
    }

    vertex_end(vb);
    if (self.canFreeze) vertex_freeze(vb);

    // Store the bounding box
    geometry.boundingBox = box3_create(
      vec3_create(ASSIMP_GetMeshAABBMinX(), ASSIMP_GetMeshAABBMinY(), ASSIMP_GetMeshAABBMinZ()),
      vec3_create(ASSIMP_GetMeshAABBMaxX(), ASSIMP_GetMeshAABBMaxY(), ASSIMP_GetMeshAABBMaxZ())
    );
    geometry.computeBoundingSphere();

    return { mesh, boneData: globalBoneData };
  }

  function _buildSkeleton(boneData, root) {
    gml_pragma("forceinline");
    var bones = [];

    for (var i = 0, il = array_length(boneData); i < il; i++) {
      var data = boneData[i];
      var boneNode = nodeMap[$ data.name]; // Fast lookup using nodeMap
      if (boneNode == undefined) continue;

      // Bone-ify the existing node instead of replacing it.
      // This preserves the node if it's also a Mesh or has other properties,
      // and keeps the hierarchy intact.
      boneNode.isBone = true;
      boneNode.offsetMatrix = data.offsetMatrix;
      boneNode.index = i;

      if (boneNode.type == "Object3D") {
        boneNode.type = "Bone";
      }

      bones[i] = boneNode;
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
        track.positionKeys = array_create(posCount * 4);
        for (var k = 0; k < posCount; k++) {
          var idx = k << 2;
          track.positionKeys[idx] = ASSIMP_GetNodeAnimPositionKeyTime(k);
          track.positionKeys[idx + 1] = ASSIMP_GetNodeAnimPositionKeyValueX(k);
          track.positionKeys[idx + 2] = ASSIMP_GetNodeAnimPositionKeyValueY(k);
          track.positionKeys[idx + 3] = ASSIMP_GetNodeAnimPositionKeyValueZ(k);
        }

        // Rotation keys
        var rotCount = ASSIMP_GetNodeAnimRotationKeysNum();
        track.rotationKeys = array_create(rotCount * 5);
        for (var k = 0; k < rotCount; k++) {
          var idx = k * 5;
          track.rotationKeys[idx] = ASSIMP_GetNodeAnimRotationKeyTime(k);
          track.rotationKeys[idx + 1] = ASSIMP_GetNodeAnimRotationKeyQuaternionX(k);
          track.rotationKeys[idx + 2] = ASSIMP_GetNodeAnimRotationKeyQuaternionY(k);
          track.rotationKeys[idx + 3] = ASSIMP_GetNodeAnimRotationKeyQuaternionZ(k);
          track.rotationKeys[idx + 4] = ASSIMP_GetNodeAnimRotationKeyQuaternionW(k);
        }

        // Scale keys
        var scaleCount = ASSIMP_GetNodeAnimScalingKeysNum();
        track.scaleKeys = array_create(scaleCount * 4);
        for (var k = 0; k < scaleCount; k++) {
          var idx = k << 2;
          track.scaleKeys[idx] = ASSIMP_GetNodeAnimScalingKeyTime(k);
          track.scaleKeys[idx + 1] = ASSIMP_GetNodeAnimScalingKeyValueX(k);
          track.scaleKeys[idx + 2] = ASSIMP_GetNodeAnimScalingKeyValueY(k);
          track.scaleKeys[idx + 3] = ASSIMP_GetNodeAnimScalingKeyValueZ(k);
        }

        anim.addTrack(track);
      }

      // Pre-calculate and bake animation data for maximum performance
      anim.update();

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
