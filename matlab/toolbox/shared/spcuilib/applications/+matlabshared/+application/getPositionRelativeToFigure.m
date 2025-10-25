function pos = getPositionRelativeToFigure(obj, fig)
%getPositionRelativeToFigure - Get the position relative to the figure

%   Copyright 2017 The MathWorks, Inc.

pos = getpixelposition(obj);
parent = get(obj, 'Parent');
if nargin < 2
    fig = ancestor(obj, 'figure');
end

% Loop until we hit the figure.
while parent ~= fig
    parentPos = getpixelposition(parent);
    
    % Add the pixel position of the parent to the pixel position of the
    % object.  Remove [1 1] because in pixels [1 1] is the origin.
    pos(1) = pos(1)+parentPos(1)-1;
    pos(2) = pos(2)+parentPos(2)-1;
    
    parent = get(parent, 'Parent');
end

% [EOF]
