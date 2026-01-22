# UeSpotLight

A light that gets emitted from a single point in one direction, along a cone that increases in size the further from the light it gets.

This light can cast shadows - see [UeSpotLightShadow](shadows/UeSpotLightShadow.md) page for details.

## Code Example

```gml
// white spotlight shining from the side, casting a shadow
var spotLight = new UeSpotLight(0xffffff);
spotLight.position.set(100, 1000, 100);
spotLight.castShadow = true;
spotLight.shadow.mapSize.set(1024, 1024);
spotLight.shadow.camera.near = 500;
spotLight.shadow.camera.far = 4000;
spotLight.shadow.camera.fov = 30;
scene.add(spotLight);
```

## Constructor

### `UeSpotLight(color, intensity, distance, angle, penumbra, decay, data)`

Constructs a new spot light.

- `color`: The light's color (hex or `[r, g, b]`). Default is `c_white`.
- `intensity`: The light's strength/intensity. Default is `1`.
- `distance`: Maximum range of the light. Default is `0` (no limit).
- `angle`: Maximum angle of light dispersion from its direction (in degrees). Default is `30`.
- `penumbra`: Percent of the spotlight cone that is attenuated due to penumbra. Default is `0`.
- `decay`: The amount the light dims along the distance of the light. Default is `2`.
- `data`: Optional configuration object.

## Properties

See the base [UeLight](UeLight.md) class for common properties.

### `.isSpotLight` (readonly)
Used to check whether this or derived classes are spot lights. Default is `true`.

### `.target`
The SpotLight points from its `position` to `target.position`. The default position of the target is `(0, 0, 0)`.

### `.distance`
If non-zero, the light's intensity will also attenuate linearly from this distance. Default is `0`.

### `.angle`
Maximum extent of the spotlight, in degrees, from its direction. Should be no more than 90. Default is `30`.

### `.penumbra`
Percent of the spotlight cone that is attenuated due to penumbra. Takes values between zero and one. Default is `0`.

### `.decay`
The amount the light dims along the distance of the light. Default is `2`.

### `.shadow`
A [UeSpotLightShadow](shadows/UeSpotLightShadow.md) used to calculate shadows for this light.

### `.power`
The light's power measured in lumens. Changing the power will also change the light's intensity.

## Methods

See the base [UeLight](UeLight.md) class for common methods.

### `.getDirection()`
Returns the normalized direction vector from the light's position to its target.

### `.getPower()`
Returns the light's power.

### `.setPower(power)`
Sets the light's power.

### `.setDistance(distance)`
Sets the maximum range of the light.

### `.setDecay(decay)`
Sets the amount the light dims along the distance of the light.

### `.setAngle(angle)`
Sets the maximum angle of light dispersion from its direction (in degrees).

### `.setPenumbra(penumbra)`
Sets the percent of the spotlight cone that is attenuated due to penumbra.
