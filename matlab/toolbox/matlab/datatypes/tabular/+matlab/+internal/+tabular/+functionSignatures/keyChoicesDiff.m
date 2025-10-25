function names = keyChoicesDiff(t,vars,otherVars)
% Return a sorted list of a table's var names (and row dim name if applicable) NOT specified.

%   Copyright 2020 The MathWorks, Inc.

% Return the row dim name only if the tabular has row labels: all
% timetables, but only some tables
suggestRowDimName = isa(t,'timetable') || ~isempty(t.Properties.RowNames);
if suggestRowDimName
    names1 = [t.Properties.DimensionNames{1} t.Properties.VariableNames];
else
    names1 = t.Properties.VariableNames;
end

if nargin < 3
    names2 = t.Properties.VariableNames(vars);
else
    names2 = [t.Properties.VariableNames(vars) t.Properties.VariableNames(otherVars)];
end

% setdiff sorts case-sensitively, return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(setdiff(names1,names2));
