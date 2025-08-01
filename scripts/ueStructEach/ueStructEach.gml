function ueStructEach(struct, callback) {
    gml_pragma("forceinline");
    var names = variable_struct_get_names(struct);
    var namesCount = variable_struct_names_count(struct);
    
    for (var i = 0; i < namesCount; i++) {
        var name = names[i];
        callback(name, struct[$ name]);
    }
}