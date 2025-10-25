function generateLiveCode(fig)
% This function calls the "generateLiveCode" API for generating code in
% Live Editor figures. 

%   Copyright 2021 The MathWorks, Inc.


old_state = getappdata(fig, 'AxesStateBeforeKeyPress');

% If the appdata doesn't exist, nothing to do, so return
if(isempty(old_state))
    return;
end

ax = old_state.Axes;
old_view = old_state.View;

if(~isequal(ax.View, old_view))
    % If the view property has changed, a rotate interaction has occured.
    matlab.graphics.interaction.generateLiveCode(ax, ...
        matlab.internal.editor.figure.ActionID.ROTATE);
else
    % OTherwise, a pan or zoom interaction has occured. 
    matlab.graphics.interaction.generateLiveCode(ax, ...
        matlab.internal.editor.figure.ActionID.PANZOOM);

end

end

