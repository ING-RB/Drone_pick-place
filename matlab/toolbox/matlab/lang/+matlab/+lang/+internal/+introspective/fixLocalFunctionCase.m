function [fname, hasLocalFunction, shouldLink, qualifyingPath, fullPath, helpFunction] = fixLocalFunctionCase(fname, helpPath)
    justChecking = nargin > 1;
    if ~justChecking
        helpPath = '';
    end

    hasLocalFunction = false;
    shouldLink       = false;

    qualifyingPath   = '';
    fullPath         = '';
    helpFunction     = '';

    split = regexp(fname, filemarker, 'split', 'once');

    if numel(split) > 1
        hasLocalFunction = true;
        [fileName, qualifyingPath, fullPath, helpFunction] = matlab.lang.internal.introspective.fixFileNameCase(split{1}, helpPath);

        if helpFunction == ""
            resolvedName = matlab.lang.internal.introspective.resolveName(fileName, QualifyingPath=helpPath, JustChecking=false);

            if ~resolvedName.isResolved
                return;
            end

            fullPath = resolvedName.whichTopic;
            helpFunction = matlab.lang.internal.introspective.getHelpFunction(fullPath);
        end

        [localName, shouldLink] = matlab.lang.internal.introspective.getCaseCorrectLocalName(fullPath, split{2});

        if shouldLink
            if justChecking
                fname = append(fileName, filemarker, localName);
            else
                if helpFunction == ""
                    [filePath, fileName] = fileparts(fullPath);
                    filePath = append(filePath, filesep, fileName);
                else
                    filePath = fullPath;
                end
                fname = append(filePath, filemarker, localName);
            end
        end

        if ~shouldLink && matlab.lang.internal.introspective.isClassMFile(fullPath)
            fname = append(fileName, filesep, split{2});
            hasLocalFunction = false;
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
