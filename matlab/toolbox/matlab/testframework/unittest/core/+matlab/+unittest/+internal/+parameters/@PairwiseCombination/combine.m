function combined = combine(~, parameters)
% combine - Combine to cover all pairs of parameter values.
%
%   Reference:
%   Kuo-Chung Tai and Yu Lei, "A Test Generation Strategy for Pairwise Testing,"
%   IEEE Transactions on Software Engineering, vol. 28, no. 1, pp. 109-111, 2002.

% Copyright 2020 The MathWorks, Inc.

import matlab.unittest.internal.parameters.combineAccordingToIndices;

parameterSizes = cellfun(@numel, parameters);
numParameters = numel(parameters);

if numParameters < 2
    % Nothing to combine
    combinedIdx = (1:parameterSizes).';
else
    % Start by generating all pairs of the first two parameters
    [X, Y] = meshgrid(1:parameterSizes(1), 1:parameterSizes(2));
    combinedIdx = [X(:), Y(:)];
end

% Loop over the remaining parameters and add pairs. For each loop
% iteration, add rows/columns to cover all pairs of existing parameters
% with the parameter being introduced that iteration.
for parameterIdx = 3:numParameters
    numValsCurrentParam = parameterSizes(parameterIdx);
    numExistingParameters = parameterIdx - 1;
    
    % Define masks to keep track of which pairs have been covered.
    % uncovered{i}(j,k) tells us whether parameter i, value j has been
    % paired with the current parameter (referred to by parameterIdx), value k.
    uncovered = arrayfun(@(rows)true(rows,numValsCurrentParam), ...
        parameterSizes(1:numExistingParameters), 'UniformOutput',false);
    
    % Horizontal and Vertical growth
    [combinedIdx, uncovered] = horizontalGrowth(parameterIdx, ...
        parameterSizes, combinedIdx, uncovered);
    growth = verticalGrowth(parameterIdx, uncovered);
    combinedIdx = [combinedIdx; growth]; %#ok<AGROW>
end

% Any remaining unused slots can be filled with any value. Use row and
% column indices to generate values deterministically but with some variety.
for row = 1:size(combinedIdx,1)
    for col = 1:numParameters
        if combinedIdx(row,col) == 0
            combinedIdx(row,col) = mod(row+col, parameterSizes(col)) + 1;
        end
    end
end

% Use the generated indices to create the specific parameter realizations
combined = combineAccordingToIndices(parameters, combinedIdx);
end

function [combinedIdx, uncovered] = horizontalGrowth(whichParam, paramSizes, combinedIdx, uncovered)
% horizontalGrowth - Extend pairwise coverage for an additional parameter

numVals = paramSizes(whichParam);
numExistingParameters = whichParam - 1;

% Append parameters in order
for currentParamIdx = 1:min(numVals, size(combinedIdx,1))
    combinedIdx(currentParamIdx, whichParam) = currentParamIdx;
    
    % Record covered pairs
    for existingParamIdx = 1:numExistingParameters
        % Because we are just now introducing a new parameter, we can
        % increase coverage by filling in any empty slots with any value.
        if combinedIdx(currentParamIdx, existingParamIdx) == 0
            combinedIdx(currentParamIdx, existingParamIdx) = ...
                mod(currentParamIdx+existingParamIdx, paramSizes(existingParamIdx)) + 1;
        end
        
        uncovered{existingParamIdx}(combinedIdx(currentParamIdx, existingParamIdx), ...
            combinedIdx(currentParamIdx, whichParam)) = false;
    end
end

% For the remaining parameters, add the parameter value to each row that
% will cover the maximum number of uncovered pairs
for combIdx = numVals+1:size(combinedIdx,1)
    [coverage, emptySlotsUsed] = getParameterCoverage(combinedIdx(combIdx,:), numVals, uncovered);
    maxCoverage = max(coverage);
    if maxCoverage == 0
        % No coverage to be gained; leave open for future use
        continue;
    end
    
    % Handle ties by choosing the value that leaves the most empty slots
    % open for future use.
    maxCoverageIdx = find(coverage == maxCoverage);
    [~, minSlotsUsedIdx] = min(emptySlotsUsed(maxCoverageIdx));
    maxCoverageIdx = maxCoverageIdx(minSlotsUsedIdx);
    
    % Add and record the value
    combinedIdx(combIdx, whichParam) = maxCoverageIdx;
    for existingParamIdx = 1:numExistingParameters
        idx = combinedIdx(combIdx,existingParamIdx);
        if idx ~= 0
            uncovered{existingParamIdx}(idx, maxCoverageIdx) = false;
        end
    end
    
    % Fill in any empty slots that provide additional coverage
    for existingParamIdx = 1:numExistingParameters
        if combinedIdx(combIdx, existingParamIdx) == 0
            idx = combinedIdx(combIdx, whichParam);
            addIdx = find(uncovered{existingParamIdx}(:,idx));
            
            % If addIdx is empty, we already have maximum coverage and the
            % slot should be left open for future use.
            if ~isempty(addIdx)
                % Tie-break: use the parameter value with the most
                % uncovered pairs left to go.
                [~, maxValuesIdx] = max(sum(uncovered{existingParamIdx}(addIdx,:),2));
                addIdx = addIdx(maxValuesIdx);
                
                % Fill the slot and record the covered pair.
                combinedIdx(combIdx, existingParamIdx) = addIdx;
                uncovered{existingParamIdx}(addIdx, idx) = false;
            end
        end
    end
end
end

function [coverage, emptySlotsUsed] = getParameterCoverage(combRow, numVals, uncovered)
% getParameterCoverage - Determine how many uncovered pairs would be covered
%   as a result of choosing each value for the parameter in the last column.
%   Also determine the number of empty "don't care" slots used in each case.

coverage = zeros(1, numVals);
emptySlotsUsed = zeros(1, numVals);

% Loop over all existing parameters
for paramIdx = 1:numel(combRow) - 1
    idx = combRow(paramIdx);
    if idx == 0
        % For empty slots, see if any possible pair would result in
        % additional coverage.
        newCoverage = any(uncovered{paramIdx});
        coverage = coverage + newCoverage;
        
        % Keep track of how many empty slots we have to use because we want
        % to avoid filling unused slots in tie-break scenarios.
        emptySlotsUsed = emptySlotsUsed + newCoverage;
    else
        % For already filled slots, check if each pair is uncovered.
        coverage = coverage + uncovered{paramIdx}(idx, :);
    end
end
end

function growth = verticalGrowth(whichParam, uncovered)
% verticalGrowth - Generate minimum number of new rows to cover parameters

growth = zeros(0, whichParam);

% Loop over all existing parameters
for paramIdx = 1:whichParam-1
    % Find all the uncovered pairs for this parameter
    [p1, p2] = find(uncovered{paramIdx});
    
    for pairIdx = 1:numel(p1)
        openSlot = find((growth(:,paramIdx)==0) & (growth(:,whichParam)==p2(pairIdx)), 1, 'first');
        
        if isempty(openSlot)
            % No empty slot; need to grow. Zero is "empty" placeholder.
            growth(end+1, [paramIdx, whichParam]) = [p1(pairIdx), p2(pairIdx)]; %#ok<AGROW>
        else
            % Fill in the empty slot
            growth(openSlot, paramIdx) = p1(pairIdx);
        end
    end
end
end

% LocalWords:  Kuo Tai Yu
