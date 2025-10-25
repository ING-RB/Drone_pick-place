function s = sphericalEarth()
% Return map.geodesy.Sphere object with standard earth radius:
% 6,371,000 meters.
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.

% Copyright 2019-2020 The MathWorks, Inc.

%#codegen

    s = map.geodesy.Sphere;
    s.Radius = 6371000;
end
