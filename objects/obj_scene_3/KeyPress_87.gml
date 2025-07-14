showWireframe = !showWireframe;

airplaneMesh.traverse(function(mesh) {
    var material = mesh[$ "material"];
    if (material != undefined) material.wireframe = showWireframe;
});