/** 
* @description Manages a group of particle emitters and handles high-level culling and LOD.
*/
function UeParticleSystem() constructor {
  gml_pragma("forceinline");
  self.emitters = [];
  self.renderer = global.UE_PARTICLE_RENDERER;
  self.enabled = true;

  self.lodEnabled = true;
  self.frustumCulling = true;
  self.sortingEnabled = false; 

  self.positionX = 0;
  self.positionY = 0;
  self.positionZ = 0;

  /**
   * @description Sets the position point to move all new particles for all emitters.
   * @param {real} px Position X.
   * @param {real} py Position Y.
   * @param {real} pz Position Z.
   */
  static setPosition = function (px, py, pz) {
    self.positionX = px;
    self.positionY = py;
    self.positionZ = pz;
  }

  /** 
  * @description Registers an emitter within this system.
  * @param {UeParticleEmitter} emitter The emitter instance.
  * @returns {UeParticleEmitter}
  */ 
  static addEmitter = function (emitter) {
    gml_pragma("forceinline");
    array_push(self.emitters, emitter);
    return emitter;
  }

  /** 
  * @description Updates all managed emitters. Handles LOD calculations and emission.
  * @param {real} dt Delta time in seconds (optional).
  * @param {real} cx Camera X position for LOD (optional).
  * @param {real} cy Camera Y position for LOD (optional).
  * @param {real} cz Camera Z position for LOD (optional).
  */ 
  static update = function (dt = undefined, cx = undefined, cy = undefined, cz = undefined) {
    gml_pragma("forceinline");
    if (!self.enabled) return;

    if (dt == undefined) { 
      static _dtCache = 0; static _lastFrame = -1;
      if (current_time != _lastFrame) {
        _dtCache = delta_time / 1000000; _lastFrame = current_time;
      }
      dt = _dtCache;
    }

    var emitters = self.emitters;
    var lod = self.lodEnabled && (cx != undefined);

    for (var i = 0, il = array_length(emitters); i < il; i++) {
      var emitter = emitters[i];
      if (lod) emitter.updateLOD(cx, cy, cz, self.positionX, self.positionY, self.positionZ);
      emitter.update(dt, self.positionX, self.positionY, self.positionZ);
    }
  }

  /** 
  * @description Calls render on all visible emitters. Handles blend modes automatically.
  * @param {resource.camera} camera Camera index to use for billboarding extraction.
  * @param {texture} depthTex Optional depth texture for soft particles.
  * @param {real} softness Amount of softness (default 100).
  * @param {real} near Near plane (optional, for linearization).
  * @param {real} far Far plane (optional, for linearization).
  * @param {texture} shadowTex Optional shadow map texture.
  * @param {array} shadowMatrix 4x4 matrix for shadow projection.
  * @param {real} shadowStrength Amount of shadowing (0-1).
  * @param {real} shadowBias Bias to avoid shadow acne.
  */ 
  static render = function (camera = undefined, depthTex = undefined, softness = 100, near = 0.1, far = 1000, shadowTex = undefined, shadowMatrix = undefined, shadowStrength = 0.5, shadowBias = 0.001) {
    gml_pragma("forceinline");
    if (!self.enabled) return;
    camera ??= view_camera[0];

    var emitters = self.emitters;
    var culling = self.frustumCulling;
    var _bm = gpu_get_blendmode();
    var _depthParams = [near, far, softness];
    var _shadowParams = [shadowStrength, shadowBias, 0]; // Resolution not used for now

    for (var i = 0, il = array_length(emitters); i < il; i++) {
      var emitter = emitters[i];
      
      // Perform Frustum Culling via GameMaker's native sphere visibility check
      if (culling) {
          emitter.visible = sphere_is_visible(emitter.centerX, emitter.centerY, emitter.centerZ, emitter.cullingRadius);
      } else { 
          emitter.visible = true; 
      }

      if (emitter.visible && emitter.pool.aliveCount > 0) {
        var type = emitter.streamType;
        if (type != undefined) {
            gpu_set_blendmode(type.additive ? bm_add : bm_normal);
            emitter.render(camera, depthTex, _depthParams, shadowTex, shadowMatrix, _shadowParams);
        }
      }
    }
    gpu_set_blendmode(_bm);
  }

  /** 
  * @description Returns the total number of active particles across all emitters.
  * @returns {real}
  */ 
  static getTotalParticles = function () {
    var total = 0;
    for (var i = 0, il = array_length(self.emitters); i < il; i++) {
      total += self.emitters[i].pool.aliveCount;
    }
    return total;
  }

  /** 
  * @description Removes all emitters from the system and destroys their buffers.
  */ 
  static clear = function () {
    for (var i = 0, il = array_length(self.emitters); i < il; i++) {
        self.emitters[i].destroy();
    }
    self.emitters = [];
  }

  /** 
  * @description Performs final cleanup of all emitters.
  */ 
  static destroy = function () {
    self.clear();
  }

  /**
  * @description Bursts particles on all emitters that have a streamType.
  * @param {int} count
  */
  static burst = function (count) {
    for (var i = 0, il = array_length(self.emitters); i < il; i++) {
        var e = self.emitters[i];
        if (e.streamType != undefined) e.burst(e.streamType, count);
    }
  }
}
