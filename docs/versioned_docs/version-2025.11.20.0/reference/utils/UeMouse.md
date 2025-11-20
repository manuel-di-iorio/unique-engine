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
| `view`         | `0`     | Returns an object with mouse coordinates adjusted to the viewport. Also includes normalized device coordinates (NDC). |

## Methods

| Method         | Description |
|----------------|-------------|
| `get()`        | Returns an object with mouse coordinates adjusted to the viewport. Also includes normalized device coordinates (NDC). |
