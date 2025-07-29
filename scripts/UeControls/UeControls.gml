function UeControls(data = {}) constructor {
    enabled = true;
    
    // @undocumented @todo
    object = undefined;
    keys = {};
    mouseButtons = {
        LEFT: undefined,
        MIDDLE: undefined,
        RIGHT: undefined 
    }
    
    function dispose() {
        gml_pragma("forceinline");
        
    }
}