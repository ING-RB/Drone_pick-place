function checkIds = findFixableCheckIds(obj)
%findFixableCheckIds   search the Issues table in codeIssues
% to find check IDs which have a Fixability of auto

%   Copyright 2023 The MathWorks, Inc.

    resultFixable = obj.Issues(obj.Issues.Fixability=="auto", :);
    checkIds = unique(string(resultFixable{:, "CheckID"}));
end