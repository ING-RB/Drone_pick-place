function flag = setmembershipFlagChecks(varargin)
%SETMEMBERSHIPFLAGCHECKS Utility for table set function methods.

%   Copyright 2012-2019 The MathWorks, Inc.

% The matlab set membership functions allow a max of two extra flags, and the
% calls to those in the table set membership methods use up one of them for
% 'rows'.  Do flag error checking here to give helpful errors instead of
% throwing MATLAB:narginchk:tooManyInputs.

% Ignore 'rows', it's always implied, but accepted anyway.  Other than that,
% accept only 'stable' or 'sorted'.  Do not accept 'R2012a' or 'legacy', or
% both 'stable' and 'sorted', or anything else.

try
    varargin = tabular.processSetMembershipFlags(varargin{:});
catch ME
    matlab.internal.datatypes.throwInstead(ME, ...
        "MATLAB:table:setmembership:UnknownInput2", ...
        "MATLAB:table:setmembership:UnknownInput");
end

if isempty(varargin)
    flag = 'sorted';
else
    flagVals =  {'stable' 'sorted'};
    flagCount = [ 0        0      ];
    for i = 1:numel(varargin)
        foundFlag = startsWith(flagVals,varargin{i},"IgnoreCase",true);
        if sum(foundFlag) == 1
            % Matches exactly one value
            flag = flagVals{foundFlag};
            flagCount(foundFlag) = flagCount(foundFlag) + 1;
        else
            % Error if the input flag matches both (i.e ambiguous match) or none
            % of the two accepted values.
            error(message('MATLAB:table:setmembership:UnknownFlag',varargin{i}));
        end
    end
    % Check for repeated or conflicting flags
    if flagCount(1) > 0 && flagCount(2) > 0
        error(message('MATLAB:table:setmembership:SetOrderConflict'));
    elseif flagCount(1) > 1 % repeated stable
        error(message('MATLAB:table:setmembership:RepeatedFlag','stable'));
    elseif flagCount(2) > 1 % repeated sorted
        error(message('MATLAB:table:setmembership:RepeatedFlag','sorted'));
    end
end
end
