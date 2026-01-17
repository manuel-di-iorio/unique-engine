---
sidebar_position: 2
---

# UeSkeleton

:::warning
Animations module is under costruction and do not works yet.
:::

Manager for a bone hierarchy for skinning.

## Constructor
```js
new UeSkeleton(bones = [])
```

### Parameters
- `bones`: Array of `UeBone` instances.

## Properties
- `bones`: Array of all bones in the skeleton.
- `boneMatrices`: Flattened array (16 floats per bone) of the final matrices to be sent to the shader.
- `rootBone`: The first bone in the array, considered the root.

## Methods
### `update()`
Recalculates all skinning matrices (`WorldMatrix * OffsetMatrix`) and stores them in `boneMatrices`. This must be called before rendering if the bones have moved.
