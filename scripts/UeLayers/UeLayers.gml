function UeLayers() constructor {
    mask = 1 << 0; // Bitmask storing active layers, default to layer 0

    /// Remove membership of the specified layer (0-31)
    function disable(layer) {
        mask &= ~(1 << layer);
        return self;
    }

    /// Add membership to the specified layer (0-31)
    function enable(layer) {
        mask |= 1 << layer;
        return self;
    }

    /// Set membership to exactly one layer, removing all others
    function set(layer) {
        mask = 1 << layer;
        return self;
    }

    /// Test if this and another Layers object share at least one layer
    /// @param layers Another Layers object
    /// @return true if at least one layer is shared
    function test(layers) {
        return (mask & layers.mask) != 0;
    }

    /// Check if a specific layer is enabled
    /// @param layer Layer index (0-31)
    /// @return true if the layer is enabled
    function isEnabled(layer) {
        return (mask & (1 << layer)) != 0;
    }

    /// Toggle membership of the specified layer (0-31)
    function toggle(layer) {
        mask ^= 1 << layer;
        return self;
    }

    /// Enable all 32 layers (set all bits to 1)
    function enableAll() {
        mask = 0xFFFFFFFF;
        return self;
    }

    /// Disable all layers (clear all bits)
    function disableAll() {
        mask = 0;
        return self;
    }
}
