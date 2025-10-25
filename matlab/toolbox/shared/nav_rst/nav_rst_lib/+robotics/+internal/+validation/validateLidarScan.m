function validLidarScan = validateLidarScan(varargin)
%This function is for internal use only. It may be removed in the future.

%VALIDATELIDARSCAN Validate lidar scan input (either object or ranges/angles)
%   VALIDLIDARSCAN = VALIDATELIDARSCAN(LIDARSCAN, FCNNAME, SCANARGNAME)
%   validates the lidarScan object, LIDARSCAN, and returns a validated
%   object in VALIDLIDARSCAN. Validation errors use FCNNAME and SCANARGNAME
%   to display an appropriate message.
%
%   VALIDLIDARSCAN = VALIDATELIDARSCAN(RANGES, ANGLES, FCNNAME,
%   RANGESARGNAME, ANGLESARGNAME) validates the numeric RANGES and ANGLES
%   input and returns a validated lidarScan object, VALIDLIDARSCAN.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

if nargin == 3
    % Call syntax: VALIDLIDARSCAN = VALIDATELIDARSCAN(LIDARSCAN, FCNNAME, SCANARGNAME)
    validLidarScan = varargin{1};
    fcnName = varargin{2};
    scanArgName = varargin{3};
    
    validateattributes(validLidarScan, {'lidarScan'}, {'nonempty', 'scalar'}, fcnName, scanArgName);
    return;
end

if nargin == 5
    % Call syntax: VALIDLIDARSCAN = VALIDATELIDARSCAN(RANGES, ANGLES, FCNNAME, RANGESARGNAME, ANGLESARGNAME)
    ranges = varargin{1};
    angles = varargin{2};
    fcnName = varargin{3};
    rangesArgName = varargin{4};
    anglesArgName = varargin{5};
    
    % Validate ranges and angles and return lidarScan object
    [validRanges, validAngles] = robotics.internal.validation.validateLaserScan(ranges, angles, fcnName, rangesArgName, anglesArgName);
    validLidarScan = lidarScan(validRanges, validAngles);
    return;
end

end

