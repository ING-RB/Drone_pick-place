function checkGoalTolerance(gtol, poseDim, sourceName)
%checkGoalTolerance(gtol, poseDim, sourceName)

%#codegen


% Copyright 2017-2018 The MathWorks, Inc.

validateattributes(gtol, {'single','double'}, ...
    {'row', 'numel', poseDim, 'real', 'nonsparse', 'finite', 'nonnegative'}, ...
    sourceName, 'GoalTolerance');
end
