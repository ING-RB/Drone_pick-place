function cost = pathAlignmentCost(trajectories, pathSegment, weightXY, weightTheta)
%pathAlignmentCost Calculates the cost for trajectory alignment with a given path segment.
%
%   cost = nav.algs.mppi.pathAlignmentCost(trajectories, pathSegment,
%   weightXY, weightTheta) computes the cost associated with each
%   trajectory based on the minimum distance and angular deviation from a
%   series of poses defining a path segment. The function evaluates how
%   well each trajectory aligns with the given path segment for the purpose
%   of path following in trajectory optimization algorithms.
%
%   Inputs:
%       trajectories            - A 3D array (NumStates x NumVehicleStates
%                                 x NumTrajectories) of generated
%                                 trajectories where NumStates is the
%                                 number of states along the trajectory and
%                                 each slice along the third dimension
%                                 corresponds to a single trajectory.
%       pathSegment             - A 2D array where each row represents a
%                                 pose [x, y, theta] along the path segment.
%       weightXY                - A scalar specifying the weight of the XY
%                                 distance in the cost calculation. Default
%                                  is 1.
%       weightTheta             - A scalar specifying the weight of the
%                                 angular difference in the cost
%                                 calculation. Default is 0.1.
%   Outputs:
%       cost                    - A column vector (NumTrajectories x 1)
%                                 where each element represents the
%                                 calculated cost for the corresponding
%                                 trajectory.
%
%   The cost for each trajectory is computed as the minimum squared
%   distance from the trajectory points to each pose in the path segment
%   and the minimum squared angular difference from the trajectory
%   orientations to the orientations of each pose in the path segment. The
%   overall cost is the mean of these minimum values across all trajectory
%   points.
%
%   Example:
%       % Define a path segment with a series of poses
%       pathSegment = [0, 0, 0; 1, 1, pi/4; 2, 2, pi/2];
%       % Compute cost for a set of trajectories and given Path Segment.
%       cost = nav.algs.mppi.pathAlignmentCost(trajectories, pathSegment);
%
%   See also controllerMPPI, pathFollowingCost, controlSmoothingCost.
%

% Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        trajectories (:,:,:) double {isValidMatrixDimensions(trajectories)}
        pathSegment (:,3)  double {mustBeNonempty}
        weightXY (1,1) double = 1;
        weightTheta (1,1) double = 0.1;
    end

    numPathSegment = size(pathSegment,1); % Number of states in path segment

    pathSegmentTr = reshape(transpose(pathSegment),[1,3,numPathSegment]);

    % Distance from all poses on the trajectory to all poses on the path
    % segments
    dx = squeeze(trajectories(:,1,:))-pathSegmentTr(:,1,:);
    dy = squeeze(trajectories(:,2,:))-pathSegmentTr(:,2,:);
    dtheta = squeeze(trajectories(:,3,:))-pathSegmentTr(:,3,:);
    dtheta = robotics.internal.wrapToPi(dtheta);
    dist = weightXY * (dx.*dx + dy.*dy) + weightTheta * (dtheta.*dtheta); %[numStates, numTraj, numPathSegment]

    % Distance from trajectory poses to the closest pose on the pathSegment
    dist = min(dist,[],3);

    % Compute average cost for each trajectory
    cost = mean(dist,1);
    cost = cost(:);
end

function isValidMatrixDimensions(matrix)

% Check the number of dimensions
    numDims = ndims(matrix);

    % Validate the number of dimensions
    coder.internal.errorIf(numDims~=3,'shared_nav_offroad:controllermppi:InvalidTrajectoriesDimension');
end
