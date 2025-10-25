function disableDefaultInteractivity(ax)
%DISABLEDEFAULTINTERACTIVITY turns off default interactivity 
%  DISABLEDEFAULTINTERACTIVITY(AXES) turns off default interactivity on
%  given axes, uiaxes, geoaxes or polaraxes

%   Copyright 2018-2020 The MathWorks, Inc.

narginchk(1,1);
if isa(ax,'matlab.graphics.axis.AbstractAxes')
    ax.InteractionContainer.Enabled = 'off';
else
    error(message('MATLAB:graphics:interaction:InvalidInputAxes'));
end
