classdef helpProcess < handle
    properties (Access=public)
        topic           = '';
        inputTopic      = '';
        justChecking    = false;
        callerContext (1,1) matlab.lang.internal.introspective.IntrospectiveContext;
    end

    properties (SetAccess=private, GetAccess=public)
        displayBanner = false;

        helpStr = '';
        docLinks (1,1) matlab.lang.internal.introspective.docLinks;
        helpOnInstance = false;

        command          = '';
        fullTopic        = '';
        objectSystemName = '';
        elementKeyword   = '';

        isBuiltin                = false;
        isDir                    = false;
        isContents               = false;
        isMCOSClassOrConstructor = false;
        isMCOSClass              = false;
        isInaccessible           = false;
        isTypo                   = false;
        isAlias                  = false;
        isUnderqualified         = false;

        suppressedFolderName = '';

        suppressDisplay    = false;
        suppressedImplicit = false;
        commandIsHelp      = true;
        fixTypos           = true;
        needsHotlinking    = false;
        noDefault          = false;
    end

    properties (Dependent = true, Access = private)
        wantHyperlinks;
    end

    methods
        function value = get.wantHyperlinks(hp)
            value = hp.command ~= "";
        end
    end

    methods
        function hp = helpProcess(nlhs, nrhs, prhs)
            hp.suppressDisplay = (nlhs ~= 0);
            if ~hp.suppressDisplay
                if matlab.internal.display.isHot
                    hp.command = 'help';
                end
            end

            commandSpecified = false;

            try
                for i = 1:nrhs
                    arg = prhs{i};
                    if isstring(arg)
                        if ~isscalar(arg)
                            error(message('MATLAB:help:MustBeSingleString'));
                        end
                        commandSpecified = processTextInput(hp, char(arg), commandSpecified);
                    elseif ischar(arg)
                        if ~isvector(arg) && ~isempty(arg)
                            error(message('MATLAB:help:MustBeCharVector'));
                        end
                        commandSpecified = processTextInput(hp, arg, commandSpecified);
                    elseif isempty(hp.topic)
                        hp.specifyTopic(class(arg));
                        % note the input index so the caller can get the inputname
                        hp.inputTopic = i;
                        hp.displayBanner = true;
                        hp.helpOnInstance = true;
                    else
                        error(message('MATLAB:help:TooManyInputs'));
                    end
                end
            catch Ex
                hp.suppressDisplay = true;
                throwAsCaller(Ex);
            end
        end

        function delete(hp)
            if ~hp.suppressDisplay
                disp(hp.displayHelp);
            end
        end

        function specifyCommand(hp, command)
            hp.command = command;
            hp.commandIsHelp = strcmp(hp.command, 'help');
        end
    end

    methods
        function link = createMATLABLink(hp, linkTarget, linkText)
            link = matlab.internal.help.createMatlabLink(hp.command, linkTarget, linkText);
        end
    end


    methods (Access=private)
        function commandSpecified = processTextInput(hp, arg, commandSpecified)
            switch arg
            case '-noDefault'
                hp.noDefault = true;
            case '-displayBanner'
                hp.displayBanner = true;
            case {'-help', '-helpwin', '-doc', '-updateHelpPopup'}
                if commandSpecified
                    error(message('MATLAB:help:TooManyCommands'));
                end
                hp.specifyCommand(extractAfter(arg, 1));
                hp.fixTypos = hp.commandIsHelp;
                commandSpecified = true;
            otherwise
                if isnumeric(hp.inputTopic)
                    % inputTopic is numeric because it's a variable
                    error(message('MATLAB:help:TooManyInputs'));
                end
                hp.specifyTopic(arg);
                hp.inputTopic = hp.topic;
            end
        end

        function specifyTopic(hp, topic)
            if hp.topic == ""
                hp.topic = topic;
            else
                hp.topic = append(hp.topic, ' ', topic);
            end
        end

        function topic = getTopic(hp)
            if hp.objectSystemName == ""
                topic = hp.topic;
            else
                topic = hp.objectSystemName;
            end
        end

        link = getReferenceLink(hp);
        link = getOverloadsLink(hp);
        link = getFoldersLink(hp);
        link = getOtherNamesLink(hp, topic, linkTopic, linkID, linkFcn);

        function name = makeStrong(hp, name)
            name = matlab.internal.help.makeStrong(name, hp.wantHyperlinks, hp.commandIsHelp);
        end

        getDocLinks(hp);
        getBuiltinNamespaceHelp(hp);
        getShadowedOrdinaryFunctionHelp(hp, methodName);
        getPackageHelp(hp);
        getDefaultHelpFromSource(hp);
        getHelpFromLookfor(hp);

        extractFromClassInfo(hp, classInfo);
        found = getHelpTextFromDoc(hp, classInfo, justH1, ignoreCase);
        found = getHelpFromClassInfo(hp, classInfo, justH1);

        demoTopic = getDemoTopic(hp);
        [qualifyingPath, pathItem] = getPathItem(hp);

        getFolderHelp(hp, justH1);
        hotlinkHelp(hp);
    end

    methods
        appendBanner(hp);
        getHelpText(hp);
        prepareHelpForDisplay(hp);

        getNoInputHelp(hp, history);
        getTopicHelpText(hp, justH1, resolveOverqualified);
        getHelpOnExpression(hp, expression);
        displayStr = displayHelp(hp);
        dirHelpStr = getContentsMHelp(hp, folderInfo, justH1)

        found = getHelpForTopics(hp, topics, forceContents);
        list = hotlinkList(hp, list, pathName, fcnName, inContents, inClass);
        contents = linkContents(hp, contents, args);
        linkSeeAlsos(hp, helpSections, pathName, fcnName, inClass);
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
