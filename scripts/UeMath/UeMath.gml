function box3_set_from_object(b, object) {
    gml_pragma("forceinline");
    box3_make_empty(b);

    // Se l'oggetto ha geometria
    var geom = object[$ "geometry"];
    if (geom != undefined) {
        // Assicurati che la geometria abbia il bounding box
        if (geom[$ "boundingBox"] == undefined) {
            geom[$ "boundingBox"] = box3_create();
            box3_set_from_array(geom[$ "boundingBox"], geom[$ "vertices"]);
        }
        var localBox = box3_clone(geom[$ "boundingBox"]);

        // Trasforma nel world space
        var m = object[$ "matrixWorld"];
        if (m != undefined) box3_apply_matrix4(localBox, m);

        box3_union(b, localBox);
    }

    // Espandi con eventuale sphere
    var s = object[$ "__intersectionSphere"];
    if (s != undefined) {
        var sb = sphere_get_bounding_box(s);
        box3_union(b, sb);
    }

    // Richiama la stessa funzione sui figli
    var children = object[$ "children"];
    var n = array_length(children);
    for (var i = 0; i < n; i++) {
      var childBox = box3_create();
      box3_set_from_object(childBox, children[i]);
      box3_union(b, childBox);
    }

    return b;
}