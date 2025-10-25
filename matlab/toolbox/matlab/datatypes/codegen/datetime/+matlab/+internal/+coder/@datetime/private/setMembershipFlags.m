function [rows,sorted] = setMembershipFlags(varargin) %#codegen
% SETMEMBERSHIPFLAGS Find 'rows' and 'stable' in the varargin provided to
% datetime's INTERSECT, SETDIFF, SETXOR, UNION, and UNIQUE. We do not need
% to error here for invalid flags, because we later forward varargin to the
% numeric versions of these functions

%   Copyright 2019 The MathWorks, Inc.

rows = false; % the defaults are not 'rows'
sorted = true; % the defaults are 'sorted'

for k = 1:numel(varargin)
    argk = varargin{k};
    % Check the type first so that strlength does not error out.
    if ((ischar(argk) && isrow(argk)) || isStringScalar(argk))
        lenk = strlength(argk);
        if strncmpi(argk,'rows',max(lenk,1))
            rows = true;
        elseif strncmpi(argk,'stable',max(lenk,2)) % 'stable' or 'sorted'
            sorted = false;
        end
    end
end
