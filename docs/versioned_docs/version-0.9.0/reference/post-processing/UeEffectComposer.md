# UeEffectComposer

`UeEffectComposer` is the core manager for post-processing effects in the Unique Engine. It handles a chain of render passes, swapping buffers between them to create complex visual effects.

## Constructor

```js
new UeEffectComposer(renderer, renderTarget?, data?)
```

- **renderer**: `UeRenderer` - The main renderer instance.
- **renderTarget** (optional): `UeRenderTarget` - An optional target to render to. If undefined, it creates one internally matching the renderer size.
- **data** (optional): Struct with configuration.
    - `renderToScreen`: boolean (default: true) - Whether the final pass should render to the screen.

## Properties

- **renderer**: `UeRenderer` - The renderer.
- **readTarget**: `UeRenderTarget` - The surface being read from (input for the current pass).
- **writeTarget**: `UeRenderTarget` - The surface being written to (output for the current pass).
- **passes**: `Array<UePass>` - List of added passes.

## Methods

### addPass

```js
function addPass(pass)
```

Adds a `UePass` to the post-processing chain.

- **pass**: The pass object (e.g., `UeRenderPass`, `UeOutlinePass`).

### render

```js
function render()
```

Executes all enabled passes in order. Can be called instead of `renderer.render()`.
It automatically handles ping-pong buffering (swapping read/write targets) so that the output of one pass becomes the input of the next.

### setSize

```js
function setSize(width, height)
```

Resizes the internal render targets and all attached passes.
