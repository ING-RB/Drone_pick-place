function varargout = quickIsmemberRows(x, y)
% A wrapper around ismember(..,'rows') that opportunistically uses the
% non-row version where possible for performance reasons.

%   Copyright 2018 The MathWorks, Inc.

% TODO(g1779243): This should be removed once ismember(..,'rows') matches
% the performance of ismember for column vectors.

if iscolumn(x) && ~(istable(x) || istimetable(x))
    [varargout{1:nargout}] = ismember(x, y);
else
    [varargout{1:nargout}] = ismember(x, y, 'rows');
end
end
