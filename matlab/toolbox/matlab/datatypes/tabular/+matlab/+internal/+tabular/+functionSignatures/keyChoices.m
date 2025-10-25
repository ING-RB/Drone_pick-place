function names = keyChoices(t)
% Return a sorted list of a table's var names (and row dim name if applicable).

%   Copyright 2017-2020 The MathWorks, Inc.

% Return the row dim name only if the tabular has row labels: all
% timetables, but only some tables
suggestRowDimName = isa(t,'timetable') || ~isempty(t.Properties.RowNames);
if suggestRowDimName
    names = [t.Properties.DimensionNames{1} t.Properties.VariableNames];
else
    names = t.Properties.VariableNames;
end

% Return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(names);
