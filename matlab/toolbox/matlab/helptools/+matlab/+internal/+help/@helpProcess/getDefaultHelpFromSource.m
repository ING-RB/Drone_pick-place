function getDefaultHelpFromSource(hp)
    hp.needsHotlinking = true;

    topicFile = regexprep(hp.fullTopic, "(\.m)?" + filemarker + "[^\\/]*$", '.m');
    existence = exist(topicFile, 'file');
    if existence || ~endsWith(hp.fullTopic, ".m") && isfile(regexprep(hp.fullTopic, '\.\w+$', '.m'))
        hp.helpStr = defaultHelpWithFile(hp, existence, topicFile);
    elseif hp.isBuiltin
        if ~hp.helpOnInstance
            hp.helpStr = defaultBuiltinHelp(hp);
        end
    elseif ~hp.helpOnInstance
        if matlab.internal.feature('mpm')
            package = mpmlist(Name=hp.topic);
        else
            package = [];
        end
        if ~isempty(package)
            hp.helpStr = defaultPackageHelp(hp.topic);
        else
            dirInfos = matlab.lang.internal.introspective.hashedDirInfo(hp.topic, false);
            if ~isempty(dirInfos)
                fullTopic = dirInfos(1).path;
                folderName = matlab.lang.internal.introspective.minimizePath(fullTopic, true);
                if folderName ~= "private"
                    hp.isTypo = isempty(matlab.lang.internal.introspective.hashedDirInfo(hp.topic, true));
                    hp.fullTopic = fullTopic;
                    hp.topic = folderName;
                    hp.isDir = true;
                    hp.helpStr = oneArgDefaultHelp('DefaultFolderHelp', ensureHighlighting(hp, folderName));
                end
            end
        end
    end
end

function helpStr = defaultHelpWithFile(hp, existence, topicFile)
    name = hp.objectSystemName;
    localName = false;
    if name == "" && contains(hp.topic, filemarker)
        name = extractAfter(hp.topic, filemarker);
        localName = name ~= "";
    end
    simpleElementTypes = matlab.lang.internal.introspective.getSimpleElementTypes;
    if ismember(hp.elementKeyword, {simpleElementTypes.keyword})
        usage = strings(0,1);
    else
        usage = matlab.lang.internal.introspective.getUsageFromSource(topicFile, name);
    end
    if name == ""
        [~, name] = fileparts(hp.topic);
    end
    if hp.wantHyperlinks
        % ensure highlighting by uppering the name
        usage = regexprep(usage, "(^|=)\s*" + name + "\s*(\(|$)", "${upper($0)}");
        name = upper(name);
    end
    if isempty(usage)
        helpStr = defaultHelpWithoutUsage(hp, existence, name);
    else
        helpStr = defaultHelpWithUsage(hp, name, usage, localName);
    end
end

function helpStr = defaultHelpWithoutUsage(hp, existence, name)
    if hp.objectSystemName == ""
        helpStr = defaultSimulinkOrFullPathHelp(existence, name, hp.fullTopic);
    else
        switch hp.elementKeyword
        case 'properties'
            helpStr = oneArgDefaultHelp('DefaultPropertyHelp', name);
        case 'events'
            helpStr = oneArgDefaultHelp('DefaultEventHelp', name);
        case 'enumeration'
            helpStr = oneArgDefaultHelp('DefaultEnumerationHelp', name);
        case 'methods'
            helpStr = defaultNoArgFunctionHelp(name);
        case 'constructor'
            helpStr = defaultClassHelp(name);
        case 'packagedItem'
            helpStr = defaultSimulinkOrFullPathHelp(existence, name, hp.fullTopic);
        otherwise
            helpStr = defaultNamespaceHelp(name);
        end
    end
end

