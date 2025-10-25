function names = rowChoices(t)
% Return a sorted list of a table's row names, possibly empty.

%   Copyright 2020 The MathWorks, Inc.

% Return these sorted case-insensitively.
names = matlab.internal.datatypes.functionSignatures.sorti(t.Properties.RowNames);
