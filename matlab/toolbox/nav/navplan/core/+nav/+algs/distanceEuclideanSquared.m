function dist = distanceEuclideanSquared(state1, state2, weight)
%DISTANCEEUCLIDEANSQUARED Compute squared Euclidean distance between two
%states
%
%   DIST = DISTANCEEUCLIDEANSQUARED(STATE1, STATE2) computes the distance
%   between STATE1 and STATE2. These states are n-by-m matrices, where each
%   row is a different state. The function calculates the distance between
%   each row in the two matrices and returns a vector of n distances.
%
%   DIST = DISTANCEEUCLIDEANSQUARED(STATE1, STATE2, WEIGHT) computes the
%   weighted distance where each element of weight corresponds to each
%   coordinate of the state
%
%   The function supports following combinations for distance calculation:
%       n-to-n: n number of states in states1 and n number of states in 
%               states2.
%       1-to-n: 1 state in states1 and n number of states in states2.
%       n-to-1: n number of states in states1 and 1 state in states2.
%
%   Example:
%      %  Compute Euclidean squared distance
%      state1 = rand(10, 5); 
%      state2 = rand(10, 5);   
%      dist = nav.algs.distanceEuclideanSquared(state1, state2);
%
%      %  Compute weighted Euclidean squared distance
%      state1 = rand(10, 5); 
%      state2 = rand(10, 5);   
%      weight = rand(1, 5);
%      distWeighted = nav.algs.distanceEuclideanSquared(...
%                     state1, state2, weight);
%       
%      % Compute Euclidean squared distance with one of the state inputs 
%      % being a row vector
%      state1 = rand(10, 5);
%      state2 = rand(1, 5);
%      distWithRowVector = nav.algs.distanceEuclideanSquared(...
%                          state1, state2);
%
%   See also: nav.algs.distanceEuclidean, nav.algs.distanceManhattan

% Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(2, 3)


if nargin==2
    % Validate state1 and state2 inputs
    [state1, state2] = nav.internal.validation.validateDistanceFcnInputs(...
        'nav.algs.distanceEuclideanSquared', state1, state2);     
    % Compute Euclidean squared distance
    dist = sum((state1-state2).^2, 2);
else
    % Validate state1, state2 and weight inputs
    [state1, state2, weight] = nav.internal.validation.validateDistanceFcnInputs(...
        'nav.algs.distanceEuclideanSquared', state1, state2, weight);     
    % Compute weighted Euclidean squared distance
    dist = sum(weight.*(state1-state2).^2, 2);
end

