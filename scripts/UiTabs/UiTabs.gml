/**
 * UI Tabs Component
 */
function UiTabs(style, props) : UiNode(style, props) constructor {
    self.tabs = variable_struct_get(props, "tabs");
    if (self.tabs == undefined) self.tabs = [];
    
    self.activeTab = variable_struct_get(props, "activeTab");
    if (self.activeTab == undefined) self.activeTab = 0;
    
    self.onChange = variable_struct_get(props, "onChange");

    self.flexDirection = "row";
    
    for (var i = 0; i < array_length(self.tabs); i++) {
        var tabName = self.tabs[i];
        var tabBtn = new UiButton(tabName, { height: "100%", paddingHorizontal: 15, marginRight: 2 }, { outline: false });
        
        tabBtn.tabIndex = i;
        tabBtn.tabName = tabName;
        tabBtn.tabsOwner = self;
        
        tabBtn.onClick(method(tabBtn, function() {
            var owner = self.tabsOwner;
            owner.activeTab = self.tabIndex;
            if (owner.onChange != undefined) {
                owner.onChange(self.tabIndex, self.tabName);
            }
        }));
        
        tabBtn.onStep(method(tabBtn, function() {
            var owner = self.tabsOwner;
            self.selected = (owner.activeTab == self.tabIndex);
        }));
        
        self.add(tabBtn);
    }
}
