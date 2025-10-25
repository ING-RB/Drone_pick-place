function varargin = processSetMembershipFlags(varargin)
%SETMEMBERSHIPFLAGCHECKS Utility for table set function methods.

%   Copyright 2018-2024 The MathWorks, Inc.

% The matlab set membership functions allow a max of two extra flags, and the
% calls to those in the table set membership methods use up one of them for
% 'rows'.  Do flag error checking here to give helpful errors instead of
% throwing MATLAB:narginchk:tooManyInputs.

% Ignore 'rows', it's always implied, but accepted anyway.  Other than that,
% accept only 'stable' or 'sorted'.  Do not accept 'R2012a' or 'legacy', or
% both 'stable' and 'sorted', or anything else.


[varargin{1:numel(varargin)}] = convertStringsToChars(varargin{:});
if ~matlab.internal.datatypes.isCharStrings(varargin)
    error(message('MATLAB:table:setmembership:UnknownInput2'));
end

matchesRows = false(numel(varargin)); %#ok<MNUML>
for i = 1:numel(varargin)
    matchesRows(i) = startsWith("rows",varargin{i},'IgnoreCase',true);
    % Do not accept 'R2012a' or 'legacy'.
    if matches(varargin{i}, ["legacy", "R2012a"], "IgnoreCase", true)
        error(message('MATLAB:table:setmembership:BehaviorFlags'));
    end
end
% Remove 'rows' from the flags if present.  It's always implied, but accept it anyway.
varargin(matchesRows) = [];

end
