function names = varChoices(t,vars)
% Return a sorted list of a table's var names, or specified var names.

%   Copyright 2020 The MathWorks, Inc.

if nargin == 1
    names = t.Properties.VariableNames;
else
    names = t.Properties.VariableNames(vars);
end

% Return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(names);
