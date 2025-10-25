function [dataVars,dvSets] = checkMultDataVariables(T,dataVars,varNamesT,numMethodInput)
% checkMultDataVariables Validate and figure out sets of mulitple data 
% variable inputs for when the method can accept more than one input.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2020-2022 The MathWorks, Inc.

% Each element of dvValues contains the all the variables for one input to
% the method.  It needs to be stored as a cell since we do scalar expansion
dvValues = cell(1,numMethodInput);
for j = 1:numMethodInput
    dvValues{1,j} = matlab.internal.math.checkDataVariables(T, dataVars{j}, "groupsummary", "Data");
end

% Make sure that all cell elements of dataVars have the same number of
% inputs or are scalars
numDVSets = unique(cellfun(@numel,dvValues));
if numel(numDVSets) > 2 || (numel(numDVSets) == 2 && numDVSets(1) ~= 1)
    error(message("MATLAB:groupsummary:DataVariablesCellNumElements"));
end
numDVSets = max(numDVSets);

% Determine the sets of method inputs and store the sets as rows of matrix
dvSets = zeros(numDVSets,numMethodInput);
for j = 1:numMethodInput
    if isscalar(dvValues{1,j})
        dvSets(:,j) = repmat(dvValues{1,j},numDVSets,1);
    else
        dvSets(:,j) = dvValues{1,j};
    end
end

% Uniqueify the sets of method inputs 
dvSets = unique(dvSets,"rows","stable");
numDVSets = size(dvSets,1);

% Concatenate the variable names for each set of method inputs
dataVars = strings(1,numDVSets);
for j = 1:numDVSets
    dataVars(1,j) = varNamesT(dvSets(j,1));
    for k = 2:numMethodInput
        dataVars(1,j) = dataVars(1,j) + "_" + varNamesT(dvSets(j,k));
    end
end

% Transpose dvSets since groupsummary wants the sets of method inputs
% stored as columns.
dvSets = dvSets';
