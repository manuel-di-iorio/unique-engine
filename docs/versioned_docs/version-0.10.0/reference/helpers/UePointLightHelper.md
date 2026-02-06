---
sidebar_position: 7
---

Helper object to assist with visualizing a `UePointLight` effect on the scene. This consists of an octahedron mesh for visualizing an instance of PointLight.

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

## Constructor

```js
new UePointLightHelper(light, sphereSize = 1, color = undefined, data = {})
```

### Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| light | `UePointLight` | `undefined` | The light to be visualized. |
| sphereSize | `number` | `1` | The size of the octahedron. |
| color | `Color` | `undefined` | The helper's color. If not set, the helper will take the color of the light. |
| data | `struct` | `{}` | Additional data. |

## Properties

| Property | Type | Description |
| --- | --- | --- |
| `light` | `UePointLight` | The `UePointLight` being visualized. |
| `color` | `Color` | The color parameter passed in the constructor. |
| `sphereSize` | `number` | The size of the octahedron. |
| `mesh` | `UeMesh` | The octahedron mesh used for visualization. |

## Methods

| Method | Returns | Description |
| --- | --- | --- |
| `.update()` | `self` | Updates the helper position and color to match the light. |
| `.dispose()` | `self` | Frees the GPU-related resources allocated by this instance. |

## Example

```js
const light = new UePointLight(c_white, 1, 100);
scene.add(light);

const helper = new UePointLightHelper(light, 5);
scene.add(helper);

// In your step/update event
helper.update();
```
