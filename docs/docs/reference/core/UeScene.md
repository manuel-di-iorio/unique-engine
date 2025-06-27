---
sidebar_position: 5
---

The `UeScene` class represents the root node of a 3D scene in Unique Engine. It inherits from `UeObject3D` and adds logic for managing lights and renderable objects.

### Constructor
```js
new UeScene(data = {})
```

### Properties

| Property   | Type      | Default     | Description                    |
| ---------- | -------   | ----------  | -----------------------------  |
| `isScene`  | `boolean` | true        | Indicates that this is a scene |
| `lights`   | `array`   | Array of all light objects in the scene      |

<!-- ## Methods

```js
dispose()
```
Removes all the scene lights -->

## 🧠 Notes

- You can build your scene tree using .add() to nest meshes, lights, or other objects.
- Lights added to the scene are automatically collected in the .lights array for easy access by the renderer.

## Example

```js
const scene = new UeScene();
const light = new UeDirectionalLight({ color: c_white });
const mesh = new UeMesh(new UeBoxGeometry(), { material: myMat });

scene.add(light, mesh);
```
