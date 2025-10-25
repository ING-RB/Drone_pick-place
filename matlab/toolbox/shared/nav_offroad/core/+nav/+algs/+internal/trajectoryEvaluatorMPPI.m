function [optimalTrajectoryInputs,solutionFound] = trajectoryEvaluatorMPPI(trajectoriesInputs,trajectoriesInputsPrev,costVector,constraintVector,lambda)
% This function is for internal use only. It may be removed in the future.

%trajectoryEvaluatorMPPI Evaluates and selects the optimal input for a set
%of trajectories based on cost & constraint vector.
%
%   [optimalTrajectoryInputs, solutionFound] =
%   TRAJECTORYEVALUATORMPPI(trajectoriesInputs, trajectoriesInputsPrev,
%   costVector) evaluates the optimal command input based on the provided
%   costVector. The function computes the weighted average of the
%   trajectory inputs, where the weights are determined by the cost
%   associated with each trajectory.
%
%   [optimalTrajectoryInputs, solutionFound] =
%   TRAJECTORYEVALUATORMPPI(trajectoriesInputs, trajectoriesInputsPrev,
%   costVector, constraintVector) additionally considers a constraintVector
%   to compute the optimal command input.
%
%   [optimalTrajectoryInputs, solutionFound] =
%   TRAJECTORYEVALUATORMPPI(trajectoriesInputs, trajectoriesInputsPrev,
%   costVector, constraintVector, lambda) allows specifying lambda, a
%   tuning parameter.
%
%   INPUTS:
%       trajectoriesInputs        : A 3D matrix of trajectory inputs, where each
%                                   "page" along the third dimension represents
%                                   a different trajectory input. 
%                                   Dimension: [NumTrajectoryStates x NumVehicleInputs x NumTrajectories]
%       trajectoriesInputsPrev    : A 2D matrix representing the previous
%                                   optimal trajectory inputs that was applied.
%                                   Dimension: [NumTrajectoryStates x NumVehicleInputs]
%       costVector                : A column vector where each element represents the cost
%                                   associated with the corresponding trajectory input.
%                                   Dimension: [NumTrajectories x 1]
%       constraintVector          : A column vector where each element
%                                   represents additional constraints to be added to the costs.
%                                   If not provided or empty, no constraints are
%                                   added to the costs. 
%                                   Dimension: [NumTrajectories x 1]
%       lambda                    : A positive scalar that determines the sharpness
%                                   of the weighting distribution. Default value is 10.
%
%   OUTPUTS:
%       optimalTrajectoryInputs   : A 2D matrix representing the inputs for
%                                   the optimal trajectory.
%                                   Dimension: [NumTrajectoryStates x NumVehicleInputs]
%       solutionFound             : A logical value indicating whether a solution was
%                                   found (true) or not (false).
%
%   EXAMPLE:
%       % Define trajectory inputs, last trajectory input, and cost vector
%       trajectoriesInputs = rand(5, 2, 10); % 10 random trajectory inputs
%       trajectoriesInputsPrev = rand(5, 2); % Last trajectory input
%       costVector = rand(10, 1); % Random cost for each trajectory input
%
%       % Evaluate the optimal command input [optimalTrajectoryInputs,
%       solutionFound] = trajectoryEvaluatorMPPI(trajectoriesInputs,
%       trajectoriesInputsPrev, costVector);
%
% Copyright 2024 The MathWorks, Inc.

%#codegen

arguments
    trajectoriesInputs {mustBeNumeric, mustBeNonNan}
    trajectoriesInputsPrev {mustBeNumeric, mustBeNonNan}
    costVector (:,1) {mustBeNumeric, mustBeNonNan}
    constraintVector (:,1) {mustBeNumeric, mustBeNonNan} = 0
    lambda (1,1) {mustBePositive} = 10
end

% Adding cost & constraints
costVector = costVector + constraintVector;

% This script calculates the weights for a set of trajectory costs
% (costVector = [C1; C2; ...CK;..]) using the softmax function. The softmax
% function is applied to the costs C1, C2, ..., CK with an inverse
% temperature λ. Equation: wk = exp(-1/λ * (Ck - ρ)) / Σ(exp(-1/λ * (Ck -
% ρ))), where ρ = min(Ck) for stability.


% Weight Computation Compute ρ, the minimum cost among all trajectories, to
% stabilize the computation.
rho = min(costVector); % extract minimum cost.

% Calculate the normalization constant η˜ as the sum of exp(-1/λ * (Ck -
% ρ)) for all k.
expWeights = exp(-(costVector-rho)/lambda); 
eta = sum(expWeights);

% Compute the weight wk for each trajectory by normalizing its adjusted cost.
if ~isinf(rho) % check if the minimum cost is not infinite.
    % The resulting weights can be used for probabilistic selection of
    % trajectories, favoring lower costs.
    weights = (1/eta)*expWeights;
    numTrajectories = size(weights,1); 
    % weighted average of all optimal trajectory inputs
    optimalTrajectoryInputs = sum(trajectoriesInputs.*reshape(weights,1,1,numTrajectories),3);
    solutionFound = true;
else
    optimalTrajectoryInputs = zeros(size(trajectoriesInputsPrev));
    solutionFound = false;
end
end