function helpStr = defaultHelpWithUsage(hp, name, usage, localName)
    if hp.isMCOSClass
        helpStr = twoArgDefaultHelp('DefaultConstructorHelp', name, usage);
    elseif hp.isMCOSClassOrConstructor
        helpStr = twoArgDefaultHelp('DefaultFullConstructorHelp', name, usage);
    elseif strcmpi(usage, name)
        if localName
            helpStr = oneArgDefaultHelp('DefaultNoArgLocalFunctionHelp', name);
        else
            helpStr = defaultFullPathHelp(name, hp.fullTopic);
        end
    else
        if localName
            helpStr = twoArgDefaultHelp('DefaultLocalFunctionHelp', name, usage);
        else
            helpStr = twoArgDefaultHelp('DefaultFunctionHelp', name, usage);
        end
    end
end

function helpStr = defaultSimulinkOrFullPathHelp(existence, name, fullPath)
    if existence == 4
        try
            info = Simulink.MDLInfo(fullPath);
            type = info.BlockDiagramType;
            helpStr = twoArgDefaultHelp('DefaultSLXHelp', name, type);
        catch
            helpStr = oneArgDefaultHelp('DefaultNoSLXHelp', name);
        end
    else
        helpStr = defaultFullPathHelp(name, fullPath);
    end
end

function helpStr = defaultFullPathHelp(name, fullPath)
    switch matlab.internal.help.sourceFileType(fullPath)
    case "Script"
        helpStr = defaultScriptHelp(name);
    case "Function"
        helpStr = defaultNoArgFunctionHelp(name);
    case "Class"
        helpStr = defaultClassHelp(name);
    case "Unknown"
        [~, fileName, ext] = fileparts(fullPath);
        if ext == ".p"
            helpStr = oneArgDefaultHelp('DefaultPHelp', name);
        else
            helpStr = oneArgDefaultHelp('DefaultInvalidFileHelp', append(fileName, ext));
        end
    end
end

function helpStr = defaultBuiltinHelp(hp)
    name = hp.topic;
    name = ensureHighlighting(hp, name);
    hp.fullTopic = hp.topic;
    if hp.isDir
        helpStr = defaultNamespaceHelp(name);
    else
        [~, whichComment] = which(hp.topic);
        if whichComment == ""
            whichComment = 'function';
        else
            if startsWith(whichComment, hp.topic)
                whichComment = extractAfter(whichComment, ' ');
            end
            qualifiedTopic = matlab.lang.internal.introspective.getUnderqualifiedName(hp.topic, whichComment);
            if qualifiedTopic ~= ""
                hp.isUnderqualified = true;
                hp.objectSystemName = qualifiedTopic;
            else
                hp.objectSystemName = hp.topic;
            end
            hp.isMCOSClass = ~isempty(meta.class.fromName(hp.objectSystemName));
        end
        helpStr = twoArgDefaultHelp('DefaultBuiltinHelp', name, whichComment);
    end
end

function name = ensureHighlighting(hp, name)
    if hp.wantHyperlinks
        % ensure highlighting by uppering the name
        name = upper(name);
    end
end

function helpStr = oneArgDefaultHelp(key, name)
    helpStr = getString(message("MATLAB:help:" + key, name));
end

function helpStr = twoArgDefaultHelp(key, name, usage)
    helpStr = getString(message("MATLAB:help:" + key, name, usage));
end

function helpStr = defaultClassHelp(name)
    helpStr = oneArgDefaultHelp('DefaultClassHelp', name);
end

function helpStr = defaultNoArgFunctionHelp(name)
    helpStr = oneArgDefaultHelp('DefaultNoArgFunctionHelp', name);
end

function helpStr = defaultNamespaceHelp(name)
    helpStr = oneArgDefaultHelp('DefaultNamespaceHelp', name);
end

function helpStr = defaultPackageHelp(name)
    helpStr = oneArgDefaultHelp('DefaultPackageHelp', name);
end

function helpStr = defaultScriptHelp(name)
    helpStr = oneArgDefaultHelp('DefaultScriptHelp', name);
end

%   Copyright 2017-2024 The MathWorks, Inc.
