# UeHemisphereLight

A light source positioned directly above the scene, with color fading from the sky color to the ground color.

This light cannot be used to cast shadows.

## Code Example

```gml
var light = new UeHemisphereLight(0xffffbb, 0x080820, 1);
scene.add(light);
```

## Constructor

### `UeHemisphereLight(skyColor, groundColor, intensity, data)`

Constructs a new hemisphere light.

- `skyColor`: The light's sky color (hex or `[r, g, b]`). Default is `c_white`.
- `groundColor`: The light's ground color (hex or `[r, g, b]`). Default is `c_white`.
- `intensity`: The light's strength/intensity. Default is `1`.
- `data`: Optional configuration object.

## Properties

### `.skyColor`
The light's sky color as an array `[r, g, b]`.

### `.groundColor`
The light's ground color as an array `[r, g, b]`.

### `.intensity`
The light's strength/intensity.

### `.isHemisphereLight` (readonly)
This flag can be used for type testing. Default is `true`.

## Methods

### `.setSkyColor(color)`
Sets the sky color. Accepts hex color or `[r, g, b]` array.

### `.setGroundColor(color)`
Sets the ground color. Accepts hex color or `[r, g, b]` array.
