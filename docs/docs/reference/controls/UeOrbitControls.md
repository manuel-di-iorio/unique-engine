---
sidebar_position: 2
---

The `UeOrbitControls` class allows orbit-style camera manipulation around a target point.  
It supports mouse drag, scroll wheel zoom, keyboard pan/rotation, and inertia damping.

### Constructor
```js
new UeOrbitControls(camera, uiSceneNode = undefined, data = {})
```

### Data parameters

| Key                  | Type        | Default      | Description                         |
| -------------------- | ----------- | ------------ | ----------------------------------- |
| `target`             | `UeVector3` | `(0,0,0)`    | The center point to orbit around    |
| `zoomSpeed`          | `number`    | `5`          | Scroll/drag zoom speed              |
| `panSpeed`           | `number`    | `1.0`        | Mouse pan speed                     |
| `rotateSpeed`        | `number`    | `1.0`        | Mouse rotation speed                |
| `autoRotate`         | `boolean`   | `false`      | Enables idle rotation               |
| `enableZoom`         | `boolean`   | `true`       | Enables zooming                     |
| `enablePan`          | `boolean`   | `true`       | Enables panning                     |
| `enableRotate`       | `boolean`   | `true`       | Enables orbit rotation              |
| `enableDamping`      | `boolean`   | `true`       | Enables inertia smoothing           |
| `dampingFactor`      | `number`    | `1.0`        | Lerp factor for smooth motion       |
| `autoRotateSpeed`    | `number`    | `0.1`        | Speed of automatic rotation         |
| `minTargetRadius`    | `number`    | `5`          | Minimum zoom radius                 |
| `maxTargetRadius`    | `number`    | `Infinity`   | Maximum zoom radius                 |
| `screenSpacePanning` | `boolean`   | `false`      | Whether pan is screen-space aligned |
| `enableFlythrough`   | `boolean`   | `true`       | Enables FPS-style flythrough mode   |
| `flythroughSpeed`    | `number`    | `5.0`       | Base speed for flythrough movement  |

### Properties

| Property            | Type        | Description                       |
| ------------------- | ----------- | --------------------------------- |
| `camera`            | `UeCamera`  | The controlled camera             |
| `target`            | `UeVector3` | The focal point being orbited     |
| `radius`            | `number`    | Distance from camera to target    |
| `azimuth`           | `number`    | Horizontal angle (radians)        |
| `elevation`         | `number`    | Vertical angle (radians)          |
| `enableZoom`        | `boolean`   | Enables zooming                   |
| `enablePan`         | `boolean`   | Enables panning                   |
| `enableRotate`      | `boolean`   | Enables orbit rotation            |
| `enableDamping`     | `boolean`   | Enables inertia smoothing         |
| `dampingFactor`     | `number`    | Lerp factor for smooth motion     |
| `mouseButtonRotate` | `number`    | Mouse button for orbit rotation   |
| `mouseButtonZoom`   | `number`    | Mouse button for zoom drag        |
| `mouseButtonPan`    | `number`    | Mouse button for panning          |
| `keys`              | `object`    | Directional keyboard key mappings |
| `transforming`      | `boolean`   | Whether the camera is being orbited with the mouse (read-only) |

## 🧩 Methods

```js
update(mouseX = undefined, mouseY = undefined)
```
Updates the camera position and direction based on current input.
Must be called every frame in the game loop.
Optionally takes the mouse coordinates in input, otherwise it will get it automatically from the `UeMouse` class

```js
focus(targetObject)
```
Focuses the camera on a specific object. 
It centers the camera on the object's bounding box and adjusts the radius for an optimal view based on the object's dimensions.

```js
reset()
```
Resets the controls to their initial state.


## 🧠 Notes

The control scheme is similar to Three.js OrbitControls.

- Rotation is performed by dragging with the left mouse button (by default).
- Zoom is handled via scroll wheel or dragging with the middle mouse button.
- Pan can be done via the right mouse button or arrow keys.
- Holding Shift switches keyboard input from pan to orbit.

### 🚀 Flythrough Mode

Hold the **Right Mouse Button** to enter Flythrough (FPS) mode:
- **WASD**: Move forward/backward/left/right.
- **Q / E**: Move down / up.
- **Shift**: Double movement speed.
- **Scroll Wheel**: Adjust base flythrough speed.
- **Mouse Look**: Look around.
- **Mouse Warping**: The mouse will warp to the opposite side if it reaches the scene boundaries (requires `uiSceneNode`).

To use:

```js
const controls = new UeOrbitControls(camera, uiSceneNode);
```

```js
// Inside your main update loop:
controls.update();
```

## 📐 Camera Behavior

The camera position is computed as:

```js
// pseudocode
position = target + radius * direction_from_angles(azimuth, elevation)
```
This allows intuitive orbiting around any arbitrary point in 3D space.
