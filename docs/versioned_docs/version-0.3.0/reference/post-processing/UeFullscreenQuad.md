# UeFullscreenQuad

`UeFullscreenQuad` is a utility class used extensively in post-processing to render a quad that covers the entire screen (or render target).

It uses **Normalized Device Coordinates (NDC)** to ensure the quad fills the viewport regardless of camera settings, by using identity matrices during rendering.

## Constructor

```js
new UeFullscreenQuad(material)
```

- **material**: `UeMaterial` - The material to render on the quad.

## Methods

### render

```js
function render(texture, skipMaterial?)
```

Renders the quad.

- **texture**: `texture` - THe input texture to use as `gm_BaseTexture` in the shader.
- **skipMaterial** (optional): boolean - If true, `material.use()` is NOT called. Useful if you need to manually apply the material and set custom texture stages before rendering.

## How it works

The quad geometry is defined from `(-1, -1)` to `(1, 1)`. 
When rendered with `matrix_projection`, `matrix_view`, and `matrix_world` all set to **Identity**, these coordinates map directly to the screen clip space, effectively covering the entire render area.
