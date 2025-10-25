function index = getDefaultGroupingVarIndex(T)
% Given a table or timetable, return the index of the variable to be used
% as the default grouping variable. If T is a timetable, index is offset by
% 1. Intended for use by ComputeByGroupTask and PivotTableTask
%
% FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
% Its behavior may change, or it may be removed in a future release.

%   Copyright 2023-2024 The MathWorks, Inc.

n = width(T);
isTT = istimetable(T);
catVars = matches(T.Properties.VariableTypes,"categorical");
if any(catVars)
    % If there are any categoricals, return the index of the one with the
    % fewest categories
    numCats = inf(n,1);
    for k = 1:n
        if catVars(k)
            var = T.(k);
            numCats(k) = numel(categories(var));
        end
    end
    [~,index] = min(numCats);
    % if T is a timetable, shift by 1 to account for RowTimes
    index = index + isTT;
elseif isTT
    % No categoricals, but we have a timetable, so use rowtimes
    index = 1;
else
    % Return the index for the variable with the fewest unique elements
    numUniqueElements = zeros(n,1);
    for k = 1:n
        var = T.(k);
        numUniqueElements(k) = numel(unique(var));
    end
    [~,index] = min(numUniqueElements);
end