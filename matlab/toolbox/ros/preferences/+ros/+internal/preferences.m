function varargout = preferences
%PREFERENCES Launch ROS preferences UI. 

%  Copyright 2022 The MathWorks, Inc.
ui = findobjinternal(0,'Type','Figure','Name',...
    getString(message("ros:utilities:preferences:ROSToolboxPreferences")));
if isempty(ui)
    ui = matlab.ui.internal.preferences.preferencePanels.ROSToolboxPreferences();
else
    focus(ui);
end
if nargout > 0
    varargout{1} = ui;
end
end