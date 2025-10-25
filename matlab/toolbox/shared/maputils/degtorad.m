function angleInRadians = degtorad(angleInDegrees)
% DEGTORAD Convert angles from degrees to radians
%
%   DEGTORAD is not recommended. Use deg2rad instead.
%
%   angleInRadians = DEGTORAD(angleInDegrees) converts angle units from
%   degrees to radians.
%
%   See also: DEG2RAD

% Copyright 2009-2017 The MathWorks, Inc.

angleInRadians = (pi/180) * angleInDegrees;
