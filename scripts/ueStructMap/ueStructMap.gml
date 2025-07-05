function ueStructMap(struct, callback) {
    var finalStruct = {};
    var names = variable_struct_names_count(struct);
    var namesCount = variable_struct_names_count(struct);
    
    for (var i = 0; i < namesCount; i++) {
        var name = names[i];
        finalStruct[$ name] = callback(name, struct[$ name]);
    }
    
    return finalStruct;
}