function bisect = bisectAngles(theta1, theta2)
%This function is for internal use only. It may be removed in the future.

%bisectAngles Find bisection angle between two angles
%
%   BISECT = bisectAngles(THETA1, THETA2) computes bisecting angle between
%   two angles THETA1 and THETA2 and returns the BISECT within the interval
%   [-pi pi]. Positive, odd multiples of pi map to pi and negative, odd
%   multiples of pi map to -pi.

% Copyright 2015-2019 The MathWorks, Inc.

%#codegen

    theta1 = robotics.internal.wrapToPi(theta1);
    theta2 = robotics.internal.wrapToPi(theta2);

    %Get angle bisection
    deltaAng = theta1 - theta2;
    angle = theta1 - deltaAng/2.0;

    % Make sure the output is in the [-pi,pi) range
    bisect = robotics.internal.wrapToPi(angle);

end
