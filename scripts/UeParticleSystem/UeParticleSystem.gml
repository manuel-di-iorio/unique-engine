/**
 * @description Manages a group of particles and their emitters.
 */
function UeParticleSystem(maxCount = 1000, data = {}) constructor {
    self.type = "ParticleSystem";
    self.pool = new UeParticlePool(maxCount);
    self.emitters = [];
    self.modules  = [];
    
    // Global properties
    self.timeScale = data[$ "timeScale"] ?? 1.0;
    self.autoUpdate = data[$ "autoUpdate"] ?? true;
    self.sorted = data[$ "sorted"] ?? false;
    self.softFactor = data[$ "softFactor"] ?? 0.0; // 0.0 means disabled
    self.castShadow = data[$ "castShadow"] ?? false;
    self.receiveShadow = data[$ "receiveShadow"] ?? false;
    
    /**
     * Adds an emitter to the system.
     */
    function addEmitter(emitter) {
        array_push(self.emitters, emitter);
        emitter.system = self;
        return emitter;
    }

    /**
     * Adds a behavior module to the system.
     */
    function addModule(module) {
        array_push(self.modules, module);
        
        // Let the module register its requirements on the pool
        if (variable_struct_exists(module, "onRegister")) {
            module.onRegister(self.pool);
        }
        
        return module;
    }
    
    /**
     * Renders the system.
     */
    function render(renderer, camera, texture = -1, depthTexture = undefined, shadowConfig = undefined, isShadowPass = false) {
        if (isShadowPass && !self.castShadow) return;
        
        if (renderer == undefined) return;
        
        // Render
        renderer.render(self, camera, texture, depthTexture, shadowConfig, isShadowPass);
    }

    /**
     * Updates all particles in the system.
     */
    function update(dt, camera = undefined) {
        gml_pragma("forceinline");
        
        var _dt = dt * self.timeScale;
        var p = self.pool;
        
        // Update emitters
        for (var i = 0, il = array_length(self.emitters); i < il; i++) {
            self.emitters[i].update(_dt);
        }

        // Modules (Per-Particle Processing)
        // This now handles EVERYTHING: life cycle, motion, behaviors.
        var ml = array_length(self.modules);
        if (ml > 0) {
            var i = 0;
            while (i < p.aliveCount) {
                var killed = false;
                for (var m = 0; m < ml; m++) {
                    // Modules can return true to stop processing this particle (e.g. if it was killed)
                    if (self.modules[m].onUpdate(p, i, _dt) == true) {
                        killed = true;
                        break;
                    }
                }
                if (!killed) i++;
            }
        }

        // Sorting (if needed)
        if (self.sorted && camera != undefined) {
            // Calculate sort keys if sorted
            var camX = camera.position[0];
            var camY = camera.position[1];
            var camZ = camera.position[2];
            for (var j = 0; j < p.aliveCount; j++) {
                var dx = p.posX[j] - camX;
                var dy = p.posY[j] - camY;
                var dz = p.posZ[j] - camZ;
                p.sortKey[j] = dx*dx + dy*dy + dz*dz;
            }
            depthSort();
        }
    }

    /**
     * Kills a particle at the given index by swapping it with the last alive one.
     */
    function kill(index) {
        gml_pragma("forceinline");
        self.pool.aliveCount--;
        if (index < self.pool.aliveCount) {
            self.pool.swap(index, self.pool.aliveCount);
        }
    }

    /**
     * Sorts particles based on their sortKey (back-to-front).
     */
    function depthSort() {
        var p = self.pool;
        var count = p.aliveCount;
        if (count <= 1) return;
        
        // Use the pool's scratch array to avoid allocation
        var temp = p.indicesScratch;
        for (var j = 0; j < count; j++) temp[j] = j;
        
        var sortArray = array_create(count);
        array_copy(sortArray, 0, temp, 0, count);
        
        // Use method to bind 'pool' to the sort function context
        // This is engine-agnostic and thread-safe (in theory for GML) and doesn't rely on globals.
        array_sort(sortArray, method({ pool: p }, function(a, b) {
            return pool.sortKey[b] - pool.sortKey[a];
        }));
        
        // Copy the sorted indices back to the pool
        array_copy(p.indices, 0, sortArray, 0, count);
    }
}
