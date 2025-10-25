function [startState, goalState] = sampleStartGoal(stateValidator, numPairs, maxAttempts)
%

% Copyright 2023 The MathWorks, Inc.

%#codegen

arguments
    stateValidator (1,1) nav.StateValidator
    numPairs (1,1) {mustBeNumeric, mustBeInteger, mustBePositive} = 1;
    maxAttempts (1,1) {mustBeNumeric, mustBeInteger, mustBePositive} = 100;
end

numSamplesToGo = numPairs*2; % Total number of valid start and goal states to be generated
stateSpace = stateValidator.StateSpace;
statesValid = nan(numSamplesToGo,stateSpace.NumStateVariables); % Preallocate the valid states

% Generate valid samples
i = 1; % index to keep track of valid state samples
for attempt = 1:maxAttempts
    statesUniform = stateSpace.sampleUniform(numSamplesToGo); % Sample states from uniform distribution
    valid = stateValidator.isStateValid(statesUniform); % Check validity of the samples
    numValid = sum(valid);
    statesValid(i:numValid+i-1,:) = statesUniform(valid,:); % Extract valid states from sampled states
    i = numValid+i;
    numSamplesToGo = numSamplesToGo - numValid; % Update remaining samples to be generated
    if numSamplesToGo <= 0
        break
    end
end

if numSamplesToGo <= 0 
    % numValidStates = 2*numPairs
    startState = statesValid(1:numPairs,:);
    goalState = statesValid(numPairs+1:end,:);
else 
    % numValidStates < 2*numPairs (maxAttempts exceeded)    
    statesValid = statesValid(~isnan(statesValid(:,1)),:);
    numPairsFound = floor(height(statesValid)/2);
    coder.internal.warning('nav:navalgs:mpnet:MaxAttemptsExceeded',numPairsFound)     
    startState = statesValid(1:numPairsFound,:);
    goalState = statesValid(numPairsFound+1:end,:);
end
