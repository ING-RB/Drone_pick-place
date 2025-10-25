function valueWithBackTicks = addBackTicks(value)
% This function adds back-ticks to the input value. This is required for user
% inputs when generating code. It prevents the live editor from renaming the input

% Copyright 2021 The MathWorks, Inc.

valueWithBackTicks = ['`', value, '`'];
end
