---
sidebar_position: 3
---

A texture wrapper class for GameMaker that supports UV transformations, wrapping modes, tiling, flipping, rotation, filtering, and mipmap generation. Transforms are baked into a surface and converted into a GPU-ready sprite.

### Constructor
```js
new UeTexture(data = {})
```

### Data parameters

| Key               | Type      | Default      | Description                                    |
| ----------------- | --------- | ------------ | ---------------------------------------------- |
| `image`           | `sprite`  | **required** | A sprite resource or image                     |
| `repeat`          | `boolean` | `true`       | Whether the texture repeats                    |
| `filter`          | `boolean` | `true`       | Enables texture smoothing                      |
| `generateMipmaps` | `boolean` | `true`       | Whether to enable mipmaps for minification     |

### Properties

| Name               | Type        | Description                                                         |
| ------------------ | ----------- | ------------------------------------------------------------------- |
| `isTexture`        | `true`      | Identifies this as a texture.                                       |
| `type`             | `"Texture"` | Constant string.                                                    |
| `uuid`             | `string`    | Unique texture ID.                                                  |
| `name`             | `string`    | Optional name.                                                      |
| `image`            | `sprite`    | Base image sprite.                                                  |
| `offset`           | `UeVector2` | UV offset.                                                          |
| `repeat`           | `UeVector2` | UV repeat count.                                                    |
| `center`           | `UeVector2` | Pivot point for transforms.                                         |
| `rotation`         | `float`     | Rotation in radians (Z-axis).                                       |
| `flipX`            | `bool`      | Flips horizontally.                                                 |
| `flipY`            | `bool`      | Flips vertically.                                                   |
| `wrapS`            | `enum`      | Horizontal wrapping (`REPEAT`, `CLAMP_TO_EDGE`, `MIRRORED_REPEAT`). |
| `wrapT`            | `enum`      | Vertical wrapping.                                                  |
| `filter`           | `bool`      | Texture filtering mode.                                             |
| `generateMipmaps`  | `bool`      | Enables mipmap generation.                                          |
| `matrix`           | `UeMatrix4` | UV transformation matrix.                                           |
| `matrixAutoUpdate` | `bool`      | Auto-updates matrix when needed.                                    |
| `needsUpdate`      | `bool`      | Marks texture as needing rebake.                                    |



## 🧩 Methods

| Method            | Description |
|-------------------|-------------|
| `updateMatrix()`  | Rebuilds the internal UV transformation matrix using `offset`, `repeat`, `center`, `rotation`, `flipX`, and `flipY`. |
| `dispose()`       | Frees any GPU resources (like the cached sprite and texture). Should be called before replacing or destroying the texture. |
| `toJSON()`        | Returns a plain JSON-like struct containing all the serializable parameters (wrap, repeat, filter, etc.). |
| `contain(aspect)`  | Scales the texture to fit entirely within the surface without cropping or stretching. Preserves the original aspect ratio. Similar to CSS 
`object-fit: contain`. |
| `cover(aspect)`    | Scales the texture to completely cover the surface, potentially cropping parts of it. Preserves the original aspect ratio. Similar to CSS `object-fit: cover`. |
| `fill()`           | Resets the texture transform to fill the surface entirely, ignoring aspect ratio. Similar to CSS `object-fit: fill`. |

## Notes

You don't need to call `updateMatrix()` manually unless `matrixAutoUpdate` is false. Just set `needsUpdate = true` to tells the engine to rebake the texture.
