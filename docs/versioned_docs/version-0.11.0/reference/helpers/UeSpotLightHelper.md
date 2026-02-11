---
sidebar_position: 8
---

# UeSpotLightHelper

Helper object to assist with visualizing a `UeSpotLight` effect on the scene. This consists of a cone mesh that matches the light's angle and range.

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

## Constructor

```js
new UeSpotLightHelper(light, color = undefined, data = {})
```

### Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| light | `UeSpotLight` | `undefined` | The light to be visualized. |
| color | `Color` | `undefined` | The helper's color. If not set, the helper will take the color of the light. |
| data | `struct` | `{}` | Additional data. |

## Properties

| Property | Type | Description |
| --- | --- | --- |
| `light` | `UeSpotLight` | The `UeSpotLight` being visualized. |
| `color` | `Color` | The color parameter passed in the constructor. |
| `mesh` | `UeMesh` | The cone mesh used for visualization. |

## Methods

| Method | Returns | Description |
| --- | --- | --- |
| `.update()` | `self` | Updates the helper's position, rotation, scale, and color to match the light's current state. |
| `.dispose()` | `self` | Frees the GPU-related resources allocated by this instance. |

## Example

```js
const light = new UeSpotLight(c_white, 1, 500, degtorad(30));
scene.add(light);

const helper = new UeSpotLightHelper(light);
scene.add(helper);

// In your step/update event
helper.update();
```
