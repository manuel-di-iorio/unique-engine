function EditorUiInspector(ui) constructor {
    self.ui = ui;
    self.asset = undefined;
    self.multiSelectCount = 0;

    ui.Inspector = new UiNode({ name: "Inspector", minWidth: 350, width: "21%", marginBottom: 62, flexDirection: "column" }, { border: true });
    ui.Inspector.owner = self;

    with (ui.Inspector) {
        function onDraw() {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
            
            var title = "Inspector";
            if (self.owner[$ "multiSelectCount"] != undefined && self.owner.multiSelectCount > 1) {
                title = string(self.owner.multiSelectCount) + " Objects Selected";
            } else if (self.owner[$ "asset"] != undefined) {
                title = self.owner.asset.type + " Inspector";
            }
            draw_text(self.x1 + 20, self.y1 + 8, title);
        }
    };

    // Inspector close button
    ui.Inspector.Close = new UiButton(sprUiClose, { display: "none", position: "absolute", top: 5, right: 5, width: 28, height: 28 }, { outline: true, tooltip: "Close inspector" });

    with (ui.Inspector.Close) {
        self.onClick(function() {
            global.editor.editorManager.clearActiveAsset();
            self.hide();
        });
    }

    ui.Inspector.add(ui.Inspector.Close);
    
    // Content
    ui.Inspector.Content = new UiNode({ 
        marginTop: 38, name: "Inspector.Content", height: "90%", 
        flex: 1, flexDirection: "column"
    }, { pointerEvents: true });
    ui.Inspector.add(ui.Inspector.Content);

    with (ui.Inspector.Content) {
        self.enableScrollbar();

        self.onDraw = function() {
            draw_set_color(global.UI_COL_INSPECTOR_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        };
    }
    
    ui.Inspector.Content.Items = new UiNode({ name: "Inspector.Content.Items", padding: 10, paddingRight: 25, paddingBottom: 30 });
    ui.Inspector.Content.add(ui.Inspector.Content.Items);
    
    // Assets fields configuration
    fields = {
        "Texture": scrEditorInspectorTexture(),
        "Material": scrEditorInspectorMaterial(),
        "Mesh": scrEditorInspectorMesh(),
        "Object3D": scrEditorInspectorObject3D(),
        "Bone": scrEditorInspectorObject3D(),
        // "Light": scrEditorInspectorLight(),
        "Scene": scrEditorInspectorScene(), 
        "Folder": scrEditorInspectorFolder(),
    }
    
    /**
     * Dynamically create the inspector fields
     */
    function inspect(asset, focusFirst = false) {
        self.ui.Inspector.Close.show();

        // Clear the previous content
        var _Items = self.ui.Inspector.Content.Items;
        self.close();

        self.asset = asset;
        self.focusFirst = focusFirst;
        var assetType = asset.type;
        var assetFields = fields[$ assetType];
        
        // Check if this is an instance (has a prefab link)
        var _isInstance = (asset[$ "prefab"] != undefined && asset.prefab != undefined);
        
        // If this is an instance, show Prefab header with action icons
        if (_isInstance) {
            var _prefabName = asset.prefab[$ "name"] ?? "Unknown";
            
            var _prefabRow = new UiNode({ 
                width: "100%", height: 24, marginBottom: 12,
                flexDirection: "row", alignItems: "center", justifyContent: "flex-end"
            });

            with (_prefabRow) {
                prefabLabel = "Prefab: " + _prefabName;
                function onDraw() {
                    if (self[$ "x1"] == undefined) return;
                    draw_set_font(fText);
                    draw_set_color(c_white);
                    draw_set_halign(fa_left);
                    draw_set_valign(fa_top);
                    draw_text(self.x1, self.y1 + 2, self.prefabLabel);
                };
            }

            // Icon: Inspect Prefab source
            var _inspectPrefabBtn = new UiButton(sprUiObject, { 
                width: 22, height: 22, marginLeft: 6 
            }, { tooltip: "Inspect prefab source", outline: true });
            _inspectPrefabBtn.onClick(method({ prefab: asset.prefab }, function() {
                global.editor.editorManager.inspector.inspect(prefab);
            }));
            
            // Icon: Apply All overrides
            var _applyAllBtn = new UiButton(sprUiDropdownArrow, { 
                width: 22, height: 22, marginLeft: 4 
            }, { tooltip: "Apply all overrides to prefab", outline: true });
            _applyAllBtn.onClick(method({ asset }, function() {
                if (asset[$ "applyAllOverrides"] != undefined && show_question("Are you sure you want to apply all overrides to prefab?")) {
                    asset.applyAllOverrides();
                    // Re-inspect to refresh override visuals
                    global.editor.editorManager.inspector.inspect(asset);
                }
            }));
            
            // Icon: Revert All overrides
            var _revertAllBtn = new UiButton(sprUiUndo, { 
                width: 22, height: 22, marginLeft: 4 
            }, { tooltip: "Revert all overrides to prefab values", outline: true });
            _revertAllBtn.onClick(method({ asset }, function() {
                if (asset[$ "revertAllOverrides"] != undefined && show_question("Are you sure you want to revert all overrides to prefab values?")) {
                    asset.revertAllOverrides();
                    global.editor.assetManager.editAsset(asset);
                    // Re-inspect to refresh override visuals
                    global.editor.editorManager.inspector.inspect(asset);
                }
            }));

            _prefabRow.add(_inspectPrefabBtn, _applyAllBtn, _revertAllBtn);
            _Items.add(_prefabRow);
        }
        
        // First pass: calculate the max label width among all items (recursive)
        draw_set_font(fText);
        var _labelWidth = __getMaxLabelWidth(assetFields);
        
        // Second pass: add the labels and inputs recursively
        var _context = { focused: false };
        
        __renderFields(self.ui.Inspector.Content.Items, assetFields, _context, _labelWidth); 
    } 
    
    function close() {
        self.ui.Inspector.Content.Items.destroyChildren();
        self.asset = undefined;  // Reset asset to show default "Inspector" title
        self.multiSelectCount = 0;
    }
    
    /// Show a multi-selection summary in the inspector
    /// @param {Array<Struct>} assets All selected assets
    /// @param {Struct} primaryAsset The primary selected asset
    function inspectMultiple(assets, primaryAsset) {
        self.ui.Inspector.Close.show();
        
        // Clear previous content
        var _Items = self.ui.Inspector.Content.Items;
        close();
        
        self.asset = primaryAsset;
        self.multiSelectCount = array_length(assets);
        
        // --- Summary header ---
        var _header = new UiText(string(self.multiSelectCount) + " objects selected", { 
            width: "100%", height: 30, marginTop: 10
        }, { 
            pointerEvents: false 
        });
        _Items.add(_header);
        
        // --- List selected object names ---
        for (var i = 0; i < array_length(assets); i++) {
            var _a = assets[i];
            var _name = _a[$ "name"] ?? ("Object " + string(i));
            var _type = _a[$ "type"] ?? "Unknown";
            var _isPrimary = (_a == primaryAsset);
            
            var _row = new UiNode({ 
                width: "100%", height: 22, marginTop: 4,
                flexDirection: "row", alignItems: "center", paddingLeft: 5
            });
            
            // Primary indicator (small marker)
            var _label = "  " + _name;
            
            var _nameText = new UiText(_label, { flex: 1, height: 20 }, { 
                pointerEvents: false 
            });
            _row.add(_nameText);
            
            var _typeText = new UiText(_type, { width: 80, height: 20 }, { 
                pointerEvents: false 
            });
            _row.add(_typeText);
            
            _Items.add(_row);
        }
    }

    function __getMaxLabelWidth(list) {
        var _max = 0;
        for (var i = 0; i < array_length(list); i++) {
            var field = list[i];
            if (field[$ "label"] != undefined) _max = max(_max, string_width(field.label));
            if (field[$ "children"] != undefined) _max = max(_max, __getMaxLabelWidth(field.children));
        }
        return _max;
    }

    function __renderFields(container, fieldsList, context, labelWidth) {
        for (var i = 0, l = array_length(fieldsList); i < l; i++) {
            var assetField = fieldsList[i];
            
            // Handle visibility
            var _asset = self.asset;
            var isVisible = assetField[$ "visible"];
            if (isVisible != undefined) {
                if (is_method(isVisible) || is_callable(isVisible)) {
                    if (!method({ asset: _asset, assetField }, isVisible)()) continue;
                } else if (!isVisible) {
                    continue;
                }
            }

            // Handle Sections with children
            if (assetField.type == "section" && assetField[$ "children"] != undefined) {
              var isCollapsed = assetField[$ "collapsed"] ?? false;
              
              var _accordion = new UiAccordion(assetField.label, { marginTop: 20 }, { collapsed: isCollapsed });
              container.add(_accordion);
              
              __renderFields(_accordion, assetField.children, context, labelWidth);
              continue;
            }
            
            var input = undefined;
            var width = assetField[$ "width"] ?? "100%";
            var _asset = self.asset;
            var scope = { asset: _asset, assetField };
            
            // Only apply marginTop if it's the very first item of the list
            var marginTop = (i == 0 && container == self.ui.Inspector.Content.Items) ? 
              0 :
              (assetField.type == "label" || assetField.type == "section" ? 25 : 15);
            
            var onChangeFn = assetField[$ "onChange"];
            var onChange = method(scope, onChangeFn != undefined ? onChangeFn : function(value, input) {
                self.asset[$ self.assetField.field] = value;
                
                // Mark as override if this is a prefab instance
                if (self.asset[$ "prefab"] != undefined && self.asset.prefab != undefined && self.assetField[$ "field"] != undefined) {
                    self.asset.setOverride(self.assetField.field);
                }
                
                // Track the change in asset manager
                global.editor.assetManager.editAsset(self.asset);
                
                var _onAfterChange = self.assetField[$ "onAfterChange"];
                if (_onAfterChange != undefined) {
                    method(self, _onAfterChange)();
                } 
            });
            
            var valueGetterFn = assetField[$ "valueGetter"];
            var valueGetter = valueGetterFn != undefined ? method(scope, valueGetterFn) : undefined;
            
            var onBlurFn = assetField[$ "onBlur"];
            var onBlur = onBlurFn != undefined ? method(scope, function(value, input) {
                // Call the custom onBlur
                method(self, self.assetField.onBlur)(value, input);
                
                // Mark as override if this is a prefab instance (e.g. transformXYZ position/rotation/scale)
                if (self.asset[$ "prefab"] != undefined && self.asset.prefab != undefined && self.assetField[$ "field"] != undefined) {
                    self.asset.setOverride(self.assetField.field);
                }
                
                // Track the change in asset manager
                global.editor.assetManager.editAsset(self.asset);
            }) : undefined;
            
            switch (assetField.type) {
                case "label":
                    input = new UiText("", { flex: 1 }, {
                        valueGetter
                    });
                break;

                // Import a new sprite for the texture
                case "spriteFilePicker":
                    input = new UiInspectorSpriteFilePicker({ flex: 1, justifyContent: "center" }, {
                        asset: self.asset,
                        valueGetter: method(scope, function() { 
                            return asset.__cachedSprite;
                        }),
                        onChange
                    });
                break;
                
                case "meshPreview":
                    input = new UiInspectorMeshPreview({ height: 256, flex: 1, justifyContent: "center" }, {
                        asset: self.asset
                    });
                break;
                
                case "materialPreview":
                    input = new UiInspectorMaterialPreview({ height: 150, flex: 1, justifyContent: "center" }, {
                        asset: self.asset
                    });
                break;
                
                case "transformXYZ":
                    input = new UiInspectorTransformXYZ({ flex: 1, justifyContent: "space-between", flexDirection: "row", gap: 15 }, {
                        valueGetter,
                        onBlur
                    });
                break;
                
                case "text": 
                    input = new UiTextbox({ 
                        flex: 1, 
                        height: 25
                    }, {
                        format: assetField[$ "format"],
                        min: assetField[$ "min"],
                        max: assetField[$ "max"],
                        negative: assetField[$ "negative"],
                        disabled: assetField[$ "disabled"],
                        value: assetField[$ "field"] != undefined && self.asset != undefined ? self.asset[$ assetField[$ "field"]] : undefined,
                        valueGetter,
                        onFocus: method(scope, function(input) {
                            var field = self.assetField[$ "field"];
                            // Capture original value when focusing
                            input.__originalValue = (field != undefined) ? self.asset[$ field] : undefined;
                        }),
                        onBlur: method(scope, function(value, input) {
                            var field = self.assetField[$ "field"];
                            var format = self.assetField[$ "format"];
                            
                            // 1. Numeric conversion if needed
                            var finalValue = value;
                            if (format == "float" || format == "integer") {
                                if (value == "" || value == "-" || value == ".") {
                                    finalValue = 0;
                                } else {
                                    finalValue = real(value);
                                }
                            }
                            
                            // 2. Retrieve the old value captured on focus
                            var _oldValue = input[$ "__originalValue"];
                            if (_oldValue == undefined && field != undefined) {
                                _oldValue = self.asset[$ field]; // Fallback if never focused properly
                            }
                            
                            // 3. Update field if it exists
                            if (field != undefined) {
                                self.asset[$ field] = finalValue;
                                
                                // Mark as override if this is a prefab instance
                                if (self.asset[$ "prefab"] != undefined && self.asset.prefab != undefined) {
                                    self.asset.setOverride(field);
                                }
                                
                                // Push undo command
                                if (_oldValue != finalValue) {
                                    global.editor.undoManager.push(new UndoCommandPropertyChange(self.asset, field, _oldValue, finalValue));
                                }
                            }
                            
                            // 4. Call custom onBlur if it exists
                            var _onBlur = self.assetField[$ "onBlur"];
                            if (_onBlur != undefined) {
                                method(self, _onBlur)(finalValue, input);
                            }
                            
                            // 5. Track the change in asset manager
                            global.editor.assetManager.editAsset(self.asset);
                        })
                    });
                break;
                    
                case "checkbox": 
                    input = new UiCheckbox({ flex: 1, }, {
                        value: assetField[$ "field"] != undefined && self.asset != undefined ? self.asset[$ assetField[$ "field"]] : undefined,
                        valueGetter,
                        onChange: method(scope, function(value) {
                            // If this field manages its own undo/redo, delegate entirely to custom onChange
                            if ((self.assetField[$ "customUndo"] ?? false) == true) {
                                var _onChange = self.assetField[$ "onChange"];
                                if (_onChange != undefined) {
                                    method(self, _onChange)(value);
                                }
                                return;
                            }
                            
                            // Capture old value for undo
                            var _oldValue = self.asset[$ self.assetField.field];
                            
                            self.asset[$ self.assetField.field] = value;
                            
                            // Mark as override if this is a prefab instance
                            if (self.asset[$ "prefab"] != undefined && self.asset.prefab != undefined) {
                                self.asset.setOverride(self.assetField.field);
                            }
                            
                            // Push undo command
                            if (_oldValue != value) {
                                global.editor.undoManager.push(new UndoCommandPropertyChange(self.asset, self.assetField.field, _oldValue, value));
                            }
                            
                            // Track the change in asset manager
                            global.editor.assetManager.editAsset(self.asset);
                            
                            var _onChange = self.assetField[$ "onChange"];
                            if (_onChange != undefined) {
                                method(self, _onChange)(value);
                            }
                        })
                    });
                break;
                
                case "dropdown": 
                    var dropdownValue = assetField[$ "field"] != undefined && self.asset != undefined ? self.asset[$ assetField[$ "field"]] : undefined;
                    if (is_struct(dropdownValue) && assetField[$ "subKey"] != undefined) {
                        dropdownValue = dropdownValue[$ assetField[$ "subKey"]];
                    }
                    input = new UiDropdown({ flex: 1, }, {
                        items: assetField[$ "items"],
                        value: dropdownValue,
                        valueGetter,
                        onChange: method(scope, function(value, input) {
                            // Capture old value for undo
                            var _oldValue;
                            if (self.assetField[$ "subKey"] != undefined) {
                                _oldValue = self.asset[$ self.assetField.field][$ self.assetField.subKey];
                            } else {
                                _oldValue = self.asset[$ self.assetField.field];
                            }
                            
                            // If subKey is present, update the sub-property
                            if (self.assetField[$ "subKey"] != undefined) {
                                self.asset[$ self.assetField.field][$ self.assetField.subKey] = value;
                            } else {
                                self.asset[$ self.assetField.field] = value;
                            }
                            
                            // Mark as override if this is a prefab instance
                            if (self.asset[$ "prefab"] != undefined && self.asset.prefab != undefined) {
                                self.asset.setOverride(self.assetField.field);
                            }
                            
                            // Push undo command
                            if (_oldValue != value) {
                                var _undoField = self.assetField[$ "subKey"] != undefined 
                                    ? self.assetField.field + "." + self.assetField.subKey
                                    : self.assetField.field;
                                global.editor.undoManager.push(new UndoCommandPropertyChange(self.asset, self.assetField.field, _oldValue, value));
                            }
                            
                            // Track the change in asset manager
                            global.editor.assetManager.editAsset(self.asset);
                            
                            // Call custom onChange if defined
                            var _onChange = self.assetField[$ "onChange"];
                            if (_onChange != undefined) {
                                method(self, _onChange)(value, input);
                            }
                            
                            // Call custom onAfterChange if defined
                            var _onAfterChange = self.assetField[$ "onAfterChange"];
                            if (_onAfterChange != undefined) {
                                method(self, _onAfterChange)();
                            }
                        }),
                        itemsGetter: assetField[$ "itemsGetter"],
                        search: assetField[$ "search"],
                    });
                break;
            }
            
            var _Container = new UiNode({ marginTop, width: "100%", flexDirection: "row", justifyContent: "space-between", alignItems: "center" });
            
            // Check if this is an instance (has a prefab link)
            var _isInstance = (_asset[$ "prefab"] != undefined && _asset.prefab != undefined);
            var _fieldId = assetField[$ "field"];
            var _isFieldOverridden = _isInstance && _fieldId != undefined && _asset.isOverridden(_fieldId);
            
            // Blue override bar on the left side
            if (_isFieldOverridden) {
                var _overrideBar = new UiNode({ width: 3, height: "100%", marginRight: 4 }, {
                    onDraw: function() {
                        // Guard: layout may not have run yet on first frame
                        if (self[$ "x2"] == undefined) exit;
                        draw_set_color(#4488FF);
                        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
                    }
                });
                _Container.add(_overrideBar);
            }
    
            // Item label
            var _label = assetField[$ "label"];
            if (_label != undefined) {
                var _tooltip = assetField[$ "tooltip"];
                var _labelWidth = _isFieldOverridden ? labelWidth + 15 - 7 : labelWidth + 15;
                _Container.add(new UiText(assetField.label, { width: _labelWidth, height: 20 }, { 
                    tooltip: _tooltip,
                    pointerEvents: true 
                }));
            }
            
            if (input != undefined) {
                _Container.add(input);

                // Apply the focus on the first input added to the inspector
                if (focusFirst && !context.focused && assetField.type == "text") {
                    context.focused = true;
                    runLater(input.Input.focus);
                }
            }
            
            // Right-click context menu for override actions
            if (_isInstance && _fieldId != undefined) {
                _Container.pointerEvents = true;
                _Container.onMouseUp(method({ asset: _asset, fieldId: _fieldId, assetField }, function() {
                    if (mouse_lastbutton == mb_right) {
                        var _items = [];
                        if (asset.isOverridden(fieldId)) {
                            array_push(_items, {
                                label: "Apply '" + (assetField[$ "label"] ?? fieldId) + "' to Prefab",
                                onClick: method({ asset, fieldId }, function() {
                                    asset.applyOverride(fieldId);
                                    global.editor.editorManager.inspector.inspect(asset);
                                })
                            });
                            array_push(_items, {
                                label: "Revert '" + (assetField[$ "label"] ?? fieldId) + "'",
                                onClick: method({ asset, fieldId }, function() {
                                    asset.revertOverride(fieldId);
                                    global.editor.assetManager.editAsset(asset);
                                    global.editor.editorManager.inspector.inspect(asset);
                                })
                            });
                        } else {
                            array_push(_items, {
                                label: "No overrides on this field",
                                onClick: function() {}
                            });
                        }
                        new UiContextMenu(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _items).show();
                        return true;
                    }
                    return false;
                }));
            }
            
            container.add(_Container);
        }
    }
}
