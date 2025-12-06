---
sidebar_position: 4
---

Visual representation of a two-dimensional grid, useful for positioning and spatial orientation.

## Constructor

```js
new UeGridHelper(size = 10, divisions = 10, colorCenterLine = #444444, colorGrid = #888888)
```

> Inherits from [UeLineSegments](/docs/reference/objects/UeLineSegments)

## Methods

| Method                               | Returns | Description                                              |
| ------------------------------------ | ------- | -------------------------------------------------------- |
| `.setColors(xColor, yColor, zColor)` | `self`  | Changes axis colors.                                     |
| `.dispose()`                         | `self`  | Frees GPU resources used by the helper.                  |
