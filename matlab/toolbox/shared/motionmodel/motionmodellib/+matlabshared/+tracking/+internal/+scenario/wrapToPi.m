function theta = wrapToPi(theta)
%This function is for internal use only. It may be removed in the future.

%wrapToPi Wrap angle in radians to interval [-pi pi]
%
%   THETAWRAP = wrapToPi(THETA) wraps angles in THETA to the interval
%   [-pi pi]. Positive, odd multiples of pi map to pi and negative, odd 
%   multiples of pi map to -pi.

% Copyright 2022 The MathWorks, Inc.

%#codegen

    if any(abs(theta) > pi, 'all')
        % Only wrap values if one or more needs to be wrapped
        piVal = cast(pi,'like',theta);

        theta = matlabshared.tracking.internal.scenario.wrapTo2Pi(theta + piVal) - piVal;
    end
end
