function hh = yregion(varargin)
%

%   Copyright 2022 The MathWorks, Inc.

    args = varargin;
    h = matlab.graphics.internal.xyzregion('y', args);

    % Prevent outputs when not assigning to variable.
    if nargout > 0
        hh = h; 
    end
end

