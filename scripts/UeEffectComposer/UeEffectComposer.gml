function UeEffectComposer(renderer, renderTarget = undefined) constructor {
    self.passes = [];
    self.renderer = renderer;
    self.renderToScreen = true;

    if (renderTarget == undefined) {
        var size = renderer.getSize(new UeVector2());
        self.width = size.width;
        self.height = size.height;
        renderTarget = new UeRenderTarget(self.width, self.height);
    } else {
        self.width = renderTarget.width;
        self.height = renderTarget.height;
    }

    self.readTarget = renderTarget;
    self.writeTarget = renderTarget.clone();
    
    function addPass(pass) {
        gml_pragma("forceinline");
        array_push(self.passes, pass);
        return self;        
    }
    
    function insertPass(pass, index) {
        gml_pragma("forceinline");
        array_insert(self.passes, index, pass);
        return self;        
    }
    
    function removePass(pass) {
        gml_pragma("forceinline");
        var index = array_find_index(self.passes, function(el) { 
            return el == pass;
        });
        array_delete(self.passes, index, 1);
        return self;
    }
    
    // Find the last enabled pass starting from the end and check if the index matches it
    function isLastEnabledPass(index) {
        gml_pragma("forceinline");
        
        for (var i = array_length(self.passes) - 1; i >= 0; i--) {
            if (self.passes[i].enabled) {
                return index == i;
            }
        }
        
        return false;
    }
    
    function dispose() {
        gml_pragma("forceinline");
        self.readTarget.dispose();
        self.writeTarget.dispose();
        return self;
    }
    
    function render() {
        gml_pragma("forceinline");
        
        for (var i = 0, il = array_length(self.passes); i < il; i++) {
            var pass = self.passes[i];            
            if (!pass.enabled) continue;
            
            pass.renderToScreen = (self.renderToScreen && self.isLastEnabledPass(i));
            pass.render(self.renderer, self.writeTarget, self.readTarget);
            
            if (pass.needsSwap) {
                var tmp = self.readTarget;
                self.readTarget = self.writeTarget;
                self.writeTarget = tmp;
            }
        }

        return self;
    }
    
    function setSize(width, height) {
        gml_pragma("forceinline");
        self.width = width;
        self.height = height;
        self.readTarget.setSize(width, height);
        self.writeTarget.setSize(width, height);
        return self;
    }
}
