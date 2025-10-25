function [foundTopic, foundVar, topic] = getClassNameFromWS(topic, wsVariables, ignoreCase)
%

%   Copyright 2020-2024 The MathWorks, Inc.

    foundTopic = topic;
    [topicParts, delimiters] = regexp(topic, '\W', 'split', 'match', 'once');
    if ~isDriveLetter(topicParts, delimiters, ignoreCase) && ~fileExists(topicParts, topic)
        [className, topicParts{1}, foundVar] = matlab.internal.help.getClassNameFromVariable(topicParts{1}, wsVariables, ignoreCase);
    else
        foundVar = false;
    end
    if foundVar
        topic = strjoin(topicParts, delimiters);
        topicParts{1} = className;
        foundTopic = strjoin(topicParts, delimiters);
    end
end

function b = isDriveLetter(topicParts, delimiters, ignoreCase)
    b = ispc && delimiters == ":" && ~isempty(matlab.lang.internal.introspective.hashedDirInfo(append(topicParts{1}, ':'), ~ignoreCase));
end

function b = fileExists(topicParts, topic)
    b = ~isscalar(topicParts) && exist(topic, 'file');
end
