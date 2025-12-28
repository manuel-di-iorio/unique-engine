---
sidebar_position: 1
---

Base class extended from other _Controls_ classes

### Properties

| Property            | Type        | Description                       |
| ------------------- | ----------- | --------------------------------- |
| `enabled`           | `boolean`   | Whether the controls are enabled  |
| `shouldHandleInput` | `function`  | Callback function to determine if input should be handled. Defaults to returning `true`. |
| `object`            | `UeObject3D`| The object being controlled (optional). |
