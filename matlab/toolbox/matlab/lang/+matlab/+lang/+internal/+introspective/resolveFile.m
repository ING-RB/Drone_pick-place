function [argExists, foundName, selectionKey, errorKey] = resolveFile(argName, introspectiveContext)
    selectionKey = '';
    errorKey = '';
    [argExists, foundName] = resolveInPrivateOfCallingFile(argName, introspectiveContext);

    if ~argExists
        [argExists, foundName] = resolveWithFileSystem(argName);
    end

    if ~argExists
        [argExists, foundName, selectionKey, errorKey] = resolvePath(argName, introspectiveContext);
    end
end

function [foundFile, foundName] = resolveInPrivateOfCallingFile(argName, introspectiveContext)
    foundFile = false;
    foundName = '';
    if ~isempty(introspectiveContext) && introspectiveContext.FullFileName ~= ""
        dirName = fileparts(introspectiveContext.FullFileName);
        privateName = fullfile(dirName, 'private', argName);
        [foundFile, foundName] = resolveWithFileSystem(privateName);
        if ~foundFile
            [foundFile, foundName] = resolveWithFileSystemAndExts(privateName);
        end
    end
end

function [foundFile, foundName] = resolveWithFileSystem(argName)
    foundFile = false;
    foundName = argName;

    dirResult = dir(argName);

    if isempty(dirResult) && isSimpleFile(argName)
        dirResult = dir(fullfile('private', argName));
    end

    if isscalar(dirResult) && ~dirResult.isdir
        foundFile = true;
        fullDirResult = dir(dirResult.folder);
        if ~any(matches({fullDirResult.name}, dirResult.name))
            fullDirResult = fullDirResult(matches({fullDirResult.name}, dirResult.name, IgnoreCase=true));
            dirResult = fullDirResult(1);
        end
        foundName = fullfile(dirResult.folder, dirResult.name);
    end
end

function [result, absfoundName] = resolveWithFileSystemAndExts(argName)
    result = false;

    if ~hasExtension(argName)
        argMlx = append(argName, '.mlx');
        [result, absfoundName] = resolveWithFileSystem(argMlx);

        if ~result
            argM = append(argName, '.m');
            [result, absfoundName] = resolveWithFileSystem(argM);
        end
    end

    if ~result
        absfoundName = argName;
    end
end

