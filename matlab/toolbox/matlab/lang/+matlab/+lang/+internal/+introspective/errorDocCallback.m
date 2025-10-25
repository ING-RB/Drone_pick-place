function errorDocCallback(topic, fileName, ~)
    if nargin < 2
        fileName = '';
    end
    
    split = regexp(topic, filemarker, 'split', 'once');
    hasFileMarker = numel(split) > 1;
    if hasFileMarker
        functionName = split{1};
        localFunctionName = split{2};
        if fileName == ""
            fileNameQualifiedTopic = topic;
            topicWithoutLocalFunction = functionName;
        else
            [filePath, fileShortName] = fileparts(fileName);
            fileNameQualifiedTopic = append(filePath, filesep, fileShortName, filemarker, localFunctionName);
            topicWithoutLocalFunction = fileName;
        end
    else
        functionName = topic;
        if fileName == "" || ~isempty(regexp(topic, '\W', 'once'))
            fileNameQualifiedTopic = topic;
        else
            docLinks = matlab.lang.internal.introspective.docLinks(fileName, topic, []);
            if docLinks.referencePage ~= ""
                fileNameQualifiedTopic = docLinks.referencePage;
            else
                fileNameQualifiedTopic = fileName;
            end
        end
    end
    
    if popTopicHelp(fileNameQualifiedTopic)
        return;
    end
    
    if hasFileMarker && popTopicHelp(topicWithoutLocalFunction)
        return;
    end

    className = regexp(functionName, '.*?(?=/[\w.]*$|\.\w+$)', 'match', 'once');
    if matlab.lang.internal.introspective.isClass(className)
        if popTopicHelp(className)
            return;
        end
    end
    
    helpPopup(fileNameQualifiedTopic);
end

function b = popTopicHelp(topic)
    b = help(topic, '-noDefault') ~= "";
    if b
        helpPopup(topic);
    end
end

%   Copyright 2010-2024 The MathWorks, Inc.
