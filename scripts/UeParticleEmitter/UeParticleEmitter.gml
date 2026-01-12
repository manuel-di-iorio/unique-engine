/**
 * @description Handles particle spawning based on a UeParticleType and a shape.
 */
function UeParticleEmitter(type, data = {}) constructor {
    self.type = type;
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

    // Shadow flags (can be used to override system settings or as defaults)
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
     * Spawns a single particle.
     */
    function spawn() {
        var p = self.system.pool;
        if (p.aliveCount >= p.maxCount) return;
        
        var i = p.aliveCount++;
        var t = self.type;
        
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

        // --- Spawn Life ---
        p.age[i] = 0;
        p.life[i] = random_range(t.life[0], t.life[1]);

        // --- Spawn Velocity ---
        var spd = random_range(t.speed[0], t.speed[1]);
        var dir = random_range(t.direction[0], t.direction[1]);
        var pitch = random_range(-90, 90); // Default 3D spread
        
        // Simple spherical to cartesian for 3D velocity
        var radDir = degtorad(dir);
        var radPitch = degtorad(pitch);
        p.velX[i] = spd * cos(radPitch) * cos(radDir);
        p.velY[i] = spd * sin(radPitch);
        p.velZ[i] = spd * cos(radPitch) * sin(radDir);

        // --- Spawn Appearance ---
        p.size[i] = random_range(t.size[0], t.size[1]);
        p.rotation[i] = random_range(t.rotation[0], t.rotation[1]);
        
        p.colorR[i] = t.colorStart[0];
        p.colorG[i] = t.colorStart[1];
        p.colorB[i] = t.colorStart[2];
        p.alpha[i]  = t.alphaStart;
        
        // --- Custom Spawn Logic (Modules) ---
        for (var m = 0, ml = array_length(self.system.modules); m < ml; m++) {
            self.system.modules[m].onSpawn(p, i);
        }
    }
}
