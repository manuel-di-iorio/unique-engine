---
sidebar_position: 4
---

A `UeSprite` is a lightweight 2D object rendered as a billboard that always faces the camera.  
Useful for UI-like elements, particles, and icon markers in 3D space.

Inherits from `UeMesh` and uses a flat plane geometry (`PlaneGeometry`) and typically a `UeSpriteMaterial`.

---

### Constructor

```js
new UeSprite(material = new UeSpriteMaterial(), data = {})
```

> Inherits from [UeMesh](/docs/reference/objects/UeMesh)

### Data parameters

| Name       | Type               | Default                  | Description                            |
| ---------- | ------------------ | ------------------------ | -------------------------------------- |
| `material` | `UeSpriteMaterial` | `new UeSpriteMaterial()` | Material used for rendering the sprite |
| `data`     | `object`           | `{}`                     | Inherited properties from `UeMesh`     |

### Properties

| Property   | Type               | Default                  | Description                            |
| ---------- | ------------------ | ------------------------ | -------------------------------------- |
| `isSprite` | `boolean`          | `true`                   | Identifies this object as a sprite     |
| `type`     | `string`           | `Sprite`                 | Object type                            |
| `name`     | `string`           | undefined                | Object name (optional)                 |
| `geometry` | `PlaneGeometry`    | `PlaneGeometry(1, 1)`    | A flat quad geometry                   |
| `material` | `UeSpriteMaterial` | `new UeSpriteMaterial()` | Material used for rendering the sprite |


### Geometry

The geometry is always a `PlaneGeometry(1, 1)` centered on the origin.

This can be scaled via .scale or transformed like any UeObject3D.

## 📝 Notes
Sprites are ideal for simple transparent objects.

Custom shaders can be assigned to UeSpriteMaterial to extend behavior.

Can be used in particle systems or UI overlays.

## Example

```js
const sprite = new UeSprite();
sprite.setPosition(0, 0, 10);
scene.add(sprite);
```
