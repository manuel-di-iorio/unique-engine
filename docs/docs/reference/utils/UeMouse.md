---
sidebar_position: 1
---

# UeMouse

A global (`UE_MOUSE`) utility class for retrieving mouse coordinates in game-space and Normalized Device Coordinates (NDC).
Mostly used internally for raycasting and camera transforming.

---

### Constructor

```js
new UeMouse()
```

## Properties

| Properties     | Default | Description |
|----------------|---------|-------------|
| `view`         | `0`     | The viewport index from which to retrieve mouse coordinates. |

## Methods

| Method         | Description |
|----------------|-------------|
| `get()`        | Returns an object with mouse coordinates adjusted to the viewport. Also includes normalized device coordinates (NDC). |
| `worldToScreen(worldPos, camera)` | Projects a 3D world-space position to 2D screen coordinates. |
| `screenToWorld(screenX, screenY, camera, depth)` | Unprojects screen coordinates into a 3D world-space position. |

### `get()`
Returns an object containing:
- `x`, `y`: Screen coordinates adjusted to the viewport.
- `ndcX`, `ndcY`: Normalized Device Coordinates in range `[-1, 1]`.

### `worldToScreen(worldPos, camera)`
Projects a 3D world-space position to 2D screen coordinates.
- `worldPos`: The 3D position in world space.
- `camera`: The camera object used for projection.

**Returns:** A struct `{x, y}` with screen coordinates, or `undefined` if the point is outside the viewing frustum.

### `screenToWorld(screenX, screenY, camera, depth = 0)`
Unprojects screen coordinates into a 3D world-space position.
- `screenX`, `screenY`: The screen coordinates.
- `camera`: The camera object used for unprojection.
- `depth`: The depth (usually `-1` to `1` or `0` to `1` depending on the platform) to unproject at. Default is `0`.

**Returns:** A new 3D vector in world space.
