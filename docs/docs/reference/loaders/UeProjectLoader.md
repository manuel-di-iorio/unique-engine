---
sidebar_position: 5
---

# UeProjectLoader

`UeProjectLoader` is a runtime project loader for loading and managing game assets from the exported project structure. It reads assets from the `datafiles/Unique Project/` directory and provides on-demand asset loading capabilities.

The loader uses a two-pass loading system to ensure all asset dependencies are properly resolved:
- **Pass 1**: Loads asset metadata and binary resources (textures, geometry)
- **Pass 2**: Links asset references (materials→textures, meshes→materials)

---

## Constructor

```js
new UeProjectLoader(data = {})
```

### Parameters

| Parameter       | Type           | Default           | Description                                           |
| --------------- | -------------- | ----------------- | ----------------------------------------------------- |
| `data`          | `struct`       | `{}`              | Configuration options                                 |
| `data.renderer` | `UeRenderer`   | `new UeRenderer()`| The renderer instance to use                          |
| `data.autoLoad` | `boolean`      | `true`            | If true, automatically loads all assets on construction |

---

## Properties

| Property        | Type         | Default                 | Description                                              |
| --------------- | ------------ | ----------------------- | -------------------------------------------------------- |
| `renderer`      | `UeRenderer` | `new UeRenderer()`      | The renderer instance used for rendering                 |
| `scene`         | `UeScene`    | `new UeScene()`         | The active scene populated by `setScene()`               |
| `autoLoad`      | `boolean`    | `true`                  | Whether to automatically load all assets on construction |
| `assetsByUuid`  | `struct`     | `{}`                    | Map of all loaded assets indexed by UUID                 |
| `assetsByName`  | `struct`     | `{}`                    | Map of all loaded assets indexed by name                 |

---

## Methods

### `load()`

```js
load()
```

Loads the project's `assets.json` and optionally loads all assets. This function must be called before using `loadAssets()` or `setScene()`.

If `autoLoad` is `true`, this method is automatically called in the constructor.

**Returns:** Nothing

**Example:**
```js
// Manual loading (autoLoad disabled)
const loader = new UeProjectLoader({ autoLoad: false });
loader.load(); // Load only assets.json
```

---

### `loadAssets(...assetNames)`

```js
loadAssets(...assetNames)
```

Loads specific assets by name. If no arguments are provided, loads all assets.

**Parameters:**
- `assetNames` (string|array) - Asset name(s) to load. Can be passed as individual arguments or as an array.

**Returns:** Nothing

**Examples:**
```js
// Load all assets
loader.loadAssets();

// Load single asset by name
loader.loadAssets("MyTexture");

// Load multiple assets by name
loader.loadAssets("Texture1", "Material1", "Mesh1");

// Load from array
loader.loadAssets(["Texture1", "Material1"]);
```

---

### `loadAssetsByUuid(...assetUUIDs)`

```js
loadAssetsByUuid(...assetUUIDs)
```

Loads specific assets by UUID. If no arguments are provided, loads all assets.

**Parameters:**
- `assetUUIDs` (string|array) - Asset UUID(s) to load. Can be passed as individual arguments or as an array.

**Returns:** Nothing

**Examples:**
```js
// Load all assets
loader.loadAssetsByUuid();

// Load single asset by UUID
loader.loadAssetsByUuid("abc-123-def");

// Load multiple assets by UUID
loader.loadAssetsByUuid("uuid-1", "uuid-2", "uuid-3");

// Load from array
loader.loadAssetsByUuid(["uuid-1", "uuid-2"]);
```

---

### `getAsset(name)`

```js
getAsset(name)
```

Retrieves a loaded asset by its name.

**Parameters:**
- `name` (string) - The name of the asset to retrieve

**Returns:** `struct|undefined` - The asset struct, or `undefined` if not found

**Example:**
```js
const myTexture = loader.getAsset("MyTexture");
if (myTexture != undefined) {
    // Use texture
    material.textures.map = myTexture;
}
```

---

### `setScene(sceneName)`

```js
setScene(sceneName)
```

Populates the loader's scene with model instances from a scene asset. Clears any existing scene content before populating.

The scene is automatically instantiated with all ModelInstances and their transforms (position, rotation, scale).

**Parameters:**
- `sceneName` (string) - Name of the scene to load

**Returns:** Nothing

**Example:**
```js
// Load scene by name
loader.setScene("MainScene");

// Render the populated scene
loader.render(camera);
```

---

### `render(camera)`

```js
render(camera)
```

Renders the current scene using the loader's renderer.

**Parameters:**
- `camera` (UeCamera) - The camera to render from

**Returns:** `self` (for method chaining)

**Example:**
```js
loader.render(camera);
```

---

## Supported Asset Types

The loader supports the following asset types:

| Asset Type  | File Structure                                    | Description                           |
| ----------- | ------------------------------------------------- | ------------------------------------- |
| **Texture** | `assets/{uuid}/texture.png` + `metadata.json`     | Texture images                        |
| **Material**| `assets/{uuid}/metadata.json`                     | Material definitions                  |
| **Mesh**    | `assets/{uuid}/geometry.buf` + `metadata.json`    | 3D models with geometry               |
| **Scene**   | `assets/{uuid}/metadata.json`                     | Scene hierarchies with model instances|

---

## Project Structure

The loader expects assets to be organized in the following structure:

```
datafiles/Unique Project/
├── assets.json                  # Asset index
└── assets/
    ├── {uuid-1}/
    │   ├── metadata.json        # Asset metadata
    │   ├── texture.png          # (for textures)
    │   └── geometry.buf         # (for meshes)
    ├── {uuid-2}/
    │   └── metadata.json
    └── ...
```

---

## Usage Examples

### Basic Usage

```js
// Create loader with automatic asset loading
const loader = new UeProjectLoader();

// Access loaded assets
const myMaterial = loader.getAsset("MyMaterial");
const myTexture = loader.getAsset("MyTexture");

// Load and render a scene
loader.setScene("MainScene");
loader.render(camera);
```

### Manual Loading

```js
// Create loader without auto-loading
const loader = new UeProjectLoader({ autoLoad: false });

// Load specific assets only
loader.load(); // Load assets.json
loader.loadAssets("Texture1", "Material1", "Mesh1");

// Get assets
const mesh = loader.getAsset("Mesh1");
scene.add(mesh);
```

### Custom Renderer

```js
// Use a custom renderer
const myRenderer = new UeRenderer({
    shadowMap: {
        enabled: true,
        autoUpdate: true
    }
});

const loader = new UeProjectLoader({ 
    renderer: myRenderer 
});

loader.setScene("MainScene");
loader.render(camera);
```

### On-Demand Loading

```js
// Start with minimal loading
const loader = new UeProjectLoader({ autoLoad: false });
loader.load(); // Only load assets.json

// Load assets as needed
function loadLevel(levelName) {
    loader.loadAssets("Level" + levelName + "Texture");
    loader.loadAssets("Level" + levelName + "Material");
    loader.setScene("Level" + levelName);
}

loadLevel(1);
```

---

## Notes

- If only one scene exists in the project and `autoLoad` is `true`, that scene is automatically loaded
- Assets are cached by both UUID and name for efficient lookup
- Model instances created by `setScene()` include position, rotation, and scale transforms from the scene data
- Assets marked as `isLoaded = true` are skipped on subsequent load attempts
- **Format Compatibility**: When loading geometry, the loader uses the `UeVertexFormat` defined in the asset's metadata. This ensures that projects exported with different engine versions (e.g., with or without tangents) are loaded correctly.
