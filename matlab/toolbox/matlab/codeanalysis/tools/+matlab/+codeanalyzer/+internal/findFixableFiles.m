function fixableFiles = findFixableFiles(obj, checkIds)
%findFixableCheckIds   search the Issues table in codeIssues
% to find check IDs which have a Fixability of auto
% and the files where those check IDs were found.
%
%   Copyright 2023 The MathWorks, Inc.

    resultFixable = obj.Issues(obj.Issues.Fixability=="auto", :);
    resultCheckIds = table.empty();
    for i=1:length(checkIds)
        resultCheckIds = [resultCheckIds; resultFixable(resultFixable.CheckID==checkIds(i), :)]; %#ok<AGROW>
    end
    fixableFiles = unique(string(resultCheckIds{:, "FullFilename"}));
end