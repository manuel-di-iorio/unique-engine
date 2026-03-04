# UePointLight

A light that gets emitted from a single point in all directions. This can be used to simulate light emitted from a light bulb.

This light can cast shadows - see [UePointLightShadow](shadows/UePointLightShadow.md) page for details.

## Code Example

```gml
var light = new UePointLight(0xffffff, 1, 100);
vec3_set(light.position, 50, 50, 50);
scene.add(light);
```

## Constructor

### `UePointLight(color, intensity, distance, decay, data)`

Constructs a new point light.

- `color`: The light's color (hex or `[r, g, b]`). Default is `c_white`.
- `intensity`: The light's strength/intensity. Default is `1`.
- `distance`: Maximum range of the light. Default is `0` (no limit).
- `decay`: The amount the light dims along the distance of the light. Default is `2`.
- `data`: Optional configuration object.

## Properties

See the base [UeLight](UeLight.md) class for common properties.

### `.isPointLight` (readonly)
Used to check whether this or derived classes are point lights. Default is `true`.

### `.distance`
If non-zero, the light's intensity will also attenuate linearly from this distance. Default is `0`.

### `.decay`
The amount the light dims along the distance of the light. Default is `2`.

### `.shadow`
A [UePointLightShadow](shadows/UePointLightShadow.md) used to calculate shadows for this light.

### `.power`
The light's power measured in lumens. Changing the power will also change the light's intensity.

## Methods

See the base [UeLight](UeLight.md) class for common methods.

### `.getPower()`
Returns the light's power.

### `.setPower(power)`
Sets the light's power.

### `.setDistance(distance)`
Sets the maximum range of the light.

### `.setDecay(decay)`
Sets the amount the light dims along the distance of the light.
