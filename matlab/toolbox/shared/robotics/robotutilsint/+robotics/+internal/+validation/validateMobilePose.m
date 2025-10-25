function validPose = validateMobilePose(inPose, fcnName, argName)
%This function is for internal use only. It may be removed in the future.

%VALIDATEMOBILEPOSE Validate pose [x y theta] for mobile robot
%   VALIDPOSE is guaranteed to be a row vector with a valid pose.

%   Copyright 2016-2023 The MathWorks, Inc.

%#codegen

% Make sure pose is valid and a row vector
    validateattributes(inPose, {'numeric'}, {'nonempty', 'real', 'nonnan', 'finite', 'vector', 'numel', 3}, fcnName, argName);
    validPose = double(inPose(:).');

    % Wrap the angle to [-pi,pi] limits
    validPose(3) = robotics.internal.wrapToPi(validPose(3));

end
