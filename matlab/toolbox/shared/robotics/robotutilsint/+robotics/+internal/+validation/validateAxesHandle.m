function tf = validateAxesHandle(ax, errorID)
%This function is for internal use only. It may be removed in the future.

%validateAxesHandle Axes handle validation
%   validateAxesHandle(AX) returns true if AX is a valid axes handle
%   otherwise an error is displayed.
%
%   validateAxesHandle(AX, ERRORID) uses the specified ERRORID when an
%   error is displayed. By default, this function will use
%   'shared_robotics:validation:InvalidAxesHandle'.
%
%   This function explicitly rejects UIAxes handles. If your visualization
%   function supports UIAxes handles, use the validateAxesUIAxesHandle
%   validation function instead.
%
%   See also validateAxesUIAxesHandle.

%   Copyright 2014-2023 The MathWorks, Inc.

    tf = true;

    if nargin == 1
        % Use default error ID.
        errorID = 'shared_robotics:validation:InvalidAxesHandle';
    end

    % Explicitly reject UIAxes handles
    if isa(ax, 'matlab.ui.control.UIAxes')
        error(message('MATLAB:ui:uiaxes:NotSupported'));
    end

    % Only allow scalar Axes handles
    if ~(isscalar(ax) && isa(ax, 'matlab.graphics.axis.Axes'))
        error(message(errorID));
    end

end
