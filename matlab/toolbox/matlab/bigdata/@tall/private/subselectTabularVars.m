function tB = subselectTabularVars(tA, varIdx)
% SUBSELECTTABULARVARS Returns a new table/timetable that only contains the
% selected variables and their corresponding properties.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2022 The MathWorks, Inc.

sz = size(tA);
subs = substruct('()', {':', varIdx});
tB = tA.Adaptor.subsrefParens(tA.ValueImpl, sz.ValueImpl, subs);