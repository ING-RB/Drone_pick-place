function setBrushColor(e, ~)
% This undocumented function may be removed in a future release.

% Set the brushing color for the current figure

% Copyright 2018 The MathWorks, Inc.

% Get the current figure from the object that caused the event. 
% If we can't using gcf will work as well
fig = ancestor(e, 'figure');
if isempty(fig)
    fig = gcf;
end

% Get the brushing mode object
brushObj = brush(fig);
% Get the color
newColor = uisetcolor(brushObj.Color);

% uisetcolor returns 0 upon errors or cancel, else it return the RGB
% triple
if length(newColor) > 1
    brushObj.Color = newColor;
end
end

