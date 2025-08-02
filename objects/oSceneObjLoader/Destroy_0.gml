if (objMesh != undefined) {
    objMesh.traverse(function(mesh) {
        var geometry = mesh[$ "geometry"];
        if (geometry != undefined) geometry.dispose();
    });
        
    ueStructEach(objLoader.materials, function(name, material) {
        ueStructEach(material.textures, function(name, texture) {
            if (sprite_exists(texture.image)) sprite_delete(texture.image);
        });
    })
}