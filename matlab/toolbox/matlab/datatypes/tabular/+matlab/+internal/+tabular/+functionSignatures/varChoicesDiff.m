function names = varChoicesDiff(t,vars)
% Return a sorted list of a table's var names NOT specified.

%   Copyright 2020 The MathWorks, Inc.

names1 = t.Properties.VariableNames;
names2 = t.Properties.VariableNames(vars);

% setdiff sorts case-sensitively, return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(setdiff(names1,names2));
