/**
* @description Persistent emitter that manages particle spawning and circular GPU buffer updates.
* Physics simulation and visual updates are handled entirely on the GPU.
*/
function UeParticleEmitter(maxParticles = 100) constructor {
  gml_pragma("forceinline");
  self.maxParticles = maxParticles;
  self.vformat = global.UE_PARTICLE_RENDER_FORMAT;
  self.vsize = 52;
  self.centerX = 0;
  self.centerY = 0;
  self.centerZ = 0;

  // RAW Buffer persistent (CPU-side storage for vertex data)
  self.rawBuffer = buffer_create(maxParticles * 6 * self.vsize, buffer_fixed, 1);
  buffer_fill(self.rawBuffer, 0, buffer_f32, 0, buffer_get_size(self.rawBuffer));

  self.vbuffer = vertex_create_buffer_from_buffer(self.rawBuffer, self.vformat);
  self.writePointer = 0;         // Index for circular writing
  self.spawnedAny = false;       // Flag to trigger GPU buffer update
  self.firstOffset = 0;          // Start of modified range
  self.lastOffset = 0;           // End of modified range

  // --- Emission State ---
  self.streamType = undefined;
  self.streamRate = 0;
  self._accumulator = 0;
  self.enabled = true;
  self.sizeX = 0; self.sizeY = 0; self.sizeZ = 0;
  self.isDestroyed = false;
  self.shape = "point";
  self.visible = true;
  self.pool = { aliveCount: 0 };
  self.totalSpawned = 0;

  // --- LOD & Culling settings ---
  self.lodDistances = [500, 1000];
  self.lodRates = [1.0, 0.5, 0.1];
  self.lodLevel = 0;
  self.cullingRadius = 100;
  self.autoCullingRadius = true;

  /**
   * @description Updates the Level of Detail based on camera distance.
   * @param {real} cx Camera X position.
   * @param {real} cy Camera Y position.
   * @param {real} cz Camera Z position.
   * @returns {real} Current LOD level (0 = highest detail).
   */
  static updateLOD = function (cx, cy, cz, px, py, pz) {
    gml_pragma("forceinline");
    var dist = point_distance_3d(cx + px, cy + py, cz + pz, self.centerX + px, self.centerY + py, self.centerZ + pz);
    var _dists = self.lodDistances;

    self.lodLevel = 0;
    for (var i = 0, il = array_length(_dists); i < il; i++) {
      if (dist > _dists[i]) {
        self.lodLevel = i + 1;
      } else {
        break;
      }
    }
    return self.lodLevel;
  }

  /**
   * @description Numerically estimates the maximum possible distance particles can travel 
   * to define an accurate culling sphere.
   * @returns {UeParticleEmitter} 
   */
  static computeCullingRadius = function () {
    gml_pragma("forceinline");
    var type = self.streamType;
    var baseR = max(self.sizeX, self.sizeY, self.sizeZ) * 0.5;
    if (type == undefined) {
      self.cullingRadius = baseR;
      return self;
    }

    // Analytical travel: (v0*t + 0.5*a*t^2)
    var maxLife = type.lifeMax;
    var maxV = max(abs(type.speedMax), abs(type.zSpeedMax));
    var maxA = max(abs(type.gravAmount), abs(type.zGravAmount));
    var travel = maxV * maxLife + 0.5 * maxA * maxLife * maxLife;

    self.cullingRadius = baseR + travel;
    return self;
  }

  /**
   * @description Defines the spawning region dimensions and shape.
   * @param {string} s Shape type ("point", "box", "sphere").
   * @param {real} x1 Top-left-near coordinate.
   * @param {real} y1 Top-left-near coordinate.
   * @param {real} z1 Top-left-near coordinate.
   * @param {real} x2 Bottom-right-far coordinate.
   * @param {real} y2 Bottom-right-far coordinate.
   * @param {real} z2 Bottom-right-far coordinate.
   * @returns {UeParticleEmitter}
   */
  static region = function (s, x1, y1, z1, x2, y2, z2) {
    self.shape = s;
    self.centerX = (x1 + x2) * 0.5;
    self.centerY = (y1 + y2) * 0.5;
    self.centerZ = (z1 + z2) * 0.5;
    self.sizeX = abs(x2 - x1);
    self.sizeY = abs(y2 - y1);
    self.sizeZ = abs(z2 - z1);
    self.computeCullingRadius();
    return self;
  }

  /**
   * @description Starts a continuous particle stream.
   * @param {UeParticleType} type Particle configuration to use.
   * @param {real} rate Number of particles per second.
   * @returns {UeParticleEmitter}
   */
  static stream = function (t, r) {
    self.streamType = t;
    self.streamRate = r;
    self.computeCullingRadius();
    return self;
  }

  /**
   * @description Instantiates a single particle by overwriting the oldest vertex data in the circular buffer.
   * @param {UeParticleType} type The particle template.
   * @returns {real} The circular buffer index used.
   */
  static spawn = function (type, positionX, positionY, positionZ) {
    if (self.isDestroyed) return -1;
    var sx = self.centerX + positionX, sy = self.centerY + positionY, sz = self.centerZ + positionZ;
    if (self.shape == "box") {
      sx += random_range(-0.5, 0.5) * self.sizeX; sy += random_range(-0.5, 0.5) * self.sizeY; sz += random_range(-0.5, 0.5) * self.sizeZ;
    }
    var spd = random_range(type.speedMin, type.speedMax), dir = random_range(type.dirMin, type.dirMax);
    var vx = cos(dir) * spd, vy = -sin(dir) * spd, vz = random_range(type.zSpeedMin, type.zSpeedMax);
    var life = random_range(type.lifeMin, type.lifeMax);
    var sS = random_range(type.sizeMin, type.sizeMax), rS = random_range(type.rotMin, type.rotMax);
    var cs = (floor(type.alphaStart * 255) << 24) | (floor(type.colorStart[2] * 255) << 16) | (floor(type.colorStart[1] * 255) << 8) | floor(type.colorStart[0] * 255);
    var st = current_time / 1000.0;

    // --- Circular Write (O(1)) ---
    var b = self.rawBuffer;
    var pSize = 6 * self.vsize;
    var offset = self.writePointer * pSize;

    if (!self.spawnedAny) {
      self.firstOffset = offset;
      self.spawnedAny = true;
    }

    buffer_seek(b, buffer_seek_start, offset);

    // Corners: TL, TR, BL, BL, TR, BR (Triangle List 6 verts)
    static cornersX = [-0.5, 0.5, -0.5, -0.5, 0.5, 0.5];
    static cornersY = [-0.5, -0.5, 0.5, 0.5, -0.5, 0.5];
    var scX = type.scaleX;
    var scY = type.scaleY;

    for (var c = 0; c < 6; c++) {
      buffer_write(b, buffer_f32, sx); buffer_write(b, buffer_f32, sy); buffer_write(b, buffer_f32, sz);
      buffer_write(b, buffer_u32, cs);
      buffer_write(b, buffer_f32, cornersX[c] * scX); buffer_write(b, buffer_f32, cornersY[c] * scY);
      buffer_write(b, buffer_f32, vx); buffer_write(b, buffer_f32, vy); buffer_write(b, buffer_f32, vz); buffer_write(b, buffer_f32, st);
      buffer_write(b, buffer_f32, life); buffer_write(b, buffer_f32, sS); buffer_write(b, buffer_f32, rS);
    }

    self.writePointer = (self.writePointer + 1) % self.maxParticles;
    self.lastOffset = self.writePointer * pSize;

    // Statistical increment
    self.pool.aliveCount = min(self.pool.aliveCount + 1, self.maxParticles);
    self.totalSpawned++;

    return self.writePointer;
  }

  /**
   * @description Spawns a batch of particles instantly.
   * @param {UeParticleType} type Particle template.
   * @param {int} count Number of particles.
   * @param {real} positionX Position X position.
   * @param {real} positionY Position Y position.
   * @param {real} positionZ Position Z position.
   * @returns {UeParticleEmitter}
   */
  static burst = function (type, count, positionX = 0, positionY = 0, positionZ = 0) {
    if (self.isDestroyed) return self;
    repeat(count) { self.spawn(type, positionX, positionY, positionZ); }
    return self;
  }

  /**
   * @description Handles periodic emission logic and statistically updates aliveCount.
   * @param {real} dt Seconds elapsed since last update.
   * @param {real} positionX Position X position.
   * @param {real} positionY Position Y position.
   * @param {real} positionZ Position Z position.
   */
  static update = function (dt, positionX, positionY, positionZ) {
    if (self.enabled && self.streamType != undefined && self.streamRate > 0) {
      self._accumulator += dt * self.streamRate * self.lodRates[self.lodLevel];

      while (self._accumulator >= 1) {
        self.spawn(self.streamType, positionX, positionY, positionZ);
        self._accumulator--;
      }
    }

    // Statistical Decay: O(1) estimation of alive particles
    if (self.pool.aliveCount > 0 && self.streamType != undefined) {
      var decayRate = self.pool.aliveCount / self.streamType.avgLife;
      self.pool.aliveCount -= decayRate * dt;
      if (self.pool.aliveCount < 0.05) self.pool.aliveCount = 0;
    }
  }

  /**
   * @description Submits the emitter's internal GPU buffer for drawing if not culled.
   * @param {resource.camera} camera Camera for billboard extraction.
   * @param {texture} depthTex Optional depth texture.
   * @param {array} depthParams [near, far, softness]
   * @param {texture} shadowTex Optional shadow map texture.
   * @param {array} shadowMatrix 4x4 matrix for shadow projection.
   * @param {array} shadowParams [strength, bias, resolution]
   */
  static render = function (camera, depthTex = undefined, depthParams = undefined, shadowTex = undefined, shadowMatrix = undefined, shadowParams = undefined) {
    if (self.isDestroyed) return;
    if (self.spawnedAny) {
      if (self.lastOffset > self.firstOffset) {
        // Update solo la porzione modificata
        vertex_update_buffer_from_buffer(self.vbuffer, self.firstOffset, self.rawBuffer, self.firstOffset, self.lastOffset - self.firstOffset);
      } else {
        // Wrap: Update tutto (per semplicitá e velocitá)
        vertex_update_buffer_from_buffer(self.vbuffer, 0, self.rawBuffer);
      }
      self.spawnedAny = false;
    }
    if (self.vbuffer == undefined || self.streamType == undefined) return;
    global.UE_PARTICLE_RENDERER.submit(self, camera, self.streamType, depthTex, depthParams, shadowTex, shadowMatrix, shadowParams);
  }

  /**
   * @description Clears all active particles from the emitter by resetting pointers and zeroing the buffer.
   * @returns {UeParticleEmitter}
   */
  static clear = function () {
    buffer_fill(self.rawBuffer, 0, buffer_u8, 0, buffer_get_size(self.rawBuffer));
    self.writePointer = 0;
    self.spawnedAny = true;
    self.firstOffset = 0;
    self.lastOffset = 0;
    self.pool.aliveCount = 0;
    return self;
  }

  /**
   * @description Properly releases GPU and CPU memory used by this emitter.
   */
  static destroy = function () {
    if (self.isDestroyed) return;
    self.isDestroyed = true;
    if (buffer_exists(self.rawBuffer)) buffer_delete(self.rawBuffer);
    if (self.vbuffer != undefined) vertex_delete_buffer(self.vbuffer);
  }
}
