---
sidebar_position: 4
---

A line segments mesh class that renders individual line segments between pairs of vertices using provided geometry and material.
Useful for drawing disconnected line segments or wireframes made of multiple independent lines.

### Constructor
```js
new UeLineSegments(geometry = undefined, material = undefined, data = {})
```

> Inherits from [UeLine](/docs/reference/objects/UeLine)

### Parameters

| Name     | Type                  | Default     | Description                               |
| -------- | --------------------- | ----------- | ----------------------------------------- |
| geometry | `UeGeometry`    | `undefined` | Geometry defining line segment vertices   |
| material | `UeLineBasicMaterial` | `undefined` | Material used to render the line segments |
| data     | `Object`              | `{}`        | Additional data passed to base class      |

### Properties

| Property         | Type      | Description                                                   |
| ---------------- | --------- | ------------------------------------------------------------- |
| `isLineSegments` | `boolean` | Flag identifying this as line segments primitive              |
| `primitive`      | `string`  | Primitive type `"pr_linelist"` for disconnected line segments |
