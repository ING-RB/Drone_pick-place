function list = hotlinkList(hp, list, pathName, fcnName, inContents, inClass)
    list = strrep(list, '&amp;', '&');
    replaceLink = @(name)makeHyperlink(hp, name, pathName, fcnName, inContents, inClass); %#ok<NASGU>
    list = regexprep(list, '(<a\s*href.*?</a>)?([^\s,]+(?<!\.))?', '$1${replaceLink($2)}', 'ignorecase');
end

%% ------------------------------------------------------------------------
function linkText = makeHyperlink(hp, word, pathName, fcnName, inContents, inClass)
    linkText = word;
    if word == ""
        return;
    end
    % Make sure the function exists before hyperlinking it.
    if strcmpi(word, fcnName) && (~inContents || inClass)
        if hp.isMCOSClassOrConstructor
            helpFunction = matlab.lang.internal.introspective.getHelpFunction(hp.fullTopic);
            if hasHelp(hp.fullTopic, helpFunction)
                constructorTopic = append(hp.fullTopic, filemarker, fcnName);
                if hasHelp(constructorTopic, helpFunction)
                    % class or constructor self link, in which both exist
                    if inClass
                        % link to the constructor
                        linkTarget = append(hp.objectSystemName, '/', fcnName);
                    else
                        % link to the class
                        linkTarget = regexp(hp.objectSystemName, '[^/]*', 'match', 'once');
                    end
                    linkText = hp.createMATLABLink(linkTarget, fcnName);
                    return;
                end
            end
        end
        pathName = '';
    end
    if inContents || word ~= "and"
        [shouldLink, fname, qualifyingPath, whichTopic] = isHyperlinkable(word, pathName, hp.callerContext);
        if shouldLink
            if shouldLink
                linkWord = matlab.lang.internal.introspective.extractCaseCorrectedName(fname, word);
            else
                linkWord = fname;
            end
            if linkWord == ""
                % word is overqualified or an alias
                [overqualifiedPath, linkWord] = matlab.lang.internal.introspective.splitOverqualification(fname, word, whichTopic);
                if linkWord ~= ""
                    % overqualfied
                    linkWord = append(overqualifiedPath, linkWord);
                else
                    % alias
                    linkWord = fname;
                end
            elseif qualifyingPath ~= ""
                % word is underqualified
                qualifyingPath(qualifyingPath=='\') = '/';
                fname = append(qualifyingPath, '/', fname);
            end
            linkText = hp.createMATLABLink(fname, linkWord);
        end
    end
end

%% ------------------------------------------------------------------------
function b = hasHelp(fullTopic, helpFunction)
    b = matlab.lang.internal.introspective.callHelpFunction(helpFunction, fullTopic, true) ~= "";
end

%% ------------------------------------------------------------------------
function [shouldLink, fname, qualifyingPath, whichTopic] = isHyperlinkable(fname, helpPath, callerContext)
    whichTopic = '';

    % Make sure the function exists before hyperlinking it.
    [fname, hasLocalFunction, shouldLink, qualifyingPath] = matlab.lang.internal.introspective.fixLocalFunctionCase(fname, helpPath);
    if hasLocalFunction
        return;
    end

    [fname, shouldLink, qualifyingPath, whichTopic] = isHyperlinkableMethod(fname, helpPath, callerContext);
    if ~shouldLink
        % Check for directories on the path
        dirInfo = matlab.lang.internal.introspective.hashedDirInfo(fname);
        if ~isempty(dirInfo)
            fname = matlab.lang.internal.introspective.extractCaseCorrectedName(dirInfo(1).path, fname);
            if exist(fname, 'file') == 7
                shouldLink = true;
                return;
            end
        end

        % Check for files on the path
        [fname, qualifyingPath, ~, helpFunction] = matlab.lang.internal.introspective.fixFileNameCase(fname, helpPath, whichTopic);
        shouldLink = helpFunction ~= "";
    end
end

%% ------------------------------------------------------------------------
function [fname, shouldLink, qualifyingPath, whichTopic] = isHyperlinkableMethod(fname, helpPath, callerContext)
    shouldLink = false;
    qualifyingPath = '';

    nameResolver = matlab.lang.internal.introspective.NameResolver(fname, QualifyingPath=helpPath, IntrospectiveContext=callerContext);
    nameResolver.lowerBeforeRef = all(isstrprop(fname, 'upper'));
    nameResolver.findVariables = false;
    nameResolver.executeResolve();
    resolvedSymbol = nameResolver.resolvedSymbol;

    classInfo  = resolvedSymbol.classInfo;
    whichTopic = resolvedSymbol.nameLocation;

    if ~isempty(classInfo)
        shouldLink = true;
        % qualifyingPath includes the object dirs, so remove them
        qualifyingPath = regexp(char(fileparts(classInfo.minimalPath)), '^[^@+]*(?=[\\/])', 'match', 'once'); % use char to avoid missing
        newName = classInfo.fullTopic;

        if classInfo.isConstructor && isempty(regexpi(fname, '\<(\w+)[\\/.]\1(\.[mp])?$', 'once'))
            fname = regexprep(newName, '\<(\w+)/\1$', '$1');
        else
            fname = newName;
        end
    elseif resolvedSymbol.isBuiltin
        shouldLink = true;
        fname = resolvedSymbol.resolvedTopic;
    end
end

% Copyright 2021-2024 The MathWorks, Inc.
