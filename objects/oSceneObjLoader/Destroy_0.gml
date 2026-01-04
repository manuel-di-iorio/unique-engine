if (objMesh != undefined) {
    objMesh.traverse(function(mesh) {
        var geometry = mesh[$ "geometry"];
        if (geometry != undefined) geometry.dispose();
    });
        
    ueStructEach(objLoader.materials, function(name, material) {
      material.textures.map.dispose();
    });
}