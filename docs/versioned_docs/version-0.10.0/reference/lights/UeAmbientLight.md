# UeAmbientLight

This light globally illuminates all objects in the scene equally.

This light cannot be used to cast shadows as it does not have a direction.

## Code Example

```gml
var light = new UeAmbientLight(0x404040); // soft white light
scene.add(light);
```

## Constructor

### `UeAmbientLight(color, data)`

Constructs a new ambient light.

- `color`: The light's color (hex or `[r, g, b]`). Default is `c_white`.
- `data`: Optional configuration object.

## Properties

See the base [UeLight](UeLight.md) class for common properties.

### `.isAmbientLight` (readonly)
This flag can be used for type testing. Default is `true`.
