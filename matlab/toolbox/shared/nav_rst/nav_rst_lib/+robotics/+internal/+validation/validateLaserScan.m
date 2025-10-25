function [validRanges, validAngles] = validateLaserScan(inRanges, inAngles, fcnName, rangesArgName, anglesArgName, allowNonFiniteAngles)
%This function is for internal use only. It may be removed in the future.

%VALIDATELASERSCAN Validate ranges and angles for laser scan
%   Since most of our functionality require ranges and angles to be
%   specified together, this convenience function validates them in tandem.

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

    if nargin <= 5
        % If not user-specified, disallow non-finite angles
        allowNonFiniteAngles = false;
    end

    % Validate the vectors separately
    validRanges = robotics.internal.validation.validateLaserRanges(inRanges, fcnName, rangesArgName);
    validAngles = robotics.internal.validation.validateLaserAngles(inAngles, fcnName, anglesArgName, allowNonFiniteAngles);

    % Data type of ranges takes precedence
    validAngles = cast(validAngles, class(validRanges));

    % Ensure that they have the same length
    isInvalidSize = (numel(validRanges) ~= numel(validAngles));
    coder.internal.errorIf(isInvalidSize, ...
                           'shared_robotics:validation:SizeMismatch', rangesArgName, anglesArgName);

end
