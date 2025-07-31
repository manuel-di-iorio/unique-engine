// Load the model
modelLoading = true;

call_later(1, time_source_units_frames, function() {
    var mtl = new UeMtlLoader();
    var materials = mtl.load("cat/12221_Cat_v1_l3.mtl");
    
    var objLoader = new UeObjLoader();
    objLoader.setMaterials(materials);
    
    var objMesh = objLoader.load("cat/12221_Cat_v1_l3.obj");
    objMesh.setScale(10, 10, 10);
    objMesh.rotateZ(90);
    objMesh.updateMatrix();
    
    objMesh.traverse(function(mesh) {
        mesh.matrixAutoUpdate = false;
        
        var geometry = mesh[$ "geometry"];
        if (geometry != undefined) geometry.freeze();
    });
    
    scene.add(objMesh);
    modelLoaded = true;
    modelLoading = false;
})