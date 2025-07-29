---
sidebar_position: 10
---

A raycaster utility for performing ray-object intersection tests in 3D space.  
Supports raycasting against objects and their children, with parameters customizable per object type.

### Constructor

```js
UeRaycaster(origin = new UeVector3(), direction = new UeVector3(0, 0, -1), near = 0, far = infinity)
```

### Properties

| Property | Type     | Description                                                           |
| -------- | -------- | -----------------------------------------------                       |
| `ray`    | `UeRay`  | Ray used for intersection testing                                     |
| `near`   | `number` | Near clipping distance for intersections                              |
| `far`    | `number` | Far clipping distance for intersections                               |
| `camera` | `Object` | Camera reference used for coordinate conversion                       |
| `layers` | `Object` | Objects must share at least one layer with the raycaster (layer 0 is enabled by default) |


## Methods

| Method                                                             | Returns | Description                                                                                     |
| ------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| `set(origin, direction)`                                           | `self`  | Sets the ray origin and direction                                                            |
| `setFromCamera(mouse_x, mouse_y, camera)`                          | `self`  | Sets the ray based on device mouse coordinates and camera                             |
| `intersectObject(object, recursive = true, hits = [])`   | `Array` | Intersects ray with an object and optionally its descendants recursively, returning sorted hits by distance |
| `intersectObjects(objects, recursive = true, hits = [])` | `Array` | Intersects ray with multiple objects, optionally recursive, returning sorted hits by distance              |

## Usage example

```js
const raycaster = new UeRaycaster();
raycaster.setFromCamera(100, 100, camera);
const hits = raycaster.intersectObjects(scene.children);
if (array_length(hits) > 0) {
  show_debug_message("Hit object:", hits[0].object);
}
```
