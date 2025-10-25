function result = isUIComponent(item)
% isUIComponent Determine whether the item is a UI component. Returns true
% if the item is a UI component and false otherwise.

%   Copyright 2022-2023 The MathWorks, Inc.

result = false;
if ishghandle(item)
    % Check to see if the item falls in the UI component group
    item = handle(item); % To ensure double handles work
    if (isa(item, 'matlab.ui.control.ClientComponent') || ... % uitable and uicontrol
        isa(item, 'matlab.ui.internal.mixin.CanvasHostMixin') || ... % uipanel, uibuttongroup, uicontainer, hgjavacomponent, uitab
        isa(item, 'matlab.ui.container.TabGroup') || ... % uitabgroup
        isa(item, 'matlab.ui.control.internal.model.ComponentModel') ||...
        isa(item, 'matlab.ui.container.Tree') ||...
        isa(item, 'matlab.ui.container.GridLayout') ||...
        isa(item, 'matlab.ui.container.internal.Accordion'))
        result = true;
    end
end
