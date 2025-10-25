function stepProps = getDefaultStepProps()
% This function returns the step values for various keyboard interactions
% in point cloud visualization tools. The clients can choose to implement
% their own function to pass appropriate step sizes or modify the returned
% struct.

% Copyright 2022 The MathWorks, Inc.

stepProps = struct();

% For move operations, move by by 10% of the distance between camera
% position and camera target
stepProps.MoveStepSize = 0.1;

% This defines the step size for panning. The format is 
% [panStepSize panAngleMin panAngleMax]. panStepSize is the percentage step
% size of max and min of the data limits.
stepProps.PanStepProperties = [0.08 0.5 5];
% horizontalPan is a boolean that tells whether to pan horizontally or
% vertically
stepProps.HorizontalPan = true;
% panDirection tells whether to pan in positive direction or negative
stepProps.PanDirection = 1;


% This defines the step size for rotating the scene. The format is
% [rotateStepSize rotateAngleMin rotateAngleMax]. rotateStepSize is the
% percentage step size of max and min of the data limits.
stepProps.RotateStepProperties = [0.08 5 10];
% horizontalRotate is a boolean that tells whether to rotate horizontally or
% vertically
stepProps.HorizontalRotate = true;
% rotateDirection tells whether to rotate in positive direction or negative
stepProps.RotateDirection = 1;

stepProps.RollAngle = 5;
stepProps.ZoomFactor = 1.5;

end