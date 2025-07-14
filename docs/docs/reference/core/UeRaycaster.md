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

| Property | Type     | Description                                     |
| -------- | -------- | ----------------------------------------------- |
| `ray`    | `UeRay`  | Ray used for intersection testing               |
| `near`   | `number` | Near clipping distance for intersections        |
| `far`    | `number` | Far clipping distance for intersections         |
| `camera` | `Object` | Camera reference used for coordinate conversion |
| `params` | `Object` | Parameters for raycasting per object type       |


## Methods

| Method                                                             | Returns | Description                                                                                     |
| ------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| `set(origin, direction)`                                           | `this`  | Sets the ray origin and direction                                                               |
| `setFromCamera(coords, camera)`                                    | `this`  | Sets the ray based on normalized device coordinates and camera type                             |
| `intersectObject(object, recursive = true, optionalTarget = [])`   | `Array` | Intersects ray with an object and optionally its descendants recursively, returning sorted hits |
| `intersectObjects(objects, recursive = true, optionalTarget = [])` | `Array` | Intersects ray with multiple objects, optionally recursive, returning sorted hits               |

## Usage example

```js
const raycaster = new UeRaycaster();
raycaster.setFromCamera(new UeVector3(0, 0), camera);
const intersects = raycaster.intersectObjects(scene.children);
if (array_length(intersects) > 0) {
  show_debug_message("Hit object:", intersects[0].object);
}
```
