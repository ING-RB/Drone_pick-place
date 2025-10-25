function [hasStable, hasRows] = processSetMembershipFlags(flags) %#codegen
%PROCESSSETMEMBERSHIPFLAGS Utility for categorical set function methods.

%   Copyright 2020 The MathWorks, Inc.

% In codegen, if the 'stable' flag is not supplied, then the inputs to the set
% functions need to be sorted (or row-sorted if 'rows' flag is supplied). Parse
% the input flags to determine if they contain 'rows' and 'stable'.

hasStable = false;
hasRows = false;
for i = 1:numel(flags)
    processedFlag = convertStringsToChars(flags{i});
    if strncmpi('stable', processedFlag, max(length(processedFlag), 1))
        hasStable = true;
    end
    if strncmpi('rows', processedFlag, max(length(processedFlag), 1))
        hasRows = true;
    end
end