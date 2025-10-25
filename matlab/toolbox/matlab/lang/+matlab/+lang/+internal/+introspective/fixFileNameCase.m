function [fileName, qualifyingPath, fullPath, helpFunction] = fixFileNameCase(fname, helpPath, whichTopic, callingFunction)
    fileName = fname;
    qualifyingPath = '';
    helpFunction = '';
    if nargin > 2 && whichTopic ~= ""
        fullPath = whichTopic;
        fname = regexprep(fname, '\.p$', '');
    else
        if nargin < 4
            callingFunction = '';
        end
        fullPath = matlab.lang.internal.introspective.safeWhich(fname, false, callingFunction);
        if fullPath == ""
            [parent, name, ext] = fileparts(fname);
            if parent == ""
                if ext == ""
                    ext = '.m';
                end
                fullPath = matlab.lang.internal.introspective.safeWhich(fullfile(pwd, 'private', append(name, ext)), false, callingFunction);
            end
        end
    end
    if fullPath == ""
        return;
    end
    if helpPath ~= ""
        helpPath = append(filesep, helpPath, filesep);
        if ~contains(fullPath, helpPath)
            [~, name] = fileparts(fname);
            allPaths = which('-all',fname);
            for entry=1:numel(allPaths)
                pathEntry = allPaths{entry};
                [~, entryName] = fileparts(pathEntry);
                if strcmpi(name, entryName)
                    startPos = strfind(pathEntry, helpPath);
                    if ~isempty(startPos)
                        qualifyingPath = fileparts(matlab.lang.internal.introspective.minimizePath(pathEntry(startPos(1)+1:end), false));
                        fullPath = pathEntry;
                        break;
                    end
                end
            end
        end
    end
    fileName = matlab.lang.internal.introspective.extractCaseCorrectedName(fullPath, fname);
    helpFunction = matlab.lang.internal.introspective.getHelpFunction(fullPath);
end

%   Copyright 2007-2024 The MathWorks, Inc.
