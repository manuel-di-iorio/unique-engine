# UeDirectionalLight

A light that is emitted from a specific direction. This light will behave as though it is infinitely far away and the rays produced from it are all parallel.

The common use case for this is to simulate daylight; the sun is far enough away that its position can be considered to be infinite, and all light rays coming from it are parallel.

This light can cast shadows - see [UeDirectionalLightShadow](shadows/UeDirectionalLightShadow.md) page for details.

## Code Example

```gml
// Create a directional light
var light = new UeDirectionalLight(0xffffff, 1);
vec3_set(light.position, 5, 10, 5);
vec3_set(light.target.position, 0, 0, 0);
scene.add(light);
```

## Constructor

### `UeDirectionalLight(color, intensity, data)`

Constructs a new directional light.

- `color`: The light's color (hex or `[r, g, b]`). Default is `c_white`.
- `intensity`: The light's strength/intensity. Default is `1`.
- `data`: Optional configuration object.

## Properties

See the base [UeLight](UeLight.md) class for common properties.

### `.isDirectionalLight` (readonly)
Used to check whether this or derived classes are directional lights. Default is `true`.

### `.target`
The DirectionalLight points from its `position` to `target.position`. The default position of the target is `(0, 0, 0)`.

### `.shadow`
A [UeDirectionalLightShadow](shadows/UeDirectionalLightShadow.md) used to calculate shadows for this light.

## Methods

See the base [UeLight](UeLight.md) class for common methods.

### `.getDirection()`
Returns the normalized direction vector from the light's position to its target.
