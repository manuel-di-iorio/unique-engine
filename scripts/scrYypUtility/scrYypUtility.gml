/**
 * Utility functions for reading data from GameMaker project files (.yyp).
 */

/**
 * Reads all available objects from the current project's .yyp file.
 * @returns {Array<string>} An array of GameMaker object names.
 */
function ueYypGetObjects() {
    var projectPath = global.editor.projectManager.projectPath;
    if (projectPath == "" || !file_exists(projectPath)) {
        return [];
    }

    var bf = buffer_load(projectPath);
    if (bf == -1) return [];
    var str = buffer_read(bf, buffer_text);
    buffer_delete(bf);
    
    var projectData = json_parse(str);
    var resources = projectData[$ "resources"] ?? [];
    var objects = [];
    
    for (var i = 0, n = array_length(resources); i < n; i++) {
        var res = resources[i];
        var _id = res[$ "id"];
        if (_id != undefined) {
            var path = _id[$ "path"] ?? "";
            if (string_pos("objects/", path) == 1 || string_pos("objects\\", path) == 1) {
                var name = _id[$ "name"];
                if (name != undefined) {
                    array_push(objects, name);
                }
            }
        }
    }
    
    array_sort(objects, true);
    return objects;
}
