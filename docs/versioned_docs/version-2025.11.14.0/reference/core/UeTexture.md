---
sidebar_position: 3
---

A texture wrapper class for GameMaker that supports UV transformations, wrapping modes, tiling, flipping, rotation, filtering, and mipmap generation. Transforms are baked into a surface and converted into a GPU-ready sprite.

### Constructor
```js
new UeTexture(sprite = undefined, data = {})
```

### Data parameters

| Key               | Type      | Default      | Description                                    |
| ----------------- | --------- | ------------ | ---------------------------------------------- |
| `repeat`          | `boolean` | `true`       | Whether the texture repeats                    |
| `filter`          | `boolean` | `true`       | Enables texture smoothing                      |
| `generateMipmaps` | `boolean` | `true`       | Whether to enable mipmaps for minification     |

### Properties

| Name               | Type           | Description                                                         |
| ------------------ | -----------    | ------------------------------------------------------------------- |
| `id`               | `real`         | Incremental object ID (auto-generated)                              | 
| `sprite`           | `sprite`       | A sprite resource                                                   | 
| `isTexture`        | `true`         | Identifies this as a texture.                                       |
| `type`             | `"Texture"`    | Constant string.                                                    |
| `uuid`             | `string`       | Unique texture ID.                                                  |
| `name`             | `string`       | Optional name.                                                      |
| `image`            | `sprite`       | Base image sprite.                                                  |
| `offset`           | `UeVector2`    | UV offset.                                                          |
| `repeat`           | `UeVector2`    | UV repeat count.                                                    |
| `center`           | `UeVector2`    | Pivot point for transforms.                                         |
| `rotation`         | `real`         | Rotation in degrees (Z-axis).                                       |
| `flipX`            | `boolean`      | Flips horizontally.                                                 |
| `flipY`            | `boolean`      | Flips vertically.                                                   |
| `wrapS`            | `boolean`      | Horizontal wrapping (`UE_TEXTURE_WRAP.REPEAT`, `UE_TEXTURE_WRAP.CLAMP_TO_EDGE`, `UE_TEXTURE_WRAP.MIRRORED_REPEAT`). |
| `wrapT`            | `boolean`      | Vertical wrapping                                                   |
| `filter`           | `boolean`      | Texture filtering mode.                                             |
| `generateMipmaps`  | `boolean`      | Enables mipmap generation.                                          |
| `matrix`           | `UeMatrix4`    | UV transformation matrix.                                           |
| `matrixAutoUpdate` | `boolean`      | Auto-updates matrix when needed.                                    |
| `needsUpdate`      | `boolean`      | Marks texture as needing rebake.                                    |
| `userData`         | `struct`       | Custom user data                                                    |



## 🧩 Methods

| Method            | Description |
|-------------------|-------------|
| `updateMatrix()`  | Rebuilds the internal UV transformation matrix using `offset`, `repeat`, `center`, `rotation`, `flipX`, and `flipY`. |
| `update()`        | Rebake the texture sprite based on the matrix and texture props. This is done automatically when `matrixAutoUpdate` is thruthy |
| `dispose()`       | Frees any GPU resources (like the cached sprite and texture). Should be called before replacing or destroying the texture. |
| `toJSON()`        | Returns a plain JSON-like struct containing all the serializable parameters (wrap, repeat, filter, etc.). |
| `contain(aspect)`  | Scales the texture to fit entirely within the surface without cropping or stretching. Preserves the original aspect ratio. Similar to CSS 
`object-fit: contain`. |
| `cover(aspect)`    | Scales the texture to completely cover the surface, potentially cropping parts of it. Preserves the original aspect ratio. Similar to CSS `object-fit: cover`. |
| `fill()`           | Resets the texture transform to fill the surface entirely, ignoring aspect ratio. Similar to CSS `object-fit: fill`. |

## Notes

You don't need to call `updateMatrix()` manually unless `matrixAutoUpdate` is set to false. Just set `needsUpdate = true` to tells the engine to rebake the texture.
