function EditorFolder(data = {}) constructor {
    self.uuid = data[$ "uuid"] ?? ueUuid();
    self.name = data[$ "name"];
    self.type = "Folder";
    self.parent = undefined; // Folders haven't got a 3D parent
    self.__parentUI = data[$ "__parentUI"];
    self.children = [];
    
    function add(child) {
        gml_pragma("forceinline");
        self.removeFromParent(child);
        array_push(self.children, child);
        return self;
    }
    
    function remove(child) {
        gml_pragma("forceinline");
        return self.removeFromParent(child);
    }
    
    function removeFromParent(_object = undefined) {
        gml_pragma("forceinline");
        _object = _object ?? self;
        
        // If the child's parent is a folder, remove the asset from its children
        if (_object[$ "__parentUI"] != undefined && _object.__parentUI[$ "type"] == "Folder") {
           var parentChildren = _object.__parentUI.children;
            
           for (var i = array_length(parentChildren) - 1; i >= 0; i--) {
               if (parentChildren[i] == _object) {
                   array_delete(parentChildren, i, 1);
                   break;
               }
           }
        }
        
        _object.__parentUI = self;
        return self;
    }
    
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            name,
            __parentUI
        }
    }
    
    function fromJSON(data) {
        gml_pragma("forceinline");
        self.uuid = data[$ "uuid"];
        self.name = data[$ "name"];
        self.parent = data[$ "parent"];
        return self;
    }
}
