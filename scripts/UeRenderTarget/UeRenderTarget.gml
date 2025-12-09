function UeRenderTarget(width, height, options = {}) constructor {
    self.isRenderTarget = true;
    self.type = "RenderTarget";
    self.width = width;
    self.height = height;
    self.surface = undefined;

    // Set the options
    var opts = options ?? {};
    self.options = opts;

    opts.internalFormat = opts[$ "internalFormat"] ?? surface_rgba8unorm;
    
    function create() {
        gml_pragma("forceinline");
        self.surface = surface_create(self.width, self.height, self.options.internalFormat);
        return self;
    }
    
    function setSize(width, height) {
        gml_pragma("forceinline");
        self.dispose();
        self.width = width;
        self.height = height;
        self.surface = surface_create(width, height, self.options.internalFormat);
        return self;
    }
    
    function dispose() {
        gml_pragma("forceinline");
        if (surface_exists(self.surface)) surface_free(self.surface);
        return self;
    }

    function clone() {
        gml_pragma("forceinline");
        return new UeRenderTarget(self.width, self.height, self.options);
    }

    function copy(source) {
        gml_pragma("forceinline");
        self.width = source.width;
        self.height = source.height;
        surface_copy(self.surface, 0, 0, source.surface);
        return self;
    }

    // Initially create the surface
    self.create();
}
