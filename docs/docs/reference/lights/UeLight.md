---
sidebar_position: 1
---

All lights in Unique Engine inherit from `UeLight`. This base class provides common properties and methods for all light types.

Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

## Constructor

### `UeLight(data)`

Constructs a new base light. This is typically not instantiated directly; use one of the specialized light classes instead.

- `data`: Optional configuration object.

## Properties

| Property    | Type      | Default     | Description                                    |
| ----------- | --------- | ----------- | ---------------------------------------------- |
| `isLight`   | `boolean` | `true`      | Identifies this object as a light              |
| `type`      | `string`  | `Light`     | Object type                                    |
| `name`      | `string`  | undefined   | Object name (optional)                         |
| `lightType` | `string`  | `"Light"`   | Specific light type (`"AmbientLight"`, etc.)   |
| `intensity` | `number`  | `1`         | Brightness multiplier for this light           |
| `enabled`   | `boolean` | `true`      | Whether the light is currently active          |
| `color`     | `array`   | `[0.5, 0.5, 0.5]` | RGB color as normalized array `[r, g, b]`      |

## Methods

### `.setColor(color)`
Sets the RGB color of the light. Accepts a GM color constant (e.g., `c_red`) or an `[r, g, b]` array.

### `.toJSON()`
Returns an object representing this light's properties.


## 🔁 Usage in Scene

Lights should be added to a `UeScene` using `.add()` and will be automatically collected by `UeRenderer`.

```js
const ambient = new UeAmbientLight(c_gray);
const sun = new UeDirectionalLight(c_white, 2);
const point = new UePointLight(c_yellow, 1, 500);
const hemi = new UeHemisphereLight(c_white, c_gray, 1);

scene.add(ambient);
scene.add(sun);
scene.add(point);
scene.add(hemi);
```

## 🌑 Shadows

Lights can cast shadows when `castShadow` is enabled. The renderer will create and update shadow maps for each shadow-casting light.

**Note:** `UeAmbientLight` and `UeHemisphereLight` do not support shadow casting.

| Property     | Type      | Default | Description                                                  |
| ------------ | --------- | ------- | ------------------------------------------------------------ |
| `castShadow` | `boolean` | `false` | Whether this light casts shadows                             |
| `shadow`     | `object`  | Auto-created | Shadow controller (type depends on light)                |

See the specific light documentation for details on shadow configuration:
- [UeDirectionalLight](UeDirectionalLight.md)
- [UePointLight](UePointLight.md)
- [UeSpotLight](UeSpotLight.md)
- [UeHemisphereLight](UeHemisphereLight.md) (No shadows)

## ⚙️ Renderer Configuration

To enable shadow rendering, you must configure the [UeRenderer](/docs/reference/core/UeRenderer):

```js
renderer.shadowMap.enabled = true;
renderer.shadowMap.autoUpdate = true;
```

For more advanced shadow settings, see the [UeShadowMap](shadows/UeShadowMap.md) documentation.

