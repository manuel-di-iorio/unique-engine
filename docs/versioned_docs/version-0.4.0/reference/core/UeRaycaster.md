---
sidebar_position: 10
---

A raycaster utility for performing ray-object intersection tests in 3D space.  
Supports raycasting against objects and their children, with parameters customizable per object type.  
Works with both perspective and orthographic cameras.

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
| `setFromCamera(camera)`                                  | `self`  | Sets the ray based on mouse coordinates and camera (supports both perspective and orthographic) |
| `intersectObject(object, recursive = true, sort = true, hits = [])`   | `Array` | Intersects ray with an object and optionally its descendants recursively, returning sorted hits by distance |
| `intersectObjects(objects, recursive = true, sort = true, hits = [])` | `Array` | Intersects ray with multiple objects, optionally recursive, returning sorted hits by distance              |

## Camera Support

The raycaster works differently depending on the camera type:

### Perspective Camera
- Ray origin is at the camera position
- Ray direction is calculated from camera position to the mouse point in world space
- Rays diverge from the camera (like a cone)

### Orthographic Camera
- Ray origin is calculated from mouse position on the viewing plane
- Ray direction is the camera's forward vector
- All rays are parallel (characteristic of orthographic projection)

## Usage example

### With Perspective Camera
```js
const camera = new UePerspectiveCamera();
const raycaster = new UeRaycaster();
raycaster.setFromCamera(camera);
const hits = raycaster.intersectObjects(scene.children);
if (array_length(hits) > 0) {
  show_debug_message("Hit object:", hits[0].object);
}
```

### With Orthographic Camera
```js
const camera = new UeOrthographicCamera();
const raycaster = new UeRaycaster();
raycaster.setFromCamera(camera);
const hits = raycaster.intersectObjects(scene.children);
// Raycasting works the same way, but uses parallel rays
if (array_length(hits) > 0) {
  show_debug_message("Hit object:", hits[0].object);
}
```
