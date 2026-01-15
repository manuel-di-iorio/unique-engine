---
sidebar_position: 6
---

The `UeLOD` (Level of Detail) class is a specialized object that switches between different objects based on the distance to the camera. This is a common optimization technique to reduce the number of vertices and draw calls for distant objects.

## Constructor
```js
new UeLOD(data = {})
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

## Data parameters

| Key          | Type      | Default | Description                                      |
| ------------ | --------- | ------- | ------------------------------------------------ |
| `autoUpdate` | `boolean` | `true`  | Whether the LOD should automatically update each frame |

## Properties

| Property      | Type      | Default  | Description                                                                 |
| ------------- | --------- | -------- | --------------------------------------------------------------------------- |
| `isLOD`       | `boolean` | `true`   | Identifies this object as an LOD object                                     |
| `type`        | `string`  | `"LOD"`  | Object type                                                                 |
| `autoUpdate`  | `boolean` | `true`   | Whether the LOD should automatically update its level based on camera distance |
| `levels`      | `array`   | `[]`     | An array of objects containing `{ object, distance, hysteresis }`           |

## Methods

| Method                               | Returns       | Description                                                                                                                                                                 |
| ------------------------------------ | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `addLevel(object, distance, hysteresis)` | `self`        | Adds a new level of detail. `distance` is the threshold to switch to this level. `hysteresis` prevents flickering at boundaries by adding a margin to the switch threshold. |
| `getCurrentLevel()`                  | `number`      | Returns the index of the currently active level.                                                                                                                            |
| `getObjectForDistance(distance)`     | `UeObject3D`  | Returns the object corresponding to the specified distance.                                                                                                                 |
| `removeLevel(index)`                 | `self`        | Removes the level at the specified index.                                                                                                                                  |
| `update(camera)`                     | `self`        | Manually updates the LOD level based on the distance to the provided camera. This is called automatically if `autoUpdate` is true.                                          |
| `raycast(raycaster, intersects)`     | `self`        | Performs raycasting against the currently active LOD object.                                                                                                                |

## Example

```js
var lod = new UeLOD();

var highRes = new UeMesh(new UeBoxGeometry(1, 1, 1), new UeMeshBasicMaterial({ color: c_red }));
var midRes = new UeMesh(new UeBoxGeometry(1, 1, 1), new UeMeshBasicMaterial({ color: c_yellow }));
var lowRes = new UeMesh(new UeBoxGeometry(1, 1, 1), new UeMeshBasicMaterial({ color: c_green }));

lod.addLevel(highRes, 0);      // High detail when close (0-50 units)
lod.addLevel(midRes, 50, 0.1); // Mid detail (50-100 units) with 10% hysteresis
lod.addLevel(lowRes, 100);     // Low detail (100+ units)

scene.add(lod);
```
