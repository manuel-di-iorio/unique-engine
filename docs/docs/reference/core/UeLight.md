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

🌌 **UeAmbientLight**

```js
new UeAmbientLight(data = {})
```
Ambient lights apply uniform color to all visible fragments. They are not directional and don’t cast shadows.

🌞 **UeDirectionalLight**
```js
new UeDirectionalLight(xt = 0, yt = 0, zt = 0, data = {})
```
Simulates sunlight-like directional lighting, affecting all objects from a direction but with no attenuation.

**Extra Properties**

| Property | Type        | Default        | Description                            |
| -------- | ----------- | -------------- | -------------------------------------- |
| `target` | `UeVector3` | `(xt, yt, zt)` | Direction the light is pointing toward |


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
const ambient = new UeAmbientLight({ color: c_gray });
const sun = new UeDirectionalLight(0, 0, -1, { color: c_white, intensity: 2 });
const point = new UePointLight(500, { color: c_yellow });

scene.add(ambient, sun, point);
```

Lights are passed to the material shader through uniforms like:

- ueAmbient
- ueDirLightDir0, ueDirLightColor0, ueDirLightIntensity0
- uePointLightPosition0, uePointLightRange0, etc.

