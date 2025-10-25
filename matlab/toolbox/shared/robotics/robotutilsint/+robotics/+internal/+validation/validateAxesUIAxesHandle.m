function tf = validateAxesUIAxesHandle(ax)
%This function is for internal use only. It may be removed in the future.

%validateAxesUIAxesHandle Axes handle validation
%   Axes handle validation. Returns true if AX is a valid axes handle
%   otherwise an error is displayed.
%
%   In addition to standard axes handles, this function also allows UIAxes
%   handles. If your visualization function does not support UIAxes handles,
%   use the validateAxesHandle validation function instead.
%
%   See also validateAxesHandle.

%   Copyright 2016-2023 The MathWorks, Inc.

    tf = true;

    if ~isscalar(ax)
        error(message('shared_robotics:validation:InvalidAxesHandle'));
    end

    % Allow both Axes and UIAxes objects
    if ~isa(ax, 'matlab.graphics.axis.Axes')
        error(message('shared_robotics:validation:InvalidAxesHandle'));
    end

end
