function found = getHelpForTopics(hp, topics, forceContents)
    arguments
        hp;
        topics;
        forceContents = false;
    end
    if isempty(topics)
        found = false;
    elseif isscalar(topics) && ~forceContents
        found = getSingleTopicHelp(hp, topics{1}, false);
        hp.displayBanner = found;
    else
        found = getMultiTopicHelp(hp, topics, forceContents);
    end
end

function found = getSingleTopicHelp(hp, topic, justH1)
    hp.inputTopic = topic;
    hp.topic = topic;
    hp.fixTypos = false;
    hp.getTopicHelpText(justH1);
    found = hp.helpOnInstance || hp.helpStr ~= "";
    if ~found
        hp.topic = '';
        hp.helpStr = '';
    end
end

function found = getMultiTopicHelp(hp, topics, forceContents)
    collect = struct('topic', num2cell(topics));
    [collect(:).help] = deal('');
    [collect(:).hasHelp] = deal(false);
    [collect(:).isDir] = deal(false);
    for i = 1:numel(topics)
        topic = topics{i};
        helpStr = '';
        isDir = false;
        if forceContents
            helpStr = getFullTopicHelp(topic, hp.callerContext);
        else
            hp2 = matlab.internal.help.helpProcess(1,0);
            hp2.callerContext = hp.callerContext;
            found = getSingleTopicHelp(hp2, topic, true);
            if found
                helpStr = hp2.helpStr;
                isDir = hp2.isDir;
            end
        end
        if helpStr ~= ""
            collect(i).hasHelp = true;
            collect(i).isDir = isDir;
            collect(i).help = helpStr;
        end
    end
    collect = collect([collect.hasHelp]);
    found = ~isempty(collect);
    if found
        if isscalar(collect) && ~forceContents
            topic = char(collect.topic);
            getSingleTopicHelp(hp, topic, false);
            hp.displayBanner = true;
        else
            fullTopics = [collect.topic];
            topics = fullTopics;
            h1Topics = topics;
            if forceContents
                topics = regexpi(topics, '[^@+\\/][^\\/]*?(\.mat$)?(?=(\.\w+)?$)', 'match', 'once');
                h1Topics = erase(topics, '.mat' + textBoundary);
            end
            h1Lines = cellfun(@makeH1, {collect.help}, h1Topics, 'UniformOutput', false);

            paddedTopics = pad(topics, 'left');
            if hp.wantHyperlinks
                if any(strlength(topics)==1)
                    linkText = " " + topics + " ";
                else
                    linkText = topics;
                end
                linkedTopics = cellfun(@(link, text)string(hp.createMATLABLink(link, text)), fullTopics, linkText);
                paddedTopics = regexp(paddedTopics, '^\s*', 'match', 'once', 'emptymatch') + linkedTopics;
            end
            hp.helpStr = sprintf('%s - %s\n', string([paddedTopics; h1Lines]));
        end
    end
end

function helpStr = getFullTopicHelp(topic, callerContext)
    helpStr = '';
    helpFunction = matlab.lang.internal.introspective.getHelpFunction(topic);
    if helpFunction ~= ""
        helpStr = matlab.lang.internal.introspective.callHelpFunction(helpFunction, topic, true);
    end
    if helpStr == ""
        hp2 = matlab.internal.help.helpProcess(1,0);
        hp2.callerContext = callerContext;
        hp2.topic = topic;
        hp2.inputTopic = topic;
        hp2.fullTopic = topic;
        resolvedSymbol = matlab.lang.internal.introspective.resolveName(topic, JustChecking=false);
        hp2.elementKeyword = resolvedSymbol.elementKeyword;
        if ~isempty(resolvedSymbol.classInfo)
            hp2.extractFromClassInfo(resolvedSymbol.classInfo);
        end
        if hp2.isDir
            hp2.getFolderHelp(true);
        else
            hp2.getDefaultHelpFromSource;
            hp2.helpStr = matlab.lang.internal.introspective.containers.extractH1Line(hp2.helpStr);
        end
        helpStr = hp2.helpStr;
    end
end

function h1 = makeH1(helpStr, topic)
    h1 = strip(helpStr);
    h1 = regexprep(h1, '\s+', ' ');
    h1 = regexprep(h1, "^" + regexptranslate('escape', topic) + "\>(\.\w+)?\s*(-\s*)?", '', 'ignorecase');
end

% Copyright 2018-2024 The MathWorks, Inc.
