function cost = controlSmoothingCost(controlSequences, vehicleInputsPrev, standardDeviation, gamma)
%controlSmoothingCost Calculates the control smoothing cost for trajectory controls.
%
%   cost = nav.algs.mppi.controlSmoothingCost(controlSequences,
%   vehicleInputsPrev, standardDeviation, gamma) computes the cost
%   associated with the deviation of the generated trajectory controls from
%   the previously optimized trajectory control commands. This is used to
%   encourage smoothness in the control inputs between iterations of an
%   optimization algorithm such as Model Predictive Path Integral (MPPI).
%
%   Inputs:
%       controlSequences     - A 3D array where each slice (along the third
%                              dimension) represents control commands for
%                              a generated trajectory.
%       vehicleInputsPrev    - A 2D array representing the previously
%                               optimized trajectory control commands.
%       standardDeviation    - Standard deviation for vehicle inputs
%       gamma                - A scalar weight for the control cost.
%
%   Outputs:
%       cost          - A column vector (NumTrajectories x 1) where
%                              each element represents the calculated
%                              control smoothing cost for the corresponding
%                              trajectory.
%
%   The control cost for each trajectory is computed as the weighted sum of
%   the squared differences between the generated control commands and the
%   previously optimized control commands. The cost is scaled by a factor
%   `gamma` and the inverse of the control input standard deviation array
%   `sigma`.
%
%   Example:
%       % Compute control cost for a set of trajectory control commands
%       % given the previous optimized commands and a weight gamma
%       cost = nav.algs.mppi.controlSmoothingCost(controlSequences, vehicleInputsPrev, standardDeviation, 0.1);
%
%   See also obstacleRepulsionCost, pathAlignmentCost, pathFollowingCost.
%

% Copyright 2024 The MathWorks, Inc.

%#codegen

arguments
    controlSequences double
    vehicleInputsPrev double
    standardDeviation (1,2) double {mustBeNonnegative}
    gamma (1,1) double = 0.1
end

numStates = size(controlSequences, 1); % Number of states in each trajectory
numTraj = size(controlSequences,3); % number of trajectories
inverseSigma = diag(1./standardDeviation);

% gamma * inputsPrev * sigma^-1 * (inputsPrev-inputs)^T
controlCost3D = pagemtimes(gamma*vehicleInputsPrev*inverseSigma,...
                           pagetranspose(vehicleInputsPrev-controlSequences));

% Final control cost is the trace of each slice: controlCost3D(:,:,1),
% controlCost3D(:,:,2),...,controlCost3D(:,:,end)
diagIndices = 1:(numStates+1):numStates^2;
controlCost3Dr = reshape(controlCost3D, numStates^2, numTraj);

% Select the diagonal elements from each slice and sum them
cost = sum(controlCost3Dr(diagIndices, :), 1);
cost = cost(:);
