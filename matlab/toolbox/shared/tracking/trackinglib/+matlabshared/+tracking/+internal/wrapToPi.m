function theta = wrapToPi(theta)
%This function is for internal use only. It may be removed in the future.

%wrapToPi Wrap angle in radians to interval [-pi pi]
%
%   THETAWRAP = wrapToPi(THETA) wraps angles in THETA to the interval
%   [-pi pi]. Positive, odd multiples of pi map to pi and negative, odd 
%   multiples of pi map to -pi.

% Copyright 2015-2017 The MathWorks, Inc.

%#codegen

piVal = cast(pi,'like',theta);

theta = wrapTo2Pi(theta + piVal) - piVal;

end

function thetaWrap = wrapTo2Pi(theta)
%wrapTo2Pi Wrap angle in radians to interval [0 2*pi]
%
%   THETAWRAP = wrapTo2Pi(THETA) wraps angles in THETA to the interval
%   [0 2*pi]. Positive multiples of 2*pi map to 2*pi and negative
%   multiples of 2*pi map to 0.

theta = real(theta);
twoPiVal = cast(2*pi,'like',theta);

% Wrap to 2*pi
thetaWrap = mod(theta, twoPiVal);

% Make sure that positive multiples of 2*pi map to 2*pi
for kk=1:numel(thetaWrap)
    if thetaWrap(kk)==0 && theta(kk)>0
        thetaWrap(kk) = twoPiVal;
    end
end
end