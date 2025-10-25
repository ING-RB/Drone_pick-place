function resolvedList = resolvePaths(items, validExtension, invalidFileError, fileNotFoundError)
%resolvePath    resolve the input paths to absolute paths
%   resolvedList = resolvePaths(items, validExtension) takes the files and
%   directories in the list, resolve it to absolute file path with the 
%   valid extension provided.
%   For directory, it will not expand it.
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2021-2024 The MathWorks, Inc.

    arguments
        items string
        validExtension string
        invalidFileError = 'codeanalysis:reports:ccrAnalysis:InvalidFile'
        fileNotFoundError = 'codeanalysis:reports:ccrAnalysis:FileNotFound'
    end

    resolvedList = [];
    for i = 1:numel(items)
        if isfolder(items{i})
            dirName = dir(items{i});
            if isempty(dirName)
                error(message(fileNotFoundError, items{i}));
            end
            folderName = dirName.folder;
            resolvedList = [resolvedList, {folderName}]; %#ok<AGROW>
        else
            % Disallow wildcard in file names
            invalid = '*?';
            nameWithoutWildCard = strtok(items{i},invalid);
            if ~strcmp(nameWithoutWildCard, items{i})
                error(message('codeanalysis:reports:ccrAnalysis:WildCard'));
            end
            % find the file in the file system
            dirItems = findFile(items{i}, validExtension, invalidFileError, fileNotFoundError);
            fileList = fullfile({dirItems.folder}, {dirItems.name});
            % If extension is specified by the user, there should be one
            % file in the list.
            % If extension is not specified by the user, there could be
            % multiple files in the list, but all have valid extension.
            % Returns a row vector.
            resolvedList = [resolvedList, fileList(1,:)]; %#ok<AGROW>
        end
    end
end

function dirItems = findFile(filename, validExtension, invalidFileError, fileNotFoundError)
% If finds file, verify that is contains a valid extension.
% If cannot find the file, and it does not have an extension,
% then attempt to find it with a supported extension.
% If the file still cannot be found, throw an error.

    [~, ~, extension] = fileparts(filename);
    if ~isempty(extension)
        if ~ismember(extension, validExtension)
            extensions = strjoin("*" + validExtension, ', ');
            error(message(invalidFileError, filename, extensions));
        end
        dirItems = dir(filename);
    else
        dirItems = [];
        for ext = 1:numel(validExtension)
            fullname = strcat(filename, validExtension(ext));
            % We do not want to find folder with extension
            if ~isfolder(fullname)
                dirOut = dir(fullname);
                dirItems = [dirItems; dirOut]; %#ok<AGROW>
            end
        end
    end
    if isempty(dirItems)
        error(message(fileNotFoundError, filename));
    end
end
