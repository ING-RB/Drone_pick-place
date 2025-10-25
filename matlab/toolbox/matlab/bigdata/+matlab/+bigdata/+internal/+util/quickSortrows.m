function [x, varargout] = quickSortrows(x)
% A wrapper around sortrows that opportunistically uses sort instead where
% possible for performance reasons.

%   Copyright 2018-2020 The MathWorks, Inc.

% TODO(g1779243): This should be removed once sortrows matches the
% performance of sort for column vectors.

if iscolumn(x) && ~(istable(x) || istimetable(x))
    [x, varargout{1:nargout-1}] = sort(x);
elseif istimetable(x)
    % Sort timetable specifying row times and variable names, otherwise it
    % will only consider row times.
    timeAndVars = [x.Properties.DimensionNames(1), x.Properties.VariableNames];
    [x, varargout{1:nargout-1}] = sortrows(x, timeAndVars);
else
    [x, varargout{1:nargout-1}] = sortrows(x);
end
end
