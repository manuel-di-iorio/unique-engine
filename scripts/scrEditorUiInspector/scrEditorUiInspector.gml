function EditorUiInspector(ui) constructor {
    self.ui = ui;

    ui.Inspector = new UiNode({ name: "Inspector", minWidth: 350, width: "21%", marginBottom: 62, flexDirection: "column" }, { border: true });

    with (ui.Inspector) {
        function onDraw() {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
            draw_text(self.x1 + 20, self.y1 + 8, "Inspector");
        }
    };

    // Inspector close button
    ui.Inspector.Close = new UiButton(sprUiClose, { display: "none", position: "absolute", top: 5, right: 5, width: 28, height: 28 }, { outline: true, tooltip: "Close inspector" });

    with (ui.Inspector.Close) {
        self.onClick(function() {
            oSceneEditor.editorManager.clearActiveAsset();
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
        "ModelInstance": scrEditorInspectorModelInstance(), 
        "Scene": scrEditorInspectorScene(), 
        "Folder": scrEditorInspectorFolder(),
    }
    
    /**
     * Dynamically create the inspector fields
     */
    function inspect(asset, focusFirst = false) {
        self.ui.Inspector.Close.show();

        self.asset = asset;
        self.focusFirst = focusFirst;
        var assetType = asset.type;
        var assetFields = fields[$ assetType];
        
        // Clear the previous content
        var _Items = self.ui.Inspector.Content.Items;
        self.close();
        
        // First pass: calculate the max label width among all items (recursive)
        draw_set_font(fText);
        var _labelWidth = __getMaxLabelWidth(assetFields);
        
        // Second pass: add the labels and inputs recursively
        var _context = { focused: false };
        
        __renderFields(self.ui.Inspector.Content.Items, assetFields, _context, _labelWidth); 
    } 
    
    function close() {
        self.ui.Inspector.Content.Items.destroyChildren();
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
            
            // Handle Sections with children
            if (assetField.type == "section" && assetField[$ "children"] != undefined) {
              var isCollapsed = assetField[$ "collapsed"] ?? false;

              // Header
              var _header = new UiNode({ 
                  width: "100%",
                  flexDirection: "row", 
                  alignItems: "center",
                  marginTop: 20, 
                  paddingHorizontal: 10,
                  paddingVertical: 2
              }, { pointerEvents: true });
              
              with (_header) {
                function onDraw() {
                  draw_set_color(hovered ? global.UI_COL_SELECTION : global.UI_COL_BTN_HOVER);
                  draw_roundrect(x1, y1, x2, y2, false)
                }
              }
                
              var _arrow = new UiSprite(isCollapsed ? sprUiTreeviewArrowRight : sprUiTreeviewArrowDown, { width: 12, height: 12, marginRight: 10 });
              var _label = new UiText(assetField.label, {});
              _header.add(_arrow, _label);
                
              // Content
              var _content = new UiNode({ 
                  width: "100%", 
                  flexDirection: "column",
                  display: isCollapsed ? "none" : "flex",
                  paddingLeft: 0
              });
              
              _header.onClick(method({ content: _content, arrow: _arrow }, function() {
                  if (!content.isVisible()) {
                      content.show();
                      arrow.sprite = sprUiTreeviewArrowDown;
                  } else {
                      content.hide();
                      arrow.sprite = sprUiTreeviewArrowRight;
                  }
              }));
              
              container.add(_header);
              container.add(_content);
              
              __renderFields(_content, assetField.children, context, labelWidth);
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
                
                // Track the change in asset manager
                oSceneEditor.assetManager.editAsset(self.asset);
                
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
                
                // Track the change in asset manager
                oSceneEditor.assetManager.editAsset(self.asset);
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
                            valueGetter: method(scope, function() { 
                            return asset.__cachedSprite;
                        }),
                        onChange
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
                        value: self.asset[$ assetField.field],
                        valueGetter,
                        onBlur: method(scope, function(value, input) {
                            if (value == "") {
                                input.value = self.asset[$ self.assetField.field];
                                return;
                            }
                            
                            self.asset[$ self.assetField.field] = value;
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                        })
                    });
                break; 
                    
                case "checkbox": 
                    input = new UiCheckbox({ flex: 1, }, {
                        value: self.asset[$ assetField.field],
                        valueGetter,
                        onChange: method(scope, function(value) {
                            self.asset[$ self.assetField.field] = value;
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                            
                            var _onChange = self.assetField[$ "onChange"];
                            if (_onChange != undefined) {
                                method(self, _onChange)(value);
                            }
                        })
                    });
                break;
                
                case "dropdown": 
                    var dropdownValue = self.asset[$ assetField.field];
                    if (is_struct(dropdownValue) && assetField[$ "subKey"] != undefined) {
                        dropdownValue = dropdownValue[$ assetField[$ "subKey"]];
                    }
                    input = new UiDropdown({ flex: 1, }, {
                        items: assetField[$ "items"],
                        value: dropdownValue,
                        valueGetter,
                        onChange: method(scope, function(value, input) {
                            // If subKey is present, update the sub-property
                            if (self.assetField[$ "subKey"] != undefined) {
                                self.asset[$ self.assetField.field][$ self.assetField.subKey] = value;
                            } else {
                                self.asset[$ self.assetField.field] = value;
                            }
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                            
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
    
            // Item label
            var _label = assetField[$ "label"];
            if (_label != undefined) {
                var _tooltip = assetField[$ "tooltip"];
                _Container.add(new UiText(assetField.label, { width: labelWidth + 15, height: 20 }, { 
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
            
            container.add(_Container);
        }
    }
}
