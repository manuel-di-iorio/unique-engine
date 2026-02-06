# UeHemisphereLightHelper

Helper object to assist with visualizing a [UeHemisphereLight](../lights/UeHemisphereLight.md).

## Code Example

```gml
var light = new UeHemisphereLight(c_white, c_gray, 1);
var helper = new UeHemisphereLightHelper(light, 5);
scene.add(helper);
```

## Constructor

### `UeHemisphereLightHelper(light, size, data)`

Constructs a new hemisphere light helper.

- `light`: The light to be visualized.
- `size`: The size of the helper. Default is `1`.
- `data`: Optional configuration object.

## Properties

### `.light`
The light being visualized.

### `.size`
The size of the helper.

## Methods

### `.update()`
Updates the helper's position and orientation to match the light. This is called automatically by the renderer.