function [result, absfoundName, selectionKey, errorKey] = resolvePath(argName, introspectiveContext)
    [~, relativePath] = matlab.lang.internal.introspective.separateImplicitDirs(pwd);

    selectionKey = '';
    errorKey = '';
    [argName, hasLocalFunction, result, ~, absfoundName] = matlab.lang.internal.introspective.fixLocalFunctionCase(argName, relativePath);
    argName = char(argName);

    if hasLocalFunction
        if result && absfoundName(end) == 'p'
            % see if a corresponding M file exists
            absfoundName(end) = 'm';
            if ~exist(absfoundName, 'file')
                % Do not error, instead behave as if no file was found
                result = false;
            end
        end
        if result
            selectionKey = regexp(argName, append('(?<=', filemarker, ')\w*$'), 'match', 'once');
        else
            absfoundName = argName;
        end
    else
        [resolvedSymbol, ~, foundParentFolder] = matlab.lang.internal.introspective.resolveName(argName, QualifyingPath=relativePath, JustChecking=false, IntrospectiveContext=introspectiveContext, FindBuiltins=false);

        classInfo  = resolvedSymbol.classInfo;
        whichTopic = char(resolvedSymbol.nameLocation);

        if resolvedSymbol.foundVar && isempty(classInfo)
            absfoundName = argName;
            return;
        end

        if isBuiltin(resolvedSymbol)
            absfoundName = argName;
            result = false;
            if ~resolvedSymbol.isResolved || resolvedSymbol.isCaseSensitive
                errorKey = 'Builtin';
            end
            return;
        end

        if whichTopic == ""
            [result, absfoundName] = resolveWithFileSystemAndExts(argName);
            if ~result && foundParentFolder ~= ""
                lastWord = regexp(argName, '\w+$', 'match', 'once');
                if ~matches(lastWord, getKnownEditorExtensions, "IgnoreCase", true)
                    absfoundName = char(fullfile(foundParentFolder, lastWord));
                end
            end
        else
            % whichTopic is the full path to the resolved output either by class
            % inference or by which
            result = true;

            switch exist(whichTopic, 'file')
            case 0 % Name resolver found something which is not a file
                assert(~isempty(classInfo));
                whichTopic = char(classInfo.definition);
            case 3 % MEX File
                % Do not error, instead behave as if no file was found
                absfoundName = argName;
                result = false;
                return;
            case {4,6} % P File or Simulink Model
                if ~extensionMatches(whichTopic, argName)
                    % see if a corresponding M file exists
                    mTopic = regexprep(whichTopic, '\.\w+$', '.m');
                    if exist(mTopic, 'file')
                        whichTopic = mTopic;
                    elseif ~isempty(regexp(whichTopic, '\.mdl$', 'once'))
                        absfoundName = argName;
                        errorKey = 'MdlErr';
                        result = false;
                        return;
                    elseif resolvedSymbol.isUnderqualified
                        % Do not error, instead behave as if no file was found
                        absfoundName = argName;
                        result = false;
                        return;
                    end
                end
            case 7 % Directory
                if classInfo.isPackage
                    absfoundName = char(classInfo.fullTopic);
                    errorKey = 'PkgErr';
                else
                    % Class Folder: switch prompt to create the classdef
                    absfoundName = fullfile(whichTopic, char(classInfo.className));
                end
                result = false;
                return;
            end

            if matlab.io.internal.common.isAbsolutePath(whichTopic)
                absfoundName = whichTopic;
            else
                absfoundName = which(whichTopic);
            end

            if ~isempty(classInfo)
                isLocal = contains(classInfo.definition, filemarker);
                if isLocal && classInfo.isMethod && ~classInfo.isAbstract
                    selectionKey = char(classInfo.element);
                elseif isLocal && classInfo.isConstructor
                    selectionKey = char(classInfo.className);
                elseif resolvedSymbol.isUnderqualified && classInfo.isSimpleElement
                    % Do not open underqualified properties, instead behave as if no file was found
                    absfoundName = argName;
                    result = false;
                elseif classInfo.isSimpleElement || isLocal
                    selectionKey = [classInfo.getElementOffset, strlength(classInfo.element)];
                end
            end
        end
    end
end

function isBuiltinName = isBuiltin(resolvedSymbol)
    isBuiltinName = false;
    simpleName = getSimpleName(resolvedSymbol);
    if simpleName ~= ""
        isBuiltinName = matlab.lang.internal.introspective.isBuiltin(simpleName);
    end
end

function simpleName = getSimpleName(resolvedSymbol)
    simpleName = "";
    if ~resolvedSymbol.isResolved
        simpleName = resolvedSymbol.topicInput;
    elseif resolvedSymbol.isUnderqualified
        simpleName = resolvedSymbol.classInfo.element;
    end
end

function result = isSimpleFile(file)
    if isunix
        separators = "/";
    else % on windows be more restrictive
        separators = ["\", "/", ":"];
    end
    result = ~contains(file, separators);
end

function result = hasExtension(s)
    [~,~,ext] = fileparts(s);
    result = ext ~= "";
end

function result = extensionMatches(s1,s2)
    [~,~,ext] = fileparts(s1);
    result = endsWith(s2,ext,'IgnoreCase',true);
end

function exts = getKnownEditorExtensions
    languageSpecifications = matlab.internal.regfwk.ResourceSpecification;
    languageSpecifications.ResourceName = "mw.desktop.editor.languageSupport";
    languageResources = matlab.internal.regfwk.getResourceList(languageSpecifications);
    exts = arrayfun(@getExtensionsFromLanguageResource, languageResources, 'UniformOutput', false);
    exts = vertcat(exts{:});
    exts = [exts; "m"; "mlx"];
end

function exts = getExtensionsFromLanguageResource(languageResource)
    resourceContents = languageResource.resourcesFileContents;
    if iscell(resourceContents)
        exts = cellfun(@getExtensionsFromResourceContents, resourceContents, 'UniformOutput', false);
        exts = vertcat(exts{:});
    else
        exts = getExtensionsFromResourceContents(resourceContents);
    end
end

function exts = getExtensionsFromResourceContents(resourceContents)
    exts = string(resourceContents.defaultSupportedFileTypes);
end

%   Copyright 2022-2024 The MathWorks, Inc.
