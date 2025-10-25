function getTopicHelpText(hp, justH1, resolveOverqualified)
    arguments
        hp;
        justH1 = false;
        resolveOverqualified = true;
    end
    [hp.topic, hasLocalFunction, shouldLink, ~, ~, helpFunction] = matlab.lang.internal.introspective.fixLocalFunctionCase(hp.topic);

    if hasLocalFunction && shouldLink
        hp.fullTopic = hp.topic;
    else
        [resolvedSymbol, malformed]  = matlab.lang.internal.introspective.resolveName(hp.topic, JustChecking=hp.justChecking, IntrospectiveContext=hp.callerContext, FixTypos=hp.fixTypos, ResolveOverqualified=resolveOverqualified);

        if resolvedSymbol.isResolved && ~resolvedSymbol.isCaseSensitive && hp.commandIsHelp && ~hp.fixTypos
            return;
        end

        if resolvedSymbol.isUnderqualified
            hp.docLinks = matlab.lang.internal.introspective.docLinks('', hp.inputTopic, []);
        end

        if hp.docLinks.productName == ""
            classInfo = extractFromResolvedSymbol(hp, resolvedSymbol);
        else
            classInfo = [];
        end

        preferSingleSource = matlab.internal.help.preferSingleSource(resolvedSymbol.nameLocation);

        if preferSingleSource && hp.getHelpTextFromDoc(classInfo, justH1, false)
            getOrAppendFolderHelp(hp, justH1);
            return;
        end

        if isempty(classInfo)
            if ~hp.isBuiltin && ~resolvedSymbol.isUnderqualified
                [hp.topic, ~, hp.fullTopic, helpFunction] = matlab.lang.internal.introspective.fixFileNameCase(hp.topic, '', hp.fullTopic, hp.callerContext.FullFileName);

                if malformed
                    return;
                end
            end
        else
            hp.getHelpFromClassInfo(classInfo, justH1);
            getAlternateSourcedHelp(hp, classInfo, justH1);
            return;
        end
    end
    if ~hp.isInaccessible && helpFunction ~= ""
        callHelpFunction(hp, helpFunction, justH1);
    end

    getAlternateSourcedHelp(hp, [], justH1);

    if hp.helpStr ~= "" && ~hasLocalFunction
        postprocessTopic(hp);
    end
end

function classInfo = extractFromResolvedSymbol(hp, resolvedSymbol)
    classInfo           = resolvedSymbol.classInfo;
    hp.fullTopic        = resolvedSymbol.nameLocation;
    hp.topic            = resolvedSymbol.resolvedTopic;
    hp.elementKeyword   = resolvedSymbol.elementKeyword;
    hp.isInaccessible   = resolvedSymbol.isInaccessible;
    hp.isBuiltin        = resolvedSymbol.isBuiltin;
    hp.isAlias          = resolvedSymbol.isAlias;
    hp.isUnderqualified = resolvedSymbol.isUnderqualified;

    if resolvedSymbol.foundVar
        hp.inputTopic = resolvedSymbol.topicInput; % may be case corrected var
        hp.helpOnInstance = true;
        hp.displayBanner = true;
    else
        hp.isTypo = resolvedSymbol.isTypo || (resolvedSymbol.isResolved && ~resolvedSymbol.isCaseSensitive) || resolvedSymbol.isAlias;
    end

    if ~isempty(classInfo)
        hp.extractFromClassInfo(classInfo);
    end
end

function callHelpFunction(hp, helpFunction, justH1)
    hp.helpStr = matlab.lang.internal.introspective.callHelpFunction(helpFunction, hp.fullTopic, justH1);
    hp.needsHotlinking = true;
    [~, hp.topic, fileExt] = fileparts(hp.fullTopic);
    split = regexp(fileExt, filemarker, 'split', 'once');
    if ~isscalar(split)
        hp.topic = append(hp.topic, filemarker, split{2});
    end
end

function getAlternateSourcedHelp(hp, classInfo, justH1)
    if hp.helpStr == ""
        hp.getHelpTextFromDoc(classInfo, justH1, true);
    end

    if hp.helpStr == "" && ~isempty(classInfo)
        hp.helpStr = classInfo.getDescription(justH1);
        if hp.helpStr ~= ""
            hp.topic = classInfo.fullTopic;
        end
    end

    if isempty(hp.helpStr)
        hp.getPackageHelp();
    end

    getOrAppendFolderHelp(hp, justH1);

    if hp.helpStr == ""
        if isempty(classInfo)
            hp.getBuiltinNamespaceHelp();
        elseif ~hp.isUnderqualified && classInfo.isMethod
            hp.getShadowedOrdinaryFunctionHelp(classInfo.element);
        end
    end

    if ~hp.noDefault
        if hp.helpStr == "" && ~hp.isInaccessible
            hp.getDefaultHelpFromSource();
        end

        if hp.helpStr == "" && ~hp.helpOnInstance
            hp.getHelpFromLookfor();
        end
    end
end

function getOrAppendFolderHelp(hp, justH1)
    if ((hp.fullTopic == "" || hp.isDir) && hp.helpStr == "") || matches(hp.inputTopic, regexpPattern('\w*'))
        hp.getFolderHelp(justH1);
    end
end

function postprocessTopic(hp)
    if hp.objectSystemName ~= ""
        hp.topic = hp.objectSystemName;
    elseif ~hp.isDir && hp.fullTopic ~= ""
        [~, hp.topic] = hp.getPathItem;
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
