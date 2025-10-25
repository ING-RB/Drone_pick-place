function grprows = getGroups(group,numgroups)  %#codegen
%GETGROUPS Collect row indices within groups.
%   GRPROWS = GETGROUPS(GROUP,NUMGROUPS) returns a NUMGROUPS-by-1 cell array
%   whose I-th cell contains the index vector FIND(GROUP == I), i.e. a list of
%   the elements of GROUP corresponding to the I-th group. GROUP is a numeric
%   vector of group indices.

%   Copyright 2020 The MathWorks, Inc.

% assume the groups are 1:numgroups
[sgroup,sgidx] = sort(group); 
grprows = cell(numgroups,1);
for i = 1:numel(grprows)
    grprows{i} = sgidx(sgroup==i);
end

