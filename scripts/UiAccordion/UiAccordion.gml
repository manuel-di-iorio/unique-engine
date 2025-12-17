function UiAccordion(text, style = {}, data = {}) : UiNode(style, data) constructor {
  self.text = text;
  self.collapsed = data[$ "collapsed"] ?? false;
  self.spriteCollapsed = data[$ "spriteCollapsed"] ?? sprUiTreeviewArrowRight;
  self.spriteExpanded = data[$ "spriteExpanded"] ?? sprUiTreeviewArrowDown;
  
  // Default style adjustments
  if (style[$ "width"] == undefined) self.setWidth("100%");
  if (style[$ "flexDirection"] == undefined) flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.column);
  
  // Create Header
  self.Header = new UiNode({ 
      width: "100%",
      flexDirection: "row", 
      alignItems: "center",
      paddingHorizontal: 10,
      paddingVertical: 2,
      height: 24,
  }, { pointerEvents: true });
  
  with (self.Header) {
      self.onDraw = function() {
          var col = self.hovered ? global.UI_COL_SELECTION : global.UI_COL_BTN_HOVER;
          draw_set_color(col);
          draw_roundrect(self.x1, self.y1, self.x2, self.y2, false);
      }
  }
  
  // Arrow
  var arrowSprite = self.collapsed ? self.spriteCollapsed : self.spriteExpanded;
  self.Arrow = new UiSprite(arrowSprite, { width: 12, height: 12, marginRight: 10 });
  
  // Label
  self.Label = new UiText(self.text, {}, { color: c_white });
  
  self.Header.add(self.Arrow, self.Label);
  
  // Content Container
  self.Content = new UiNode({
      width: "100%",
      flexDirection: "column",
      display: self.collapsed ? "none" : "flex",
      paddingLeft: 0 
  });
  
  // Add internal nodes to self using the inherited add (before we override)
  self.add(self.Header, self.Content);
  
  /** Methods */
  
  self.collapse = function() {
      self.collapsed = true;
      self.Content.hide();
      self.Arrow.sprite = self.spriteCollapsed;
      return self;
  }
  
  self.expand = function() {
      self.collapsed = false;
      self.Content.show();
      self.Arrow.sprite = self.spriteExpanded;
      return self;
  }
  
  // Override add to put children into Content
  self.add = function() {
      for (var i=0; i<argument_count; i++) {
          self.Content.add(argument[i]);
      }
      return self;
  }
  
  // Toggle Logic
  self.Header.onClick(method(self, function() {
      if (self.collapsed) {
          self.expand();
      } else {
          self.collapse();
      }
  }));
}
