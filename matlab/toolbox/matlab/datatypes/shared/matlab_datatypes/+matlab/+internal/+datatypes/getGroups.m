function grprows = getGroups(group,numgroups)
%GETGROUPS Collect row indices within groups.
%   GRPROWS = GETGROUPS(GROUP,NUMGROUPS) returns a NUMGROUPS-by-1 cell array
%   whose I-th cell contains the index vector FIND(GROUP == I), i.e. a list of
%   the elements of GROUP corresponding to the I-th group. GROUP is a numeric
%   vector of group indices.

%   Copyright 2014-2020 The MathWorks, Inc.

[sgroup,sgidx] = sort(group); % presort so accumarray doesn't have to
nonNaN = ~isnan(sgroup);

if isempty(sgroup) || ~any(nonNaN)
    grprows = cell(numgroups,1);
else
    grprows = accumarray(sgroup(nonNaN),sgidx(nonNaN),[numgroups,1],@(x){x});
end
