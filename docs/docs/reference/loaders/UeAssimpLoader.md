---
sidebar_position: 1
---



Import a 3D model and its materials by using an integrated Assimp extension, which supports a variety of 3D formats (obj,3ds,etc..).

> STATUS: **BETA** - Many things may not work correctly, eg. you may need to manually add the textures to the mesh's materials. Animations are not supported yet from the engine.

---

## Constructor

```js
new UeAssimpLoader(data = undefined)
```

## Methods

| Method           | Returns     | Description                                                         |
| ---------------- | ----------- | ------------------------------------------------------------------- |
| `load(filename)` | `struct`    | Returns a struct `{ textures, materials, model }` containing the loaded assets. |
| `dispose()`      | `self`      | Clean the internal importer resource                                |
