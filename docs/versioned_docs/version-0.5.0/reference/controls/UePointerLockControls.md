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
| `sensitivityX` | `number` | `0.1` | Horizontal mouse sensitivity |
| `sensitivityY` | `number` | `0.1` | Vertical mouse sensitivity |

### Properties

| Property | Type | Description |
| :--- | :--- | :--- |
| `camera` | `UeCamera` | The controlled camera |
| `sensitivityX` | `number` | Horizontal mouse sensitivity |
| `sensitivityY` | `number` | Vertical mouse sensitivity |
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

## 🧠 Notes

- **Input capture**: The lock is requested on the first left-click inside the game view. Pressing `Escape` (default browser/engine behavior) will release the lock.
- **Orientation**: The camera rotation is clamped between -89 and +89 degrees on the vertical (pitch) axis to prevent flipping.
- **Direction**: The controls update the `camera.target` property based on the calculated direction, while the camera's `position` remains independent (allowing the user to handle movement separately).
- **Inheritance**: It inherits from `UeControls`, so it can be enabled/disabled via the `enabled` property.

### Example

```js
// Initialize controls
const controls = new UePointerLockControls(camera, { 
    sensitivityX: 0.08,
    sensitivityY: 0.08
});

// In your update loop
function update() {
    controls.update();
    
    // Example: move camera position separately
    if (keyboard_check(ord("W"))) {
        camera.translateZ(5);
    }
}
```
