showWireframe = !showWireframe;

airplaneMesh.traverse(function(mesh) {
    var material = mesh[$ "material"];
    log(material)
    if (material != undefined) material.wireframe = showWireframe;
});