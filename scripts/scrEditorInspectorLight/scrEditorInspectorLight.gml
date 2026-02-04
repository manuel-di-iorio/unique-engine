function scrEditorInspectorLight() {
    return [
        // === SECTION: GENERAL ===
        {
            id: "name",
            field: "name",
            label: "Name",
            type: "text"
        },
        {
            id: "enabled",
            field: "enabled",
            label: "Enabled",
            type: "checkbox",
            tooltip: "Enable or disable the light",
        },

        // === TRANSFORM ===
        {
            id: "sec_transform",
            label: "Transform",
            type: "section",
            children: [
                {
                    id: "position",
                    field: "position",
                    label: "Position",
                    type: "transformXYZ",
                    valueGetter: function () {
                        return self.asset.position;
                    },
                    onBlur: function (value, input) {
                        vec3_copy(self.asset.position, value);
                    }
                },
                {
                    id: "rotation",
                    field: "rotation",
                    label: "Rotation",
                    type: "transformXYZ",
                    valueGetter: function () {
                        if (self.asset[$ "__rotationEuler"] == undefined) {
                            self.asset.__rotationEuler = euler_create();
                            euler_set_from_quaternion(self.asset.__rotationEuler, self.asset.rotation);
                        }
                        return self.asset.__rotationEuler;
                    },
                    onBlur: function (value, input) {
                        // value is [x, y, z] from the textboxes
                        self.asset.__rotationEuler[0] = value[0];
                        self.asset.__rotationEuler[1] = value[1];
                        self.asset.__rotationEuler[2] = value[2];

                        // Update quaternion from euler
                        quat_set_from_euler(self.asset.rotation, self.asset.__rotationEuler[0], self.asset.__rotationEuler[1], self.asset.__rotationEuler[2]);
                        self.asset.updateWorldMatrix(true, false);
                        global.UI.requestRedraw();
                    }
                },
            ]
        },

        // === LIGHT PROPERTIES ===
        {
            id: "sec_properties",
            label: "Light Properties",
            type: "section",
            children: [
                {
                    id: "intensity",
                    field: "intensity",
                    label: "Intensity",
                    type: "text",
                    format: "float",
                    min: 0,
                    tooltip: "Brightness of the light source",
                    onBlur: function () {
                        global.UI.requestRedraw();
                    }
                },
                {
                    id: "colorR",
                    label: "Color R",
                    type: "text",
                    format: "float",
                    min: 0,
                    max: 1,
                    valueGetter: function () { return self.asset.color[0]; },
                    onBlur: function (value) {
                        self.asset.color[0] = value;
                    }
                },
                {
                    id: "colorG",
                    label: "Color G",
                    type: "text",
                    format: "float",
                    min: 0,
                    max: 1,
                    valueGetter: function () { return self.asset.color[1]; },
                    onBlur: function (value) {
                        self.asset.color[1] = value;
                    }
                },
                {
                    id: "colorB",
                    label: "Color B",
                    type: "text",
                    format: "float",
                    min: 0,
                    max: 1,
                    valueGetter: function () { return self.asset.color[2]; },
                    onBlur: function (value) {
                        self.asset.color[2] = value;
                    }
                },
                {
                    id: "range",
                    field: "range",
                    label: "Range",
                    type: "text",
                    format: "float",
                    min: 0,
                    tooltip: "Distance the light reaches (Point lights only)",
                    // visibleGetter: function () {
                    //     return self.asset.lightType == "PointLight";
                    // }
                },
                {
                    id: "castShadow",
                    field: "castShadow",
                    label: "Cast Shadows",
                    type: "checkbox",
                    tooltip: "Whether this light casts shadows",
                }
            ]
        }
    ];
}
