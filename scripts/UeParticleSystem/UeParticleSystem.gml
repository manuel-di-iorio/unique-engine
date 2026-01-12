/**
 * @description Manages a group of particles and their emitters.
 */
function UeParticleSystem(pool, data = {}): UeObject3D(data) constructor {
    self.type = "ParticleSystem";
    self.pool = pool;
    self.emitters = [];
    self.modules  = [];
    
    // Global properties
    self.timeScale = data[$ "timeScale"] ?? 1.0;
    self.autoUpdate = data[$ "autoUpdate"] ?? true;
    self.sorted = data[$ "sorted"] ?? false;
    self.softFactor = data[$ "softFactor"] ?? 0.0; // 0.0 means disabled
    self.castShadow = data[$ "castShadow"] ?? false;
    self.receiveShadow = data[$ "receiveShadow"] ?? false;
    
    // Mock geometry for UeRenderer collection
    self.geometry = { vb: true }; 
    self.frustumCulled = false; // Usually particles have dynamic bounds, disable culling for now
    
    // We need a reference to the renderer. 
    // In a real scenario, this could be a global or passed.
    self.renderer = undefined; 

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
        return module;
    }
    
    /**
     * Renders the system. Called by UeRenderer.
     */
    function render() {
        var isShadowPass = (variable_global_exists("UE_RENDERER_ACTIVE_SHADOW_CAMERA") && global.UE_RENDERER_ACTIVE_SHADOW_CAMERA != undefined);
        
        if (isShadowPass && !self.castShadow) return;

        if (self.renderer == undefined) {
            // Lazy-init global particle renderer if not provided
            if (!variable_global_exists("__ue_global_particle_renderer")) {
                global.__ue_global_particle_renderer = new UeParticleRenderer();
            }
            self.renderer = global.__ue_global_particle_renderer;
        }
        
        var cam = isShadowPass ? global.UE_RENDERER_ACTIVE_SHADOW_CAMERA : global.UE_RENDERER_ACTIVE_CAMERA;
        if (cam != undefined) {
            self.renderer.render(self, cam, -1, isShadowPass);
            
            // If it was a shadow pass, we must restore the engine's shadow shader
            if (isShadowPass && variable_global_exists("UE_RENDERER_ACTIVE_SHADOW_SHADER")) {
                shader_set(global.UE_RENDERER_ACTIVE_SHADOW_SHADER);
            }
        }
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

        // Update particles
        var i = 0;
        while (i < p.aliveCount) {
            // Update age
            p.age[i] += _dt;
            
            // Check life
            if (p.age[i] >= p.life[i]) {
                kill(i);
                continue; // Don't increment i, swap happened
            }

            // Apply modules
            for (var m = 0, ml = array_length(self.modules); m < ml; m++) {
                self.modules[m].onUpdate(p, i, _dt);
            }

            // Basic Physics Integration
            p.posX[i] += p.velX[i] * _dt;
            p.posY[i] += p.velY[i] * _dt;
            p.posZ[i] += p.velZ[i] * _dt;

            // Sorting Key Calculation
            if (self.sorted && camera != undefined) {
                var camPos = camera.position;
                var dx = p.posX[i] - camPos[0];
                var dy = p.posY[i] - camPos[1];
                var dz = p.posZ[i] - camPos[2];
                p.sortKey[i] = dx*dx + dy*dy + dz*dz; // Distance squared for sorting
            }

            i++;
        }

        if (self.sorted) {
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
        
        global.__ue_particle_pool_ref = p;
        array_sort(sortArray, function(a, b) {
            var pool = global.__ue_particle_pool_ref;
            return pool.sortKey[b] - pool.sortKey[a];
        });
        
        // Copy the sorted indices back to the pool
        array_copy(p.indices, 0, sortArray, 0, count);
    }
}
