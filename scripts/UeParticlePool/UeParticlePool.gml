/**
 * @description Data-oriented container for particles.
 * Stores particle properties in separate arrays (SoA) for better performance in GML.
 */
function UeParticlePool(maxCount) constructor {
    self.maxCount = maxCount;
    self.aliveCount = 0;

    // Dynamic attribute storage
    self.attributes = {};
    self.attributeNames = [];

    // Base attributes that are ALWAYS needed for rendering and lifecycle
    self.registerAttribute("posX", 0);
    self.registerAttribute("posY", 0);
    self.registerAttribute("posZ", 0);
    
    // Sorting/Rendering (these are internal, not dynamic attributes in the same sense but handled similarly)
    self.sortKey = array_create(maxCount, 0);
    self.indices = array_create(maxCount, 0);
    for (var i = 0; i < maxCount; i++) self.indices[i] = i;
    self.indicesScratch = array_create(maxCount, 0);

    /**
     * Registers a new attribute if it doesn't exist.
     * @param {String} name
     * @param {Any} defaultValue
     */
    function registerAttribute(name, defaultValue = 0) {
        if (variable_struct_exists(self.attributes, name)) return;
        
        var arr = array_create(self.maxCount, defaultValue);
        self.attributes[$ name] = arr;
        array_push(self.attributeNames, name);
        
        // Expose directly on the pool struct for performance (self.posX instead of self.attributes.posX)
        self[$ name] = arr;
    }

    /**
     * Resets a particle at the given index.
     */
    function reset(index) {
        gml_pragma("forceinline");
        var names = self.attributeNames;
        for (var i = 0, il = array_length(names); i < il; i++) {
            var attr = self.attributes[$ names[i]];
            attr[index] = 0; // Default reset to 0, maybe store actual default values?
        }
    }

    /**
     * Swaps two particles in the container.
     */
    function swap(i, j) {
        gml_pragma("forceinline");
        var names = self.attributeNames;
        var nl = array_length(names);
        var attrs = self.attributes;
        
        for (var n = 0; n < nl; n++) {
            var arr = attrs[$ names[n]];
            var tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
        }
        
        // Also swap sortKey
        var tmpKey = self.sortKey[i];
        self.sortKey[i] = self.sortKey[j];
        self.sortKey[j] = tmpKey;
    }
}
