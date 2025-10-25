function [state1, state2, weight] = validateDistanceFcnInputs(distanceFcn, state1, state2, weight)
%This function is for internal use only. It may be removed in the future.

%validateDistanceFcnInputs Validate inputs to the distance functions
%   The distanceFcn argument is a string or char array input representing
%   nav.algs.distanceEuclidean, nav.algs.distanceEuclideanSquared or
%   nav.algs.distanceManhattan whose inputs state1, state2 and weight
%   are being validated

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Validate state1 input
validateattributes(state1, {'single', 'double'}, {'nonempty', 'real'},...
    distanceFcn, 'state1');

% Validate state2 input and also column size
stateSize = size(state1, 2);
validateattributes(state2, {'single', 'double'}, {'nonempty', 'real',...
    'size', [nan, stateSize]}, distanceFcn, 'state2');

% Get number of states
s1 = size(state1, 1);
s2 = size(state2, 1);

% Validate shapes of state1 and state2 inputs when both are matrices i.e.,
% one of them is not a row vector
if s1~=1 && s2~=1
    validateattributes(state2, {'single', 'double'}, {'size', [height(state1), stateSize]}, ...
        distanceFcn, 'state2');
end

% Validate the weight input if provided
if nargin==4
    validateattributes(weight, {'single', 'double'},...
        {'nonempty', 'real', 'nonnegative', 'size', [1 stateSize]}, ...
        distanceFcn, 'weight');    
end

% Expected datatype of the output
outClass = superiorfloat(state1, state2);
if nargin==4
    outClass = superiorfloat(state1, state2, weight);
end

% Cast variables to the expected data type of the output
state1 = cast(state1, outClass);
state2 = cast(state2, outClass);
if nargin==4
    weight = cast(weight, outClass);
end