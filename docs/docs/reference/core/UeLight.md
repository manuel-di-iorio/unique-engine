---
sidebar_position: 9
---

All lights in Unique Engine inherit from `UeLight`. These include `AmbientLight`, `DirectionalLight`, and `PointLight`.

Lights affect materials that have lighting enabled (e.g. `UeMeshStandardMaterial`) and are collected by the renderer from the scene.

---

```js
new UeLight(data = {})
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

### Properties

| Property    | Type      | Default     | Description                                    |
| ----------- | --------- | ----------- | ---------------------------------------------- |
| `isLight`   | `boolean` | `true`      | Identifies this object as a light              |
| `type`      | `string`  | `Light`     | Object type                                    |
| `name`      | `string`  | undefined   | Object name (optional)                         |
| `lightType` | `string`  | `"Light"`   | Specific light type (`"AmbientLight"`, etc.)   |
| `intensity` | `number`  | `1`         | Brightness multiplier for this light           |
| `enabled`   | `boolean` | `true`      | Whether the light is currently active          |
| `range`     | `number`  | `undefined` | (Only for point lights) max influence distance |
| `color`     | `array`   | `c_dkgray`  | RGB color as normalized array `[r, g, b]`      |

## Methods

```js
setColor(color)
```
Sets the RGB color of the light. Accepts a GM color constant like c_red.

```js
toJSON()
```

Returns an object representing this entity's properties. Not all props may be included.

🌌 **UeAmbientLight**

```js
new UeAmbientLight(color = c_white, data = {})
```
Ambient lights apply uniform color to all visible fragments. They are not directional and don't cast shadows.

🌞 **UeDirectionalLight**
```js
new UeDirectionalLight(horizontal = 0, vertical = 0, data = {})
```
Simulates sunlight-like directional lighting, affecting all objects from a direction (starting from the forward vector, rotated around XZ axes).

**Properties**

| Property     | Type        | Default        | Description                            |
| --------     | ----------- | -------------- | -------------------------------------- |
| `horizontal` | `real`      | `0`            | Pitch direction (in degrees)           |
| `vertical`   | `real`      | `0`            | Yaw direction (in degrees)             |

Available methods: 
  
  - `setDirection(horizontal, vertical)`


💡 **UePointLight**

```js
new UePointLight(range = 1000, data = {})
```
Emits light in all directions from a single point, attenuated by distance.

**Extra Properties**
| Property | Type     | Default | Description                        |
| -------- | -------- | ------- | ---------------------------------- |
| `range`  | `number` | `1000`  | Maximum distance the light affects |


## 🔁 Usage in Scene

Lights should be added to a UeScene using .add() and will be automatically collected by UeRenderer.

```js
const ambient = new UeAmbientLight(c_gray);
const sun = new UeDirectionalLight(0, 45, { color: c_white, intensity: 2 });
const point = new UePointLight(500, { color: c_yellow });

scene.add(ambient, sun, point);
```

Lights are passed to the material shader through uniforms like:

- ueAmbient
- ueDirLightDir0, ueDirLightColor0, ueDirLightIntensity0
- uePointLightPosition0, uePointLightRange0, etc.

## Shadow Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `castShadow` | `boolean` | `false` | Whether this light casts shadows. If `true`, the renderer will create and update a shadow controller associated to the light. |
| `shadow` | `object` | `undefined` | Shadow controller object assigned when `castShadow` is enabled. For directional lights the controller is `UeDirectionalLightShadow`, for point lights the controller is `UePointLightShadow` (manages 6 faces). |

### Usage Example

```js
// Directional light with shadows
const sun = new UeDirectionalLight(0, 45, { color: c_white, intensity: 2 });
sun.castShadow = true;
sun.shadow.mapSize = 2048; // increase shadow resolution
sun.shadow.bias = 0.0005;
scene.add(sun);

// Point light with omnidirectional shadows
const lamp = new UePointLight(500, { color: c_yellow });
lamp.castShadow = true;
lamp.shadow.mapSize = 1024; // per-face resolution
lamp.shadow.far = 600; // max distance stored in shadow maps
scene.add(lamp);
```

