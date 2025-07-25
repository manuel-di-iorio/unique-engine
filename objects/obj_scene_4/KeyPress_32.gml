scene.traverse(function(mesh) {
    mesh.frustumCulled = !mesh.frustumCulled;
})