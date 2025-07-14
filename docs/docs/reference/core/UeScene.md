---
sidebar_position: 5
---

The `UeScene` class represents the root node of a 3D scene in Unique Engine. It inherits from `UeObject3D` and adds logic for managing lights and renderable objects.

### Constructor
```js
new UeScene(data = {})
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

### Properties

| Property   | Type      | Default     | Description                    |
| ---------- | -------   | ----------  | -----------------------------  |
| `isScene`  | `boolean` | true        | Indicates that this is a scene |
| `lights`   | `array`   | Array of all light objects in the scene      |

## 🧠 Notes

- You can build your scene tree using .add() to nest meshes, lights, or other objects.

## Example

```js
const scene = new UeScene();
const light = new UeDirectionalLight({ color: c_white });
const material = new UeMeshStandardMaterial();
const mesh = new UeMesh(new UeBoxGeometry(), material);

scene.add(light, mesh);
```
