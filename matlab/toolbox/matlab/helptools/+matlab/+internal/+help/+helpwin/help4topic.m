function [topic, helpstr, docTopic, found] = help4topic(topic, commandOption)
    [helpstr, docTopic] = help(topic, append('-', commandOption));
    found = ~isempty(helpstr);
end

%   Copyright 2020-2024 The MathWorks, Inc.
