function enableDefaultInteractivity(ax)
%ENABLEDEFAULTINTERACTIVITY turns on default interactivity
%  ENABLEDEFAULTINTERACTIVITY(AXES) turns on default interactivity on
%  given axes, uiaxes, geoaxes or polaraxes

%   Copyright 2018-2020 The MathWorks, Inc.

narginchk(1,1);
if isa(ax,'matlab.graphics.axis.AbstractAxes')
    ax.InteractionContainer.Enabled = 'on';
else
    error(message('MATLAB:graphics:interaction:InvalidInputAxes'));
end
