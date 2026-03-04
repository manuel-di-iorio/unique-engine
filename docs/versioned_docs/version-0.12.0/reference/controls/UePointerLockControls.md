---
sidebar_position: 4
---

# UePointerLockControls

The `UePointerLockControls` class provides a first-person shooter (FPS) style camera control system.  
It uses the pointer lock API (via `window_mouse_set_locked`) to capture the mouse and allows looking around by moving the mouse, without the cursor hitting the edges of the screen.

### Constructor
```js
new UePointerLockControls(camera, data = {})
```

### Data parameters

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `pointerSpeedX` | `number` | `0.1` | Horizontal mouse speed |
| `pointerSpeedY` | `number` | `0.1` | Vertical mouse speed |
| `minPolarAngle` | `number` | `0` | Camera pitch lower limit (radians) |
| `maxPolarAngle` | `number` | `Math.PI` | Camera pitch upper limit (radians) |

### Properties

| Property | Type | Description |
| :--- | :--- | :--- |
| `camera` | `UeCamera` | The controlled camera |
| `pointerSpeedX` | `number` | Horizontal mouse speed |
| `pointerSpeedY` | `number` | Vertical mouse speed |
| `minPolarAngle` | `number` | Camera pitch lower limit. Range is `[0, Math.PI]` in radians |
| `maxPolarAngle` | `number` | Camera pitch upper limit. Range is `[0, Math.PI]` in radians |
| `yaw` | `number` | Current horizontal rotation (degrees) |
| `pitch` | `number` | Current vertical rotation (degrees) |
| `isLocked` | `boolean` | Whether the pointer is currently locked |

### 🧩 Methods

```js
update()
```
Updates the camera direction based on mouse movement.  
Must be called every frame.  
**Note**: It handles the lock request automatically on a left-click, but **only if the mouse is within the viewport** (using `global.UE_MOUSE` validation).

```js
lock()
```
Manually requests the pointer lock.

```js
unlock()
```
Releases the pointer lock.

```js
getDirection(target)
```
Returns a vector representing the current look direction.  
- **target**: An array `[x, y, z]` or struct `{x, y, z}` to store the result.

```js
moveForward(distance)
```
Moves the camera position forward along the ground plane (based on yaw).

```js
moveRight(distance)
```
Moves the camera position right relative to the current orientation.

### 🔔 Events

| Event | Description |
| :--- | :--- |
| `change` | Fires when the user moves the mouse. |
| `lock` | Fires when the pointer lock status is "locked". |
| `unlock` | Fires when the pointer lock status is "unlocked". |

## 🧠 Notes

- **Input capture**: The lock is requested on the first left-click inside the game view. Pressing `Escape` (default browser/engine behavior) will release the lock.
- **Orientation**: The camera orientation is clamped according to `minPolarAngle` and `maxPolarAngle`. The default range is `[0, Math.PI]`.
- **Direction**: The controls update the `camera.target` property based on the calculated direction.
- **Inheritance**: It inherits from `UeControls`, so it can be enabled/disabled via the `enabled` property.

### Example

```js
// Initialize controls
const controls = new UePointerLockControls(camera, { 
    pointerSpeedX: 0.08,
    pointerSpeedY: 0.08
});

// In your update loop
function update() {
    controls.update();
    
    // Example: move camera position using the control's methods
    if (keyboard_check(ord("W"))) {
        controls.moveForward(5);
    }
}
```
