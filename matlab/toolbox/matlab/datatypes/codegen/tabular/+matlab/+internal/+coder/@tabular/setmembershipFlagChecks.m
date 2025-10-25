function flag = setmembershipFlagChecks(varargin) %#codegen
%SETMEMBERSHIPFLAGCHECKS Utility for table set function methods.

%   Copyright 2019 The MathWorks, Inc.

% The matlab set membership functions allow a max of two extra flags, and the
% calls to those in the table set membership methods use up one of them for
% 'rows'.  Do flag error checking here to give helpful errors instead of
% throwing MATLAB:narginchk:tooManyInputs.

% Ignore 'rows', it's always implied, but accepted anyway.  Other than that,
% accept only 'stable' or 'sorted'.  Do not accept 'R2012a' or 'legacy', or
% both 'stable' and 'sorted', or anything else.

processedArgs = tabular.processSetMembershipFlags(varargin{:});

if isempty(processedArgs)
    flag = 'sorted';
else
    flagVals =  {'stable' 'sorted'};
    flagCount = [      0         0];
    for i = 1:numel(processedArgs)
        foundFlag = strncmpi(flagVals,processedArgs{i},max(length(processedArgs{i}), 1));
        % Error if the input flag matches both (i.e ambiguous match) or none
        % of the two accepted values.
        coder.internal.assert(sum(foundFlag) == 1,...
            'MATLAB:table:setmembership:UnknownFlag',processedArgs{i});
        flag = flagVals{foundFlag};
        flagCount(foundFlag) = flagCount(foundFlag) + 1;
    end
    % Check for repeated or conflicting flags
    coder.internal.errorIf(flagCount(1) > 0 && flagCount(2) > 0, ...
        'MATLAB:table:setmembership:SetOrderConflict');
    coder.internal.errorIf(flagCount(1) > 1, ...
        'MATLAB:table:setmembership:RepeatedFlag','stable');
    coder.internal.errorIf(flagCount(2) > 1, ...
        'MATLAB:table:setmembership:RepeatedFlag','sorted');
end
