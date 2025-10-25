function strs = replaceVariableNames(strs, oldVariableNames, newVariableNames)
%replaceVariableNames   Looks through strs and replaces old variable names
%   with the strings in newVariableNames.
%
%   Any extra variable names are added at the end.

%   Copyright 2021 The MathWorks, Inc.
    arguments
        strs (1, :) string {mustBeNonmissing}
        oldVariableNames (1, :) string {mustBeNonmissing}
        newVariableNames (1, :) string {mustBeNonmissing}
    end

    usedNewVariableNames = false(1, numel(newVariableNames));
    alreadyReplacedVariableName = false(1, numel(strs));

    for i = 1:numel(oldVariableNames)
        matchIndex = find(strs == oldVariableNames(i), 1);
        if ~isempty(matchIndex)
            % Old name was found. Perform the replacement if this variable
            % was not already replaced.
            if ~alreadyReplacedVariableName(matchIndex)
                strs(matchIndex) = newVariableNames(i);
                usedNewVariableNames(i) = true;
                alreadyReplacedVariableName(matchIndex) = true;
            end
        end
    end

    % Add all unused new variable names to strs at the end.
    strs = unique([strs newVariableNames(~usedNewVariableNames)], "stable");
end