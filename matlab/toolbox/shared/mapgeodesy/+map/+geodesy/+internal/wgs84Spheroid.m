function s = wgs84Spheroid()
% Return oblateSpheroid object for WGS84 with SemimajorAxis in meters.
%
%       FOR INTERNAL USE ONLY -- This function is intentionally
%       undocumented and is intended for use only within other toolbox
%       functions and classes. Its behavior may change, or the function
%       itself may be removed in a future release.

% Copyright 2019-2020 The MathWorks, Inc.

%#codegen

    s = oblateSpheroid;
    s.SemimajorAxis = 6378137;
    s.InverseFlattening = 298.257223563;
end
