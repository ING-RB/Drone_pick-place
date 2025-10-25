function names = commonVarChoices(t1,t2)
% Return a sorted list of common var names shared by two tables.

%   Copyright 2020 The MathWorks, Inc.

t1Names = t1.Properties.VariableNames;
t2Names = t2.Properties.VariableNames;

% intersect sorts case-sensitively, return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(intersect(t1Names, t2Names));
