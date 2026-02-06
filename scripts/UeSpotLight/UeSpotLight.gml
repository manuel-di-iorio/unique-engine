/**
 * @description A light that gets emitted from a single point in one direction, along a cone.
 * @param {Real|Array} [_color=c_white] The light's color.
 * @param {Real} [_intensity=1] The light's strength/intensity.
 * @param {Real} [_distance=0] Maximum range of the light.
 * @param {Real} [_angle=60] Maximum angle of light dispersion from its direction (in degrees).
 * @param {Real} [_penumbra=0] Percent of the spotlight cone that is attenuated due to penumbra [0,1].
 * @param {Real} [_decay=2] The amount the light dims along the distance of the light.
 * @param {Struct} [data={}] Additional configuration data.
 */
function UeSpotLight(_color = c_white, _intensity = 100, _distance = 20, _angle = 30, _penumbra = 1, _decay = 2, data = {}): UeLight(data) constructor {

  isSpotLight = true;
  lightType = "SpotLight";

  self.setColor(_color);
  self.intensity = _intensity;
  self.distance = _distance;
  self.angle = _angle;
  self.penumbra = clamp(_penumbra, 0.0, 1.0);
  self.decay = _decay;

  static setDistance = function(_distance) {
    gml_pragma("forceinline");
    distance = _distance;
    paramsVersion++;
  }

  static setDecay = function(_decay) {
    gml_pragma("forceinline");
    decay = _decay;
    paramsVersion++;
  }

  static setAngle = function(_angle) {
    gml_pragma("forceinline");
    angle = _angle;
    paramsVersion++;
  }

  static setPenumbra = function(_penumbra) {
    gml_pragma("forceinline");
    penumbra = clamp(_penumbra, 0.0, 1.0);
    paramsVersion++;
  }

  // Target is an Object3D that the light points at (default: origin)
  target = new UeObject3D({ x: data[$ "xt"] ?? 0, y: data[$ "yt"] ?? 0, z: data[$ "zt"] ?? 0 });

  /**
   * @property {Real} power The light's power measured in lumens.
   * Changing the power will also change the light's intensity.
   */
  static getPower = function () {
    gml_pragma("forceinline");
    return self.intensity * pi;
  };
      
  static setPower = function (_power) {
    gml_pragma("forceinline");
    self.intensity = _power / pi;
  };

  // Shadow support for spot lights
  var _shadowFar = data[$ "shadowFar"] ?? self.distance;

  shadow = new UeSpotLightShadow({
    near: data[$ "shadowNear"] ?? .5,
    far: _shadowFar,
    mapWidth: data[$ "shadowMapWidth"] ?? 1024,
    mapHeight: data[$ "shadowMapHeight"] ?? 1024
  });

  // Caching
  __direction = vec3_create();
  __lastWorldPosition = vec3_create(infinity, infinity, infinity);
  __lastWorldTargetPosition = vec3_create(infinity, infinity, infinity);

  /**
   * Gets the current light direction (normalized vector from position to target).
   * @params {Array} v - Output vector (vec3)
   * @returns {Array} Normalized direction vector (vec3)
   */
  function getDirection(v = global.UE_VEC3_TEMP0) {
    gml_pragma("forceinline");
    
    var wp = global.UE_VEC3_TEMP1;
    var wtp = global.UE_VEC3_TEMP2;
    self.getWorldPosition(wp);
    target.getWorldPosition(wtp);

    if (!vec3_equals(wp, __lastWorldPosition) || !vec3_equals(wtp, __lastWorldTargetPosition)) {
      vec3_copy(__direction, wtp);
      vec3_sub(__direction, wp);
      vec3_normalize(__direction);
      vec3_copy(__lastWorldPosition, wp);
      vec3_copy(__lastWorldTargetPosition, wtp);
    }
    vec3_copy(v, __direction);

    return v;
  }
}
