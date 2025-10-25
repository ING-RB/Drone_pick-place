function cost = defaultCost(trajectories, controlSequences, mppiObject)
%defaultCost Default cost function for controllerMPPI.
%
%   cost = nav.algs.mppi.defaultCost(trajectories, controlSequences,
%   mppiObject) computes the default cost for each of the generated
%   trajectories based on the MPPI control algorithm. The function is
%   designed to work with the controllerMPPI class and utilizes its
%   properties and methods to evaluate the cost of the trajectories.
%
%   Inputs:
%       trajectories        - A 3D array (NumStates x NumVehicleStates
%                             x NumTrajectories) of generated trajectories,
%                             where NumStates is the number of states along
%                             the trajectory and each slice along the third
%                             dimension corresponds to a single trajectory.
%       controlSequences    - A 3D array (NumStates x NumVehicleInputs
%                              x NumTrajectories) of generated trajectory
%                             controls, where NumStates is the number of
%                             states along the trajectory and each slice
%                             along the third dimension corresponds to a
%                             single trajectory's controls.
%       mppiObject          - An instance of the controllerMPPI class.
%
%   Outputs:
%       cost                - A column vector (NumTrajectories x 1) of
%                             costs associated with each trajectory. The
%                             cost value can range from 0 to infinity. An
%                             infinite cost signifies a violation of
%                             constraints, leading to the rejection of the
%                             associated trajectory.
%
%   This function evaluates the cost of each trajectory by considering
%   factors such as the deviation from the reference path, control effort,
%   and proximity to obstacles defined in the mppiObject.
%
%   See also controllerMPPI, pathFollowingCost, obstacleRepulsionCost
%
%   Note: Users can create custom cost function if needed by following the
%   customCost template provided by the controllerMPPI class. This default
%   function serves as a starting point and may be sufficient for many
%   standard applications.


% Copyright 2024 The MathWorks, Inc.

%#codegen

arguments
    trajectories double {mustBeNonempty,mustBeFinite}
    controlSequences double {mustBeNonempty,mustBeFinite}
    mppiObject {mustBeA(mppiObject, 'controllerMPPI')}
end

% Initialize cost
numTraj = size(trajectories, 3);
cost = zeros(numTraj, 1);

% Cost function weights
weightPathFollowing = mppiObject.Options.Parameters.CostWeights.PathFollowing;
weightPathAlignment = mppiObject.Options.Parameters.CostWeights.PathAlignment;
weightObstacleRepulsion = mppiObject.Options.Parameters.CostWeights.ObstacleRepulsion;
weightControlCost = mppiObject.Options.Parameters.CostWeights.ControlSmoothing;

% Path following cost
if weightPathFollowing>0
    cost = cost +...
           weightPathFollowing*nav.algs.mppi.pathFollowingCost(trajectories,mppiObject.LookaheadEndPose);
end

% Path alignment cost
if weightPathAlignment>0
    scalingFactor = 1000; % To bring this in same magnitude as Other Costs
    cost = cost +...
           scalingFactor*weightPathAlignment*nav.algs.mppi.pathAlignmentCost(trajectories,mppiObject.LookaheadPoses);
end

% Obstacle repulsion cost
if weightObstacleRepulsion>0
    repulsionCost = nav.algs.mppi.obstacleRepulsionCost(...
        trajectories, mppiObject.Map,...
        mppiObject.Options.Parameters.VehicleCollisionInformation);
    cost = cost + weightObstacleRepulsion * repulsionCost;
end

% Control smoothing cost
if weightControlCost > 0
    cost = cost +...
           weightControlCost * nav.algs.mppi.controlSmoothingCost(controlSequences,...
                                                                  mppiObject.PrevOptTrajControls, mppiObject.StandardDeviation);
end
