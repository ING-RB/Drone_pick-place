function [data,I,J,reord] = setMembershipSort(data,i,j,rows) %#codegen
%SETMEMBERSHIPSORT
%   This function is called by set membership functions
%   (unique,intersect,setdiff,setxor) to handle datetimes pre-1970, with
%   fractional seconds below milliseconds. The default sort behavior used
%   by base unique does not work correctly in such cases. Need to resort
%   with ComparisonMethod real.

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin == 2
    rows = i;
elseif nargin == 3
    rows = j;
end

if rows
    [data,reord] = sortrows(data,'ComparisonMethod','real');
else
    [data,reord] = sort(data,'ComparisonMethod','real');
end

if nargin == 2 % [data,reord] = setMembershipSort(data,rows)
    I = reord;
elseif nargin == 3 % [data,i,reord] = setMembershipSort(data,i,rows)
    I = i(reord);
    J = reord;
else % [data,i,j,reord] = setMembershipSort(data,i,j,rows)
    I = i(reord);
    J = j(reord);
end
