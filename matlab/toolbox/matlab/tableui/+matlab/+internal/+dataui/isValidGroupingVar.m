function issupported = isValidGroupingVar(g,enforceColumn)
% Determine whether input G is a valid grouping variable. By default, the
% grouping variable must be a column vector. Set ENFORCECOLUMN to false if
% grouping variables need not be columns (e.g. array inputs to groupsummary).
%
% For use in ComputeByGroupTask and PivotTableTask
%
% FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
% Its behavior may change, or it may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.

if nargin < 2
    enforceColumn = true;
end
if enforceColumn
    issupported = iscolumn(g);
else
    issupported = true;
end

issupported = issupported && (isfloat(g) || (isinteger(g) && isreal(g)) || isduration(g) || ...
    isdatetime(g) || iscalendarduration(g) || isstring(g) || ...
    iscellstr(g) || iscategorical(g) || islogical(g) || ischar(g) || isenum(g));

end