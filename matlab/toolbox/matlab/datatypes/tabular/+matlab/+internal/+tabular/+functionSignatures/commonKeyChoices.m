function names = commonKeyChoices(t1,t2)
% Return a sorted list of common var names (and common row dim names if applicable) shared by two tables.

%   Copyright 2017-2020 The MathWorks, Inc.

% Return the common row dim name only if both tabulars have row labels: all
% timetables, but only some tables
t1SuggestRowDimName = isa(t1,'timetable') || ~isempty(t1.Properties.RowNames);
t2SuggestRowDimName = isa(t2,'timetable') || ~isempty(t2.Properties.RowNames);

if t1SuggestRowDimName
    t1Names = [t1.Properties.DimensionNames{1} t1.Properties.VariableNames];
else
    t1Names = t1.Properties.VariableNames;
end

if t2SuggestRowDimName
    t2Names = [t2.Properties.DimensionNames{1} t2.Properties.VariableNames];
else
    t2Names = t2.Properties.VariableNames;
end

% intersect sorts case-sensitively, return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(intersect(t1Names, t2Names));
