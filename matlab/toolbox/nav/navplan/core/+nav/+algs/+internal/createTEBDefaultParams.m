function params = createTEBDefaultParams()
%This function is for internal use only. It may be removed in the future.

% createTEBDefaultParams define the default values for all the parameters in
% TimedElasticBandCarGraph.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

params = struct(...
    'RobotType', 0, ...% Type of robot. 0 represent car-like robot.
    'RobotDimension',[0 0],...% Define the dimension of the robot.[0 0] indicates point shaped robot.
    'RobotFixedTransform',[0,0,0],... % FixedTransform for user-defined robot origin.
    'ReferenceDeltaTime', 0.3, ...% Travel time between two consecutive poses.
    'MaxPathStates', 200, ...% Maximum number of poses allowed in the path.
    'NumIteration', 4, ... % Number of solver invocations.
    'MaxSolverIteration', 15, ...% Maximum number of iterations per solver invocation.
    'WeightTime', 0, ...% Cost function weight for time.
    'WeightSmoothness', 0, ...% Cost function weight for nonholonomic motion.
    'WeightMinTurningRadius',0, ... % Cost function weight for complying with minimum turning radius.
    'WeightForwardDrive', 0, ...% Cost function weight for preferring positive drive direction in differential drive robots.
    'WeightVelocity', 0, ... % Cost function weight for velocity.
    'WeightAngularVelocity', 0, ... % Cost function weight for angular velocity.
    'WeightAcceleration', 0, ...% Cost function weight for acceleration.
    'WeightAngularAcceleration', 0, ... % Cost function weight for angular acceleration.
    'WeightObstacles', 0, ...% Cost function weight for maintaining safe distance from obstacles.
    'MinTurningRadius', 0, ...% Minimum turning radius in path.
    'MaxVelocity', 0.4, ...% Maximum velocity along path.
    'MaxAngularVelocity', 0.3, ... % Maximum angular velocity along path.
    'MaxReverseVelocity', NaN, ... % Maximum reverse velocity along path.
    'MaxAcceleration', 0.5, ... % Maximum acceleration along path.
    'MaxAngularAcceleration', 0.5, ... % Maximum angular acceleration along path.
    'StartVelocity', 0,... % Velocity of the robot at start pose.
    'EndVelocity', 0, ...% Velocity of the robot at goal pose.
    'StartAngularVelocity', 0, ...% Angular velocity of the robot at start pose.
    'EndAngularVelocity', 0, ... % Angular velocity of the robot at goal pose.
    'ObstacleSafetyMargin', 0.5, ... % Safety distance from obstacles.
    'ObstacleCutOffDistance', 2.5, ...% Obstacle cutoff distance.
    'ObstacleInclusionDistance', 0.75, ...% Obstacle inclusion distance.
    'NumRobotCollisionCircles', 3 ... % Num of collision circles representing robot
    );

end
