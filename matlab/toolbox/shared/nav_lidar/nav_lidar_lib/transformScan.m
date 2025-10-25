function [transRanges, transAngles] = transformScan(ranges, angles, relPose)
%transformScan Transform laser scan based on relative pose
%   TRANSSCAN = transformScan(SCAN, RELPOSE) transforms the laser scan
%   given by the lidarScan object, SCAN. The translation and rotation are
%   defined in the relative pose, RELPOSE. The transformed laser scan is
%   returned in TRANSSCAN.
%
%   [TRANSRANGES, TRANSANGLES] = transformScan(RANGES, ANGLES, RELPOSE)
%   transforms the laser scan given by RANGES and ANGLES. The transformed
%   laser scan is returned in TRANSRANGES and TRANSANGLES.
%
%   RELPOSE is a 3-element vector, [x y theta], representing the relative pose
%   that is used to transform the scan. [x y] is the translation
%   (in meters) and [theta] is the rotation (in radians).
%
%
%   Example:
%       % Example laser scan data input
%       refRanges = 5 * ones(1, 300);
%       refAngles = linspace(-pi/2, pi/2, 300);
%       refScan = lidarScan(refRanges, refAngles);
%
%       % Translate laser scan by an (x,y) offset of (0.5, 0.2)
%       translScan = transformScan(refScan, [0.5, 0.2, 0])
%
%       % Rotate raw ranges and angles by 20 degrees
%       [rotRanges, rotAngles] = transformScan(refRanges, refAngles, [0, 0, deg2rad(20)]);
%
%
%   See also matchScans, lidarScan/transformScan.

%   Copyright 2016-2018 The MathWorks, Inc.

%#codegen

% Parse the function inputs
    narginchk(2,3);
    [validScan, validPose, hasRowRanges] = parseInput(ranges, angles, relPose);

    % Transform scan
    transScan = nav.algs.internal.transformScan(validScan, validPose);

    % Return ranges and angles as numeric arrays
    % Transpose outputs if inputs were rows
    transRanges = reshapeOutput(hasRowRanges, transScan.Ranges);
    transAngles = reshapeOutput(hasRowRanges, transScan.Angles);

end


function [validScan, validPose, hasRowRanges] = parseInput(ranges, angles, relPose)
%parseInput Parse the inputs of the function
%   The function takes ranges / angles input and returns a lidarScan object

    validScan = robotics.internal.validation.validateLidarScan(...
        ranges, angles, 'transformScan', 'ranges', 'angles');

    hasRowRanges = isrow(ranges);

    % Always validate pose input
    validPose = robotics.internal.validation.validateMobilePose(...
        relPose, 'transformScan', 'relPose');

end


function shapedOutArray = reshapeOutput(hasRow, outArray)
%reshapeOutput Reshape output based on size of input array
%    SHAPEDOUTARRAY will always have the same size as INARRAY.
%    SHAPEDOUTARRAY will be reshaped from the OUTARRAY input.

    if hasRow
        shapedOutArray = outArray';
    else
        shapedOutArray = outArray;
    end
end
