/**
 * @description Handles particle spawning and initial positioning.
 * All initial state (life, velocity, etc.) should be handled by modules via onSpawn.
 */
function UeParticleEmitter(data = {}) constructor {
    self.system = undefined;
    
    // Emission properties
    self.rate = data[$ "rate"] ?? 10;
    self.burst = data[$ "burst"] ?? 0;
    self._accumulator = 0;
    self.enabled = true;

    // Transform
    self.position = data[$ "position"] ?? [0, 0, 0];
    
    // Shape
    self.shape = data[$ "shape"] ?? "point"; // "point", "box", "sphere"
    self.shapeSize = data[$ "shapeSize"] ?? [0, 0, 0]; // For box: [w, h, d], For sphere: [radius]

    // Shadow flags
    self.castShadow = data[$ "castShadow"] ?? false;
    self.receiveShadow = data[$ "receiveShadow"] ?? false;

    /**
     * Updates the emitter and spawns particles.
     */
    function update(dt) {
        if (!self.enabled) return;
        
        self._accumulator += dt * self.rate;
        
        while (self._accumulator >= 1) {
            spawn();
            self._accumulator--;
        }
        
        if (self.burst > 0) {
            repeat(self.burst) spawn();
            self.burst = 0;
        }
    }

    /**
     * Spawns a single particle and sets its initial position.
     */
    function spawn() {
        var p = self.system.pool;
        if (p.aliveCount >= p.maxCount) return;
        
        var i = p.aliveCount++;
        
        // --- Spawn Position ---
        var sx = self.position[0];
        var sy = self.position[1];
        var sz = self.position[2];
        
        switch (self.shape) {
            case "box":
                sx += random_range(-self.shapeSize[0], self.shapeSize[0]) * 0.5;
                sy += random_range(-self.shapeSize[1], self.shapeSize[1]) * 0.5;
                sz += random_range(-self.shapeSize[2], self.shapeSize[2]) * 0.5;
                break;
            case "sphere":
                var r = random(self.shapeSize[0]);
                var phi = random(2 * pi);
                var theta = random(pi);
                sx += r * sin(theta) * cos(phi);
                sy += r * sin(theta) * sin(phi);
                sz += r * cos(theta);
                break;
        }
        
        p.posX[i] = sx;
        p.posY[i] = sy;
        p.posZ[i] = sz;

        // --- Modules Initializations ---
        var ml = array_length(self.system.modules);
        for (var m = 0; m < ml; m++) {
            self.system.modules[m].onSpawn(p, i);
        }
    }
}
