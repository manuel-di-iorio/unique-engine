function UeControls(data = {}) constructor {
    self.enabled = true;
    
    // @undocumented @todo
    self.shouldHandleInput = data[$"shouldHandleInput"] ?? function() { return true; };
    
    // @undocumented @todo
    self.object = undefined;
    self.keys = {};
    self.mouseButtons = {
        LEFT: undefined,
        MIDDLE: undefined,
        RIGHT: undefined 
    }
    
    self.__canInteract = false;
    
    function dispose() {
        gml_pragma("forceinline");
        
    }
}
