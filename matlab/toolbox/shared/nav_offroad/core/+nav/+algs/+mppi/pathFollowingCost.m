function cost = pathFollowingCost(trajectories, targetPose, weightXY, weightTheta)
%pathFollowingCost Calculates the cost for path following based on trajectory.
%
%   cost = nav.algs.mppi.pathFollowingCost(trajectories, targetPose,
%   weightXY, weightTheta) computes the cost associated with each
%   trajectory based on the distance and angular deviation from a target
%   pose. This function measures how well each trajectory aims towards a
%   target position and orientation.
%
%   Inputs:
%       trajectories            - A 3D array (NumStates x NumVehicleStates
%                                 x NumTrajectories) of generated
%                                 trajectories where NumStates is the
%                                 number of states along the trajectory and
%                                 each slice along the third dimension
%                                 corresponds to a single trajectory.
%       targetPose              - A 1x3 vector representing the target pose
%                                 [x, y, theta] that the trajectories are
%                                 trying to follow.
%       weightXY                - A scalar specifying the weight of the XY
%                                 distance in the cost calculation. Default
%                                 is 1.
%       weightTheta             - A scalar specifying the weight of the
%                                 angular difference in the cost
%                                 calculation. Default is 1.
%
%   Outputs:
%       cost                    - A column vector (NumTrajectories x 1)
%                                 where each element represents the
%                                 calculated cost for the corresponding
%                                 trajectory.
%
%   The cost for each trajectory is computed as the sum of squared
%   distances from the trajectory points to the target position (x, y) and
%   the sum of squared angular differences from the trajectory orientations
%   to the target orientation (theta).
%
%   Example:
%       % Define target pose
%       targetPose = [5, 5, pi/2];
%       % Compute cost for a set of trajectories for given targetPose
%       cost = nav.algs.mppi.pathFollowingCost(trajectories, targetPose);
%
%   See also controllerMPPI, pathAlignmentCost, controlSmoothingCost.

% Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        trajectories (:,:,:) double {isValidMatrixDimensions(trajectories)}
        targetPose (1,3) double
        weightXY (1,1) double = 1;
        weightTheta (1,1) double = 1;
    end

    % Compute distance from trajectories to the target pose
    stateDiff = trajectories(:,1:3,:) - targetPose;
    stateDiff(:,3,:) = robotics.internal.wrapToPi(stateDiff(:,3,:));
    dist = weightXY*stateDiff(:,1,:).^2 + weightXY*stateDiff(:,2,:).^2 + weightTheta*stateDiff(:,3,:).^2;

    % Sum distances for each trajectory
    cost = sum(dist, 1);
    cost = cost(:);
end


function isValidMatrixDimensions(matrix)

% Check the number of dimensions
    numDims = ndims(matrix);

    % Validate the number of dimensions
    coder.internal.errorIf(numDims~=3,'shared_nav_offroad:controllermppi:InvalidTrajectoriesDimension');
end
