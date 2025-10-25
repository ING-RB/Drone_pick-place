function dist = distanceManhattan(state1, state2, weight)
%DISTANCEMANHATTAN Compute Manhattan distance between two states
%
%   DIST = DISTANCEMANHATTAN(STATE1, STATE2) computes the distance between
%   STATE1 and STATE2. These states are n-by-m matrices, where each row is
%   a different state. The function calculates the distance between each
%   row in the two matrices and returns a vector of n distances.
%
%   DIST = DISTANCEMANHATTAN(STATE1, STATE2, WEIGHT) computes the weighted
%   distance where each element of weight corresponds to each coordinate of
%   the state.
%
%   The function supports following combinations for distance calculation:
%       n-to-n: n number of states in states1 and n number of states in 
%               states2.
%       1-to-n: 1 state in states1 and n number of states in states2.
%       n-to-1: n number of states in states1 and 1 state in states2.
%
%   Example:
%      %  Compute Manhattan distance
%      state1 = rand(10, 5); 
%      state2 = rand(10, 5);   
%      dist = nav.algs.distanceManhattan(state1, state2);
%
%      %  Compute Manhattan distance
%      state1 = rand(10, 5); 
%      state2 = rand(10, 5);   
%      weight = rand(1, 5);
%      distWeighted = nav.algs.distanceManhattan(state1, state2, weight);
%       
%      % Compute Manhattan distance with one of the state inputs being a
%      % row vector
%      state1 = rand(10, 5);
%      state2 = rand(1, 5);
%      distWithRowVector = nav.algs.distanceManhattan(state1, state2);
%
%   See also: nav.algs.distanceEuclidean, nav.algs.distanceEuclideanSquared

% Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(2, 3)

if nargin==2
    % Validate state1 and state2 inputs
    [state1, state2] = nav.internal.validation.validateDistanceFcnInputs(...
        'nav.algs.distanceManhattan', state1, state2);     
    % Compute Manhattan distance
    dist = sum(abs(state1-state2), 2);
else
    % Validate state1, state2 and weight inputs
    [state1, state2, weight] = nav.internal.validation.validateDistanceFcnInputs(...
        'nav.algs.distanceManhattan', state1, state2, weight);     
    % Compute weighted Manhattan distance
    dist = sum(weight.*abs(state1-state2), 2);
end
