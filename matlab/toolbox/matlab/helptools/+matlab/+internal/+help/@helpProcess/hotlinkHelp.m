function hotlinkHelp(hp)
    %HOTLINKHELP Reformat help output so that the content has hyperlinks

    packageName = '';
    inClass = false;
    inConstructor = false;

    [pathName, fcnName] = fileparts(hp.topic);
    if hp.isContents
        pathName = hp.topic;
        hp.topic = 'Contents';
    elseif contains(fcnName, filemarker)
        methodSplit = regexp(fcnName, filemarker, 'split', 'once');
        if ~matlab.lang.internal.introspective.containers.isClassDirectory(pathName)
            pathName = fullfile(pathName, append('@', methodSplit{1}));
        end
        fcnName = methodSplit{2};
        inConstructor = hp.isMCOSClassOrConstructor;
    elseif strcmp(getFinalObjectEntity(pathName), fcnName)
        % @ dir Class
        inClass = true;
        packageName = matlab.lang.internal.introspective.getPackageName(fileparts(pathName));
    elseif fcnName ~= ""
        if pathName == "" && contains(hp.objectSystemName, '.')
            packageName = fcnName;
            fcnName = regexp(hp.topic, '\w*$', 'match', 'once');
        else
            packageName = matlab.lang.internal.introspective.getPackageName(pathName);
        end
        if hp.isMCOSClassOrConstructor
            inClass = true;
            if pathName == ""
                pathName = fcnName;
            else
                pathName = append(pathName, '/@', fcnName);
            end
        end
    end

    % hotlink all URLs in the help
    hp.helpStr = linkURLs(hp.helpStr);

    if hp.isContents || strcmp(fcnName,'debug')
        % hotlink these files like directories
        hp.helpStr = hp.linkContents(hp.helpStr, QualifyingPath=pathName);
    else
        inClassOrConstructor = inClass || inConstructor;
        helpSections = matlab.internal.help.HelpSections(hp.helpStr, fcnName, packageName, inClassOrConstructor);
        hp.linkSeeAlsos(helpSections, pathName, fcnName, inClass);
        if inClassOrConstructor
            linkClassMembers(hp, helpSections, fcnName, pathName);
        end
        hp.helpStr = helpSections.getFullHelpText;
    end

    if hp.commandIsHelp
        fullName = hp.docLinks.productName;
        if fullName == ""
            fullName = hp.objectSystemName;
        end
        hp.helpStr = matlab.internal.help.highlightHelp(hp.helpStr, fullName, fcnName, '<strong>', '</strong>');
    end
end

function helpStr = linkURLs(helpStr)
    replaceLink = @(url)makeURLLink(url); %#ok<NASGU>
    helpStr = regexprep(helpStr, '(<a\s*href.*?</a>)?(\w{2,}://\S*(?<=[\w\\/]))?', '$1${replaceLink($2)}', 'ignorecase');
end

function linkText = makeURLLink(url)
    if url == ""
        linkText = '';
    else
        linkText = matlab.internal.help.createMatlabLink('web', url, url);
    end
end

function linkClassMembers(hp, helpSections, className, pathName)
    % linkClassMembers links the list of class members in helpStr if a list exists

    for classMemberSection = helpSections.ClassMembers
        % Parse the "Class Member" portion of help output to link like a Contents.m file.
        classMemberSection.helpStr = hp.linkContents(classMemberSection.helpStr, QualifyingPath=pathName, QualifyingName=className, InClass=true);
    end
end

function entity = getFinalObjectEntity(objectPath)
    entity = regexp(objectPath, '(?<=[@+])[^@+]*$', 'match', 'once');
end

%   Copyright 1984-2024 The MathWorks, Inc.
