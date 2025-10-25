function TF = isAxesInteractionModeActive(ax,fig)
%isAxesInteractionModeActive Determine if axes interaction mode is active.
%
%   TF = isAxesInteractionModeActive(ax,fig) returns true if an axes
%   interaction mode (such as zoom or pan) is active in the specified axes
%   and figure. 
%
%   Note: The input arguments are not checked for validity.

%   Copyright 2021 The MathWorks, Inc.

is_html_canvas = isa(getCanvas(fig),...
    "matlab.graphics.primitive.canvas.HTMLCanvas");

if is_html_canvas
    % Interactivity modes are set and queried at the axes level.
    TF = ax.InteractionContainer.CurrentMode ~= "none";
else
    % Interactivity modes are set and queried at the figure level.
    hManager = uigetmodemanager(fig);
    hMode = hManager.CurrentMode;
    TF = isobject(hMode) && isvalid(hMode) && ~isempty(hMode);
end

end