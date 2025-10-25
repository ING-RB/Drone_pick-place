function t = removevars(t, vars)
%REMOVEVARS Delete variables from a tall table or timetable.
%   T2 = REMOVEVARS(T1, VARS)
%
%   See also TABLE, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

thisFcn = upper(mfilename);
if nargin < 2
    vars = [];
else
    % If two args, check that only T is tall
    tall.checkIsTall(thisFcn, 1, t);
    tall.checkNotTall(thisFcn, 1, vars);
end
% T must be tabular
t = tall.validateType(t, thisFcn, {'table', 'timetable'}, 1);

% Let subsasgn do the real work
sz = size(t);
t = subsasgnParensDeleting(t.Adaptor, t.ValueImpl, sz.ValueImpl, substruct('()', {':',vars}));

