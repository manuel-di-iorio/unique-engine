---
sidebar_position: 1
---

A global (UE_MOUSE) utility class for retrieving mouse coordinates in game-space and Normalized Device Coordinates (NDC).
Mostly used internally for raycasting and camera trasforming.

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
